#!/bin/bash
# Description: OpenWrt DIY script part 2 (After Update feeds)

echo ">> Fixing USB and RNDIS based on CSDN article..."
cat > target/linux/mediatek/dts/mt7981b-netis-nx30v2.dts << 'EOF'
/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */

/dts-v1/;
#include "mt7981b-netis-common.dtsi"

/ {
        model = "netis NX30 V2";
        compatible = "netis,nx30v2", "mediatek,mt7981";

        aliases {
                label-mac-device = &gmac0;
                led-boot = &led_power;
                led-failsafe = &led_power;
                led-running = &led_power;
                led-upgrade = &led_wps;
        };

        leds {
                compatible = "gpio-leds";

                led_power: power {
                        color = <LED_COLOR_ID_BLUE>;
                        function = LED_FUNCTION_POWER;
                        gpios = <&pio 4 GPIO_ACTIVE_LOW>;
                        default-state = "on";
                };

                internet {
                        color = <LED_COLOR_ID_BLUE>;
                        function = LED_FUNCTION_WAN_ONLINE;
                        gpios = <&pio 7 GPIO_ACTIVE_LOW>;
                };

                led_wps: wps {
                        color = <LED_COLOR_ID_BLUE>;
                        function = LED_FUNCTION_WPS;
                        gpios = <&pio 5 GPIO_ACTIVE_LOW>;
                };

                wifi2g {
                        color = <LED_COLOR_ID_BLUE>;
                        function = LED_FUNCTION_WLAN_2GHZ;
                        gpios = <&pio 34 GPIO_ACTIVE_LOW>;
                        linux,default-trigger = "phy0tpt";
                };

                wifi5g {
                        color = <LED_COLOR_ID_BLUE>;
                        function = LED_FUNCTION_WLAN_5GHZ;
                        gpios = <&pio 35 GPIO_ACTIVE_LOW>;
                        linux,default-trigger = "phy1tpt";
                };

                wan {
                        color = <LED_COLOR_ID_BLUE>;
                        function = LED_FUNCTION_WAN;
                        gpios = <&pio 8 GPIO_ACTIVE_LOW>;
                };
        };
        usb_vbus: regulator-usb {
                compatible = "regulator-fixed";
                regulator-name = "usb-vbus";
                regulator-type = <1>; /* REGULATOR_VOLTAGE */
                regulator-min-microvolt = <5000000>;
                regulator-max-microvolt = <5000000>;
                gpios = <&pio 23 GPIO_ACTIVE_HIGH>;
                enable-active-high;
                regulator-boot-on;
        };
};

&switch {
        ports {
                port@0 {
                        reg = <1>;
                        label = "lan1";
                };

                port@1 {
                        reg = <2>;
                        label = "lan2";
                };

                port@2 {
                        reg = <3>;
                        label = "lan3";
                };
                port@3 {
                        reg = <4>;
                        label = "lan4";
                };
        };
};

&u2port0 {
        status = "okay";
};

&u3port0 {
        status = "okay";
};

&xhci {
    compatible = "mediatek,mt7986-xhci", "mediatek,mtk-xhci";
    reg = <0 0x11200000 0 0x2e00>, <0 0x11203e00 0 0x0100>;
    reg-names = "mac", "ippc";
    interrupts = <GIC_SPI 173 IRQ_TYPE_LEVEL_HIGH>;
    clocks = <&infracfg CLK_INFRA_IUSB_SYS_CK>,
             <&infracfg CLK_INFRA_IUSB_CK>,
             <&infracfg CLK_INFRA_IUSB_133_CK>,
             <&infracfg CLK_INFRA_IUSB_66M_CK>,
             <&topckgen CLK_TOP_U2U3_XHCI_SEL>;
    clock-names = "sys_ck", "ref_ck", "mcu_ck", "dma_ck", "xhci_ck";
    phys = <&u2port0 PHY_TYPE_USB2>, <&u3port0 PHY_TYPE_USB3>;
    vbus-supply = <&usb_vbus>;
    status = "okay";
};

&usb_phy {
    status = "okay";
    u2port0: usb-phy@0 {
        reg = <0x0 0x700>;
        clocks = <&topckgen CLK_TOP_USB_FRMCNT_SEL>;
        clock-names = "ref";
        #phy-cells = <1>;
    };
    u3port0: usb-phy@700 {
        reg = <0x700 0x900>;
        clocks = <&topckgen CLK_TOP_USB3_PHY_SEL>;
        clock-names = "ref";
        #phy-cells = <1>;
        mediatek,syscon-type = <&topmisc 0x218 0>;
        status = "okay";
    };
};
EOF

echo ">> Forcing zh_cn language..."
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-force-zh << 'EOF'
#!/bin/sh
uci set luci.main.lang=zh_cn
uci commit luci
EOF

echo ">> Configuring MultiLogin and OpenClash startup order..."
cat > package/base-files/files/etc/uci-defaults/98-multilogin-openclash-startup << 'EOF'
#!/bin/sh
uci -q set multilogin.global.enabled='1'
uci -q set multilogin.global.auth_check_interval='60'
uci -q commit multilogin

# Default to one uplink. Keep mwan3 installed for explicit later use.
/etc/init.d/mwan3 stop >/dev/null 2>&1
/etc/init.d/mwan3 disable
if [ "$(uci -q get network.wan6.proto)" = 'dhcpv6' ]; then
    uci -q set network.wan6.sourcefilter='0'
fi

# OpenWrt 25.12 的全局 DUID 会让多个 macvlan 共用 DHCP 身份。
# 如果已存在 MultiLogin 虚拟 WAN，则让 IPv6 复用第一个已认证 macvlan，
# 而不是启用物理 wan6 或额外占用一个校园网账号。
uci -q delete network.globals.dhcp_default_duid
if uci -q get network.auto_vwan_1 >/dev/null 2>&1; then
    uci -q set network.wan.disabled='1'
    uci -q set network.wan6.disabled='1'
    for index in 1 2 3 4; do
        ipv4_interface="auto_vwan_$index"
        ipv6_interface="${ipv4_interface}_6"
        ipv6_device="$(uci -q get "network.$ipv4_interface.device")"
        [ -n "$ipv6_device" ] || continue

        uci -q set "network.$ipv6_device.ipv6=1"
        uci -q set "network.$ipv6_interface=interface"
        uci -q set "network.$ipv6_interface.device=$ipv6_device"
        uci -q set "network.$ipv6_interface.proto=dhcpv6"
        uci -q set "network.$ipv6_interface.metric=$((20 + index))"
        uci -q set "network.$ipv6_interface.reqaddress=try"
        uci -q set "network.$ipv6_interface.reqprefix=no"
        uci -q set "network.$ipv6_interface.sourcefilter=0"
        uci -q set "network.$ipv6_interface.multipath=off"
        uci -q delete "network.$ipv6_interface.norelease"

        multilogin_section="$(uci -q show multilogin | sed -n "s/^\(multilogin\.[^.]*\)\.interface='$ipv4_interface'$/\1/p" | head -n1)"
        [ -z "$multilogin_section" ] || uci -q set "$multilogin_section.v6face=$ipv6_interface"

        uci -q del_list firewall.@zone[1].network="$ipv6_interface"
        uci -q add_list firewall.@zone[1].network="$ipv6_interface"
    done
fi
uci -q commit network
uci -q commit multilogin

# 校园网不下发 PD 时，向 LAN 发布 ULA 默认路由，并在 WAN zone 启用 NAT66。
uci -q set dhcp.lan.ra_default='1'
uci -q commit dhcp
uci -q set firewall.@zone[1].masq6='1'
uci -q commit firewall

# IPv4 与 IPv6 使用独立 policy；HTTPS 特例只匹配 IPv4。
uci -q set mwan3.https.family='ipv4'
for index in 1 2 3 4; do
    ipv6_interface="auto_vwan_${index}_6"
    ipv6_member="${ipv6_interface}_m1_w5"
    uci -q set "mwan3.$ipv6_interface=interface"
    uci -q set "mwan3.$ipv6_interface.enabled=1"
    uci -q set "mwan3.$ipv6_interface.family=ipv6"
    uci -q set "mwan3.$ipv6_interface.initial_state=online"
    uci -q set "mwan3.$ipv6_interface.track_method=ping"
    uci -q set "mwan3.$ipv6_interface.reliability=1"
    uci -q set "mwan3.$ipv6_interface.count=1"
    uci -q set "mwan3.$ipv6_interface.size=56"
    uci -q set "mwan3.$ipv6_interface.max_ttl=60"
    uci -q set "mwan3.$ipv6_interface.timeout=3"
    uci -q set "mwan3.$ipv6_interface.interval=5"
    uci -q set "mwan3.$ipv6_interface.failure_interval=5"
    uci -q set "mwan3.$ipv6_interface.recovery_interval=5"
    uci -q set "mwan3.$ipv6_interface.down=3"
    uci -q set "mwan3.$ipv6_interface.up=3"
    uci -q delete "mwan3.$ipv6_interface.track_ip"
    uci -q add_list "mwan3.$ipv6_interface.track_ip=2001:da8:c800::33"
    uci -q add_list "mwan3.$ipv6_interface.track_ip=240c::6666"
    uci -q set "mwan3.$ipv6_member=member"
    uci -q set "mwan3.$ipv6_member.interface=$ipv6_interface"
    uci -q set "mwan3.$ipv6_member.metric=1"
    uci -q set "mwan3.$ipv6_member.weight=5"
done
uci -q set mwan3.balanced_v6='policy'
uci -q delete mwan3.balanced_v6.use_member
for index in 1 2 3 4; do
    uci -q add_list "mwan3.balanced_v6.use_member=auto_vwan_${index}_6_m1_w5"
done
uci -q set mwan3.default_rule_v6.use_policy='balanced_v6'
uci -q set mwan3.default_rule_v6.family='ipv6'
uci -q set mwan3.default_rule_v6.proto='all'
uci -q set mwan3.default_rule_v6.sticky='0'
uci -q commit mwan3

# OpenClash Fake-IP 停止后，dnsmasq 必须恢复到真实的 IPv4 上游 DNS。
# 运行中若已经指向 7874，只更新 OpenClash 的备份列表，避免 DNS 旁路。
uci -q delete openclash.config.dnsmasq_server
uci -q add_list openclash.config.dnsmasq_server='223.5.5.5'
uci -q add_list openclash.config.dnsmasq_server='119.29.29.29'
uci -q set openclash.config.dnsmasq_filter_aaaa='0'
uci -q set dhcp.@dnsmasq[0].filter_aaaa='0'

# 校园认证域名返回私网地址，只为该域名放行 DNS 重绑定检查。
case " $(uci -q get dhcp.@dnsmasq[0].rebind_domain) " in
    *" login.cqu.edu.cn "*) ;;
    *) uci -q add_list dhcp.@dnsmasq[0].rebind_domain='login.cqu.edu.cn' ;;
esac
uci -q commit dhcp
dnsmasq_servers="$(uci -q get dhcp.@dnsmasq[0].server)"
case "$dnsmasq_servers" in
    *127.0.0.1#7874*) ;;
    *)
        for dns_server in 223.5.5.5 119.29.29.29; do
            case " $dnsmasq_servers " in
                *" $dns_server "*) ;;
                *) uci -q add_list dhcp.@dnsmasq[0].server="$dns_server" ;;
            esac
        done
        uci -q commit dhcp
        ;;
esac

uci -q set openclash.config.delay_start='30'
uci -q set openclash.config.custom_fakeip_filter='1'
uci -q set openclash.config.default_dashboard='metacubexd'
uci -q commit openclash

fakeip_filter='/etc/openclash/custom/openclash_custom_fake_filter.list'
if [ -f "$fakeip_filter" ] && ! grep -qxF 'login.cqu.edu.cn' "$fakeip_filter"; then
    printf '%s\n' 'login.cqu.edu.cn' >> "$fakeip_filter"
fi
exit 0
EOF

echo ">> Installing the UA3F transparent profile and lifecycle helper..."
cp -a ../files/. package/base-files/files/
chmod +x package/base-files/files/usr/libexec/n30pro-ua3f-tproxy
chmod +x package/base-files/files/etc/uci-defaults/99-ua3f-transparent

echo ">> Injecting custom TTL/Hoplimit rules..."
mkdir -p package/base-files/files/etc/nftables.d
cat > package/base-files/files/etc/nftables.d/10-custom-ttl.nft << 'EOF'
chain custom_ttl_postrouting {
    type filter hook postrouting priority mangle; policy accept;
    iifname "br-lan" ip ttl set 64
    iifname "br-lan" meta l4proto != ipv6-icmp ip6 hoplimit set 64
}
EOF
