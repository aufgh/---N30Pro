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
| Argon 主题 | 界面美化 | 现代化深色主题 |
| mwan3 | 多线多拨 | 校园网多拨 |
| syncdial | 同步多拨 | 配合 mwan3 |
| UA3F | 防检测 | 校园网 User-Agent 伪装 |
| OpenClash | 代理 | 科学上网 |
| ZeroTier | 内网穿透 | P2P VPN |

## ⚡ USB 支持

已通过 DTS 补丁修复底层的 USB 硬件支持。
由于精简了固件体积，默认未安装 USB 相关内核包。如需使用 USB，请在系统内自行安装以下组件：
- `kmod-usb3`, `kmod-usb-storage` (USB 存储)
- `kmod-usb-net-rndis` (随身 WiFi 共享)

## 🚀 使用方法

### 方式一：GitHub Actions 云编译

1. Fork 本仓库
2. 进入 Actions 页面
3. 选择 **Build OpenWrt for Netcore N30 Pro**
4. 点击 **Run workflow**
5. 等待编译完成（约 2-4 小时）
6. 在 Artifacts 或 Releases 中下载固件

### 方式二：SSH 调试模式

运行 workflow 时将 SSH 参数设为 `true`，可以通过 SSH 连接到编译环境，手动执行 `make menuconfig` 调整配置。

## 🔧 默认设置

- 管理地址：`192.168.6.1`
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
