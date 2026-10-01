# 参考固件软件对照

参考对象为用户提供的 `immortalwrt-mediatek-filogic-netcore_n30-pro-squashfs-sysupgrade.bin`。从镜像包数据库恢复出 407 个不同的软件包名称；这是成品安装清单，不能据此还原作者完整的 `.config`、源码补丁或 feeds 提交。

参考镜像基于 ImmortalWrt 24.10-SNAPSHOT / Linux 6.6.133。本项目继续使用 OpenWrt `openwrt-25.12` / APK，按功能重新解析依赖，不复制参考镜像中的旧版库、内核模块或认证配置。

## 管理插件和主题

| 参考镜像功能 | 本次配置 | 备注 |
|---|---|---|
| iStore | 移除 | 用户当前选择；同时移除专用 taskd 组件 |
| OpenClash | 预装 | 保留现有配置补丁；Mihomo 核心仍在刷机后下载 |
| PassWall | 预装 | nftables 模式；Sing-Box、Geoview、GeoIP、Geosite；保持上游默认关闭 |
| Samba4 | 预装 | 局域网文件共享，配合 Avahi / wsdd2 服务发现 |
| SQM | 预装 | 配置带宽和出口后使用；启用时需核对硬件流量卸载是否影响效果 |
| DDNS | 预装 | 包含服务商定义，须自行填写域名和账号 |
| UPnP | 预装 | 按需配置端口映射服务 |
| WOL | 预装 | 网络唤醒工具和页面 |
| Statistics | 移除 | 同时移除 collectd 采集模块 |
| ttyd | 预装 | 网页终端 |
| Firewall / Package Manager | 预装 | 原生防火墙页面和 APK 包管理页面 |
| Argon / Argon Config | 预装 | 固定上游提交；同时保留 Bootstrap 主题 |
| ZeroTier | 预装 | 官方服务及从 ImmortalWrt 导入的 LuCI 页面 |
| OpenList | 预装 | 本项目追加；固定 OpenList 官方包仓库提交 |

参考镜像中的 14 个 `luci-app-*` 应用，除用户当前排除的 iStore 和 Statistics 外，其余 12 个均已加入本项目的包选择；主题保留 Argon 和 Bootstrap。是否真正装入生成的固件，须以 GitHub Actions 的 `make defconfig` 检查及最终 manifest 检查为准。

## 本项目额外保留的功能

- MultiLogin、mwan3、syncdial：继续保留已有认证状态检查和 IPv6 上联补丁。
- UA3F v3.6.0 自带 LuCI 页面，替换 UA2F/UA-Mask；配合 hev-socks5-tproxy 默认启用 LAN 双栈 TCP 接管，认证仍由 MultiLogin 负责。详见 [UA3F 配置](ua3f-transparent-profile.md)。
- 固定 TTL / Hop Limit：保留现有规则，ICMPv6 控制报文不改为 64。
- OpenList：预装服务及 LuCI 页面；不依赖 iStore 安装。
- 单线路优先：mwan3 默认关闭，插件保留；MultiLogin 独立检查接口和认证状态，DHCPv6 上联取消源地址路由限制以支持 NAT66。

## 存储、网卡和网络协议

选择 USB 2.0/3.0、USB 存储与 UAS、ext4 / exFAT / NTFS3 / VFAT、block-mount、e2fsprogs，以及相关字符集模块。保留 RNDIS / CDC / MBIM / QMI，补齐 AQC111、ASIX、AX88179、LAN78xx、RTL8152 USB 网卡及 r8152 固件。补齐 WireGuard 和 relayd 协议页面、完整 wpad-openssl。

普通库和内核模块由当前源码依赖自动选择，因此数量和版本不会与参考镜像的 407 项完全相同。设备默认固件和 Wi-Fi 驱动继续由 `netis_nx30v2` 设备定义选择。

## 没有直接照搬的项目

- ImmortalWrt 的 `autocore`、`default-settings`、`default-settings-chn`、`shellsync` 等发行版辅助包：其初始化行为可能覆盖本项目设置，保留 OpenWrt 的管理功能和本项目中文默认配置。
- `automount`、`ntfs3-mount`：选择当前系统的 block-mount / 文件系统模块，通过挂载配置管理磁盘，不复制旧发行版初始化脚本。
- `kmod-nft-fullcone`：依赖 ImmortalWrt 内核和防火墙补丁，当前官方 OpenWrt 项目未复刻该扩展。
- `bridger`、`kmod-mtd-rw`、内核自测模块：未作为必需功能加入，不为复制软件数量而引入额外卸载行为或闪存写入工具。
- `opkg`、`luci-lib-ipkg`、版本化的旧 ABI 库：由当前 APK 系统及当前源码依赖替代。

OpenClash 和 PassWall 的流量接管、DNS 设置存在重叠。预装两套供选择，先只启用一套并验证认证、IPv4、IPv6 和 DNS；本次不创建订阅、节点或自动启用 PassWall。软件安装使用原生 APK Package Manager。

## 固定的第三方源码

| 来源 | 固定版本或提交 |
|---|---|
| UA3F | v3.6.0 / ac39645779823e94628435a2d69cd086a4e4b9fc |
| OpenList OpenWrt packages | 4bf72661c700d7209e78228f3d3c618443d5b9df |
| PassWall LuCI | 1a826389f1920dbfcab1dbb811776347cc5fdfa8 |
| PassWall packages | cadc39bc5cfc67098de4797d52b1f12673351f09 |
| Argon | 0546f975a66796a89ff988524290c4a2e2d01855 |
| Argon Config | 3e099a37c3f71d0de677f1b6b0f4bffd57d91dac |
| MultiLogin | fb272e8285c65415dea8a9a359a4204b94be06a0 |

OpenWrt 基础源码、官方 feeds、OpenClash 和 syncdial 沿用本项目更新方式，完整构建仍会受到这些上游更新的影响。
