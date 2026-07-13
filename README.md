# 磊科 N30 Pro OpenWrt 自编译固件

## 📌 设备信息

| 项目 | 内容 |
|------|------|
| 设备 | 磊科 Netcore N30 Pro |
| OpenWrt 代号 | `netis_nx30v2` |
| 芯片组 | MT7981B + MT7976CN + MT7531AE |
| 接口 | 5×千兆网口 + 1×USB 3.0 |
| 源码分支 | `openwrt-25.12` |

## 🔌 已安装插件

| 插件 | 功能 | 说明 |
|------|------|------|
| LuCI + 中文 | 管理界面 | 简体中文 |
| mwan3 | 多线多拨 | 校园网多拨 |
| syncdial | 同步多拨 | 配合 mwan3 |
| MultiLogin | 自动认证 | 多 WAN 校园网自动登录 |
| UA-Mask | 防检测 | 校园网 User-Agent 伪装 |
| OpenClash | 代理 | Firewall4/nftables 模式 |
| OpenList | 文件管理 | OpenList 服务及 LuCI 界面 |

## ⚡ USB 支持

已通过 DTS 补丁修复底层的 USB 硬件支持。
固件已包含 USB 2.0/3.0、USB 存储及 RNDIS/CDC/MBIM/QMI 网络设备支持。

## OpenClash 说明

OpenClash 使用 OpenWrt 25.12 默认的 Firewall4/nftables 后端，不包含旧版 iptables 依赖。固件包含 LuCI 插件及完整运行依赖；首次使用时请在 OpenClash 的版本更新页面选择 `linux-arm64` 并下载 Mihomo 核心。

## 🚀 使用方法

### 方式一：GitHub Actions 云编译

1. Fork 本仓库
2. 进入 Actions 页面
3. 选择 **Build OpenWrt for Netcore N30 Pro**
4. 点击 **Run workflow**
5. 等待编译完成（约 2-4 小时）
6. 在 Releases 中下载固件

## 🔧 默认设置

- 管理地址：使用 OpenWrt 默认设置
- 默认密码：无（首次登录自行设置）

## 📁 文件说明

```
├── .config                           # OpenWrt 编译配置
├── .github/workflows/build-openwrt.yml  # GitHub Actions 工作流
├── diy-part1.sh                      # 编译前脚本（添加第三方源）
├── diy-part2.sh                      # 编译后脚本（DTS补丁+默认设置）
└── README.md                         # 本文件
```

## 🙏 参考

- [磊科N30 Pro OpenWRT刷机及开启USB支持](https://blog.csdn.net/hsyxxyg/article/details/161982524)
- [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt)
- [OpenWrt 官方](https://openwrt.org/)
