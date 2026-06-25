# 项目记忆与技能库 (Project Memory & Skills)

## MT7981 (磊科 N30 Pro) USB 无法供电与 RNDIS 无效的修复机制
- **问题描述**：原版 OpenWrt/ImmortalWrt 在编译 Netis NX30V2 (MT7981) 时，USB 无法通电，即使配置了 `kmod-usb-net-rndis` 等驱动也无法识别随身WiFi。
- **根本原因**：设备底层硬件描述 (dtsi) 中由于官方未使用 USB，剔除了 USB 主控（xHCI）和物理层（usb_phy）的时钟基准信号和物理寄存器初始化。
- **解决方案**：
  必须在 DTS 中强制重新注入时钟定义，而不仅仅是设定 `status = "okay"`。具体步骤：
  1. 定义 `regulator-fixed` 供电针脚 (`pio 23 GPIO_ACTIVE_HIGH`) 并开启 `regulator-boot-on`。
  2. 显式覆盖 `&xhci` 节点，注入包括 `CLK_INFRA_IUSB_SYS_CK` 在内的 5 个必选时钟，并挂载 `vbus-supply`。
  3. 显式覆盖 `&usb_phy` 节点，为 `u2port0` 和 `u3port0` 分别注入 `ref` 时钟与 `syscon-type` 物理寄存器地址。
- **代码参考**：见 `diy-part2.sh` 中利用 `cat << "EOF" >> "$DTS_FILE"` 动态追加覆盖 DTS 节点的部分。采用追加方式能有效防止与新版 ImmortalWrt 自身的 LED、引脚库等产生冲突。

## 构建分支选择策略
- ImmortalWrt 推荐使用固定稳定版分支（如 `openwrt-25.12`, `openwrt-24.10`）而不是 `master`。这能确保在云端编译时内核模块驱动的一致性，防止 `kmod` 校验失败。
