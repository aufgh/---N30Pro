# OpenWrt 构建记忆

## 第三方包名必须以 Makefile 为准

- `.config` 中的 `CONFIG_PACKAGE_*` 必须匹配第三方包 `Makefile` 里的 `Package/<name>`，不能根据 LuCI 菜单名称猜测。
- UA-Mask 的实际包名是 `UAmask`，对应 `CONFIG_PACKAGE_UAmask=y`，不是 `luci-app-uamask`。
- 每次接入第三方包后，都应在 `make defconfig` 后断言目标配置仍为 `y`；未知符号会被静默丢弃。

## OpenClash 在 OpenWrt 25.12 使用 Firewall4

- OpenWrt 25.12 默认使用 Firewall4/nftables 和 APK。
- OpenClash 检测到 `fw4` 后需要 `kmod-nft-tproxy` 与启用 nftset 的 `dnsmasq-full`，不需要旧版 iptables/ipset 包。
- `luci-app-openclash` 不包含 Mihomo 核心；N30 Pro 使用 `linux-arm64` 核心。
- OpenClash 构建前需要可用的 `po2lmo`，按上游工作流编译并安装其 `tools/po2lmo`。

## Firewall4 自定义 nftables 文件

- `/etc/nftables.d/*.nft` 被包含在 `table inet fw4 { ... }` 内。
- 文件中只能放集合、链或规则定义，不能再次声明 `table`，否则会产生非法嵌套并导致 Firewall4 规则加载失败。
