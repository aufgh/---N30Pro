#!/bin/bash
# ============================================================
# 磊科 N30 Pro ImmortalWrt 编译 - Part 2
# 在 feeds install 之后执行
# 功能：修改默认设置 + 应用 DTS 补丁（USB 修复）
# ============================================================

echo "========================================="
echo "  DIY Part 2: 自定义配置 + DTS 补丁"
echo "========================================="

# 1. 自动配置 fw4 (nftables) 的 TTL 固定规则 (包含 IPv4 和 IPv6)
echo ">> 注入固定 TTL (IPv4) 和 Hoplimit (IPv6) 防火墙规则..."
cat << "EOF" >> package/base-files/files/etc/firewall.user
# 现代版 fw4 (nftables) 固定 TTL 和 Hoplimit
nft add rule inet fw4 mangle_postrouting ip ttl set 64
nft add rule inet fw4 mangle_prerouting ip ttl set 64
nft add rule inet fw4 mangle_postrouting ip6 hoplimit set 64
nft add rule inet fw4 mangle_prerouting ip6 hoplimit set 64
EOF

# 修改 firewall 配置以使 fw4 兼容并执行 firewall.user
cat << "EOF" >> package/network/config/firewall/files/firewall.config

config include
	option path '/etc/firewall.user'
	option type 'script'
	option fw4_compatible '1'
EOF

# 4. 应用 DTS 补丁 - 修复 USB 供电 + RNDIS 网络共享
# 由于 ImmortalWrt 的内核版本可能会更新（如 6.1 或 6.6），DTS 路径会改变。
# 并且完全替换整个 DTS 文件可能会导致与 ImmortalWrt 其它配置（如 LED、交换机）冲突。
# 因此我们采用动态查找并【追加重写】的方式，保证安全兼容。
echo ">> 应用 DTS 补丁（USB 供电 + RNDIS 修复）..."

DTS_FILE=$(find target/linux/mediatek -name "mt7981b-netis-nx30v2.dts" -print -quit)

if [ -n "$DTS_FILE" ]; then
    echo ">> 找到 DTS 文件: $DTS_FILE，正在追加 USB 修复节点..."
    cat << "EOF" >> "$DTS_FILE"

// ======== 自定义 USB 供电与 RNDIS 修复补丁 (追加覆盖) ========
/ {
        usb_vbus: regulator-usb {
                compatible = "regulator-fixed";
                regulator-name = "usb-vbus";
                regulator-type = <1>; /* REGULATOR_VOLTAGE */
                regulator-min-microvolt = <5000000>;
                regulator-max-microvolt = <5000000>;
                gpios = <&pio 23 GPIO_ACTIVE_HIGH>;
                enable-active-high;
                regulator-boot-on;
                /* 注意: 不开启 regulator-always-on，
                   否则软重启时无法通过电源循环触发 USB 复位 */
        };
};

&u2port0 {
        status = "okay";
};

&u3port0 {
        status = "okay";
};

/* xHCI USB 控制器 - 关键配置：时钟与电源参数 */
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

/* USB PHY 控制器 - 物理层参数 */
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
// ======== 补丁结束 ========
EOF
    echo ">> DTS 补丁自适应追加成功！"
else
    echo ">> [错误] 未找到 mt7981b-netis-nx30v2.dts 文件！请检查分支和目标设备名。"
fi

echo "========================================="
echo "  DIY Part 2 完成！"
echo "========================================="
