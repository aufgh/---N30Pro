"""Exercise the actual shell helper with isolated UCI/ip/nft commands.

Hardware regression: concurrent LAN requests during fw4 reload, recorded in
docs/ua3f-live-verification.md. These checks protect its lifecycle guarantees.
"""
from pathlib import Path
import json
import os
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]
helper = repo.joinpath('files/usr/libexec/n30pro-ua3f-tproxy').read_text()
defaults = {
    'ua3f.enabled.enabled': '1', 'ua3f.main.transparent_proxy': '1',
    'ua3f.main.server_mode': 'SOCKS5', 'ua3f.main.bind': '127.0.0.1',
    'ua3f.main.lan_device': 'br-lan', 'ua3f.main.port': '1080',
    'ua3f.main.proxy_https': '1', 'openclash.config.enable': '0',
    'passwall.@global[0].enabled': '0',
    'firewall.@defaults[0].flow_offloading': '0',
    'firewall.@defaults[0].flow_offloading_hw': '0',
}
mock_code = '''#!/usr/bin/python3
import sys, os, json
from pathlib import Path
name = Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ['MOCK_LOG'], 'a') as f:
    f.write(json.dumps([name]+args)+'\\n')
if name == 'uci':
    value = json.loads(os.environ['MOCK_UCI']).get(args[-1])
    if value is None: sys.exit(1)
    print(value)
elif name == 'ip' and 'show' in args and 'route' in args:
    print('192.168.1.0/24 proto kernel src 192.168.1.1' if '-4' in args else 'fd7c:ebfe:7c9c::/64 proto static metric 1024\\nfe80::/64 proto kernel metric 256')
elif name == 'ip' and 'show' in args and 'rule' in args and os.environ.get('MOCK_ACTIVE') == '1':
    print('1000: from all fwmark 0x1000000/0xff000000 lookup 31001')
elif name == 'nft' and args[:2] == ['list','table']:
    sys.exit(0 if os.environ.get('MOCK_ACTIVE') == '1' else 1)
elif name == 'nft' and '-c' in args and os.environ.get('FAIL_NFT') == '1':
    sys.exit(1)
'''

with tempfile.TemporaryDirectory(prefix='ua3f-profile-') as directory:
    root = Path(directory)
    bin_dir = root/'bin'
    bin_dir.mkdir()
    for name in ('uci', 'ip', 'nft', 'logger', 'hev-socks5-tproxy'):
        p = bin_dir/name
        p.write_text(mock_code)
        p.chmod(0o755)
    script = root/'helper'
    script.write_text(helper.replace('RUN_DIR=/var/run/ua3f-tproxy', 'RUN_DIR='+str(root/'run')))
    script.chmod(0o755)
    log = root/'commands.jsonl'
    def run(changes=None, action='start', fail_nft=False, active=False):
        log.write_text('')
        config = dict(defaults, **(changes or {}))
        env = dict(os.environ, PATH=str(bin_dir)+':'+os.environ['PATH'], MOCK_UCI=json.dumps(config), MOCK_LOG=str(log), FAIL_NFT=str(int(fail_nft)), MOCK_ACTIVE=str(int(active)))
        result = subprocess.run(['/bin/sh', str(script), action], env=env, capture_output=True, text=True)
        commands = [json.loads(x) for x in log.read_text().splitlines()]
        return result, commands

    result, commands = run()
    assert result.returncode == 0, result.stderr
    rules = (root/'run/rules.nft').read_text()
    config = (root/'run/hev.yml').read_text()
    assert 'tproxy ip to 127.0.0.1:1088' in rules
    assert 'tproxy ip6 to [::1]:1088' in rules
    assert 'tcp dport 443 return' not in rules
    assert 'fib daddr type local return' in rules and 'iifname != "br-lan" return' in rules
    assert '192.168.1.0/24' in rules and 'fd7c:ebfe:7c9c::/64' in rules
    assert '10.0.0.0/8' not in rules and 'fc00::/7' not in rules
    assert '198.18.0.0/15' in rules
    assert 'udp dport 443' in rules and 'redirect to :123' in rules
    for family in ('-4', '-6'):
        assert any(c[:4] == ['ip',family,'rule','add'] for c in commands)
    assert "address: '::'" in config and 'port: 1080' in config and '\nudp:' not in config
    print('PASS dual-stack TCP, management/LAN exclusions, campus private destinations, Fake-IP bypass, QUIC/NTP, routing marks')

    result, commands = run(action='stop')
    assert result.returncode == 0
    assert any(c[:4] == ['nft','delete','table','inet'] for c in commands)
    assert not any(c[0]=='nft' and '-f' in c for c in commands)
    print('PASS stop removes owned nft table and both route policies')

    result, commands = run({'ua3f.main.proxy_https':'0', 'ua3f.main.port':'2080'})
    assert result.returncode == 0
    assert 'tcp dport 443 return' in (root/'run/rules.nft').read_text()
    assert 'port: 2080' in (root/'run/hev.yml').read_text()
    print('PASS HTTPS bypass switch and SOCKS5 port propagation')

    for option,value in [('ua3f.enabled.enabled','0'),('ua3f.main.transparent_proxy','0')]:
        result, commands = run({option:value})
        assert result.returncode == 0
        assert not any(c[0]=='nft' and '-f' in c for c in commands)
    print('PASS disabled profile never re-adds transparent rules')

    for option,value in [('ua3f.main.bind','0.0.0.0'),('ua3f.main.port','1088'),('ua3f.main.port','0'),('ua3f.main.port','65536'),('ua3f.main.lan_device','br-lan;bad'),('openclash.config.enable','1'),('passwall.@global[0].enabled','1'),('firewall.@defaults[0].flow_offloading','1'),('firewall.@defaults[0].flow_offloading_hw','1')]:
        result, commands = run({option:value})
        assert result.returncode != 0, option
        assert not any(c[0]=='nft' and '-f' in c for c in commands), option
    print('PASS invalid ports/binds/device, interception conflicts and flow-offload guards')

    result, commands = run(fail_nft=True)
    assert result.returncode != 0
    assert not any(c[0]=='nft' and c[1]=='-f' for c in commands)
    assert sum(c[:4]==['nft','delete','table','inet'] for c in commands) == 1
    print('PASS nft validation failure rolls back both route policies')

    result, commands = run(active=True)
    assert result.returncode == 0, result.stderr
    assert (root/'run/rules.nft').read_text().startswith('delete table inet n30pro_ua3f\n')
    assert not any(c[:4]==['nft','delete','table','inet'] for c in commands)
    assert not any(c[0]=='ip' and ('del' in c or 'flush' in c or 'add' in c) for c in commands)
    print('PASS active reload keeps routes and replaces nft table in one transaction')

    result, commands = run(active=True,fail_nft=True)
    assert result.returncode != 0
    assert not any(c[:4]==['nft','delete','table','inet'] for c in commands)
    assert not any(c[0]=='ip' and ('del' in c or 'flush' in c) for c in commands)
    print('PASS failed active reload preserves previous rules and routes')

for filename in ['diy-part1.sh','diy-part2.sh','files/usr/libexec/n30pro-ua3f-tproxy','files/etc/uci-defaults/99-ua3f-transparent']:
    subprocess.run(['/bin/bash','-n',str(repo/filename)],check=True)
print('PASS shell syntax')
