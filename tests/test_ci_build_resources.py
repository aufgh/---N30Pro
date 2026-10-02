"""Exercise CPU-based parallelism, retry, exit status and diagnostics."""
from pathlib import Path
import json
import os
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / ".github/scripts/build-firmware.sh"


class BuildResourceTests(unittest.TestCase):
    def run_build(self, codes, cpus=4):
        with tempfile.TemporaryDirectory(prefix="ci-resource-test-") as directory:
            root = Path(directory)
            binary = root / "bin"
            binary.mkdir()
            fake = binary / "make"
            fake.write_text("""#!/usr/bin/python3
import json, os, sys
from pathlib import Path
p = Path(os.environ['CALLS'])
calls = json.loads(p.read_text()) if p.exists() else []
codes = json.loads(os.environ['CODES'])
index = len(calls)
calls.append(sys.argv[1:])
p.write_text(json.dumps(calls))
print('fake build output', flush=True)
sys.exit(codes[min(index, len(codes)-1)])
""")
            fake.chmod(0o755)
            fake_cpu = binary / "nproc"
            fake_cpu.write_text(f"#!/bin/sh\necho {cpus}\n")
            fake_cpu.chmod(0o755)
            env = dict(os.environ, PATH=f"{binary}:{os.environ['PATH']}",
                       CALLS=str(root / "calls.json"), CODES=json.dumps(codes),
                       RESOURCE_MONITOR_INTERVAL="1")
            result = subprocess.run(["bash", str(SCRIPT)], cwd=root, env=env,
                                    capture_output=True, text=True, timeout=10)
            calls = json.loads((root / "calls.json").read_text())
            log = (root / "ci-logs/build.log").read_text()
            resources = (root / "ci-logs/resources.log").read_text()
            self.assertIn("fake build output", log)
            self.assertIn("[ci-resource]", resources)
            return result.returncode, calls

    def test_parallelism_matches_available_cpus(self):
        self.assertEqual(self.run_build([0], 16), (0, [["-j16"]]))
        self.assertEqual(self.run_build([0], 1), (0, [["-j1"]]))

    def test_one_verbose_retry(self):
        self.assertEqual(self.run_build([2, 0]),
                         (0, [["-j4"], ["-j1", "V=s"]]))

    def test_final_failure_preserved(self):
        self.assertEqual(self.run_build([2, 7]),
                         (7, [["-j4"], ["-j1", "V=s"]]))

    def test_signal_exit_does_not_retry(self):
        self.assertEqual(self.run_build([143]), (143, [["-j4"]]))


if __name__ == "__main__":
    unittest.main()
