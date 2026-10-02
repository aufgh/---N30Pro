# 固件精简与当前路由器处理

2026-10-02：当前固件的 UBI 固件卷约 98.1 MiB，rootfs_data 卷约 8.5 MiB，UBIFS 显示可写容量约 5.9 MiB。OpenClash ARM64 内核约 10.3 MiB，无法写入剩余约 4.7 MiB 的 overlay。

## 本次选择

- 不再预装 PassWall、sing-box、geoview、v2ray-geoip、v2ray-geosite、SyncDial。
- 保留 OpenClash 的 MetaCubeXD 面板，打包时排除 Zashboard；两者是同一个 Mihomo 核心的不同控制界面，并非两套核心。
- 保留 MultiLogin、mwan3 核心和管理页面、macvlan、UA3F、hev、IPv6、OpenList、ZeroTier，以及尚未要求移除的 Samba 等软件。
- 现有 MultiLogin 登录/状态请求仍调用 `mwan3 use`，不能将 mwan3 随 SyncDial 一起删除。服务可以保持关闭，接口绑定工具仍需存在。

主文件解压后统计：sing-box 约 54.7 MiB、两份 v2ray 数据约 26.3 MiB、geoview 约 6.8 MiB、Zashboard 约 4.4 MiB。它们不是压缩固件占用，不能据此承诺精简后释放的可写容量；以新镜像大小和刷机后卷布局为准。

## 当前设备

通过 APK 卸载上述五个组件；PassWall 本体及语言包已在此前卸载。SyncDial 和 OpenClash 配置、APK world 在路由器 `/root/*pre-trim-20261002` 保留权限 600 的备份。Zashboard 删除前备份至电脑工作区 `work/pre-trim-build/zashboard.pre-trim-20261002.tar.gz`，删除范围经用户确认。

只读 SquashFS 中的原始文件仍存在，卸载是通过 overlay 隐藏它们，因此不会明显增加当前可写空间。OpenClash 内核仍在 `/tmp/etc/openclash/core/clash_meta`；小闪存模式配置持久化，内存中的内核重启后丢失。本次未启动 OpenClash 或修改校园认证账号、WAN、DNS 配置。

实机复核：五个指定包和对应程序/数据文件均已移除，Zashboard 不存在，MetaCubeXD 的 index.html 保留且设置为默认面板；mwan3、OpenList、ZeroTier 保留。UA3F 与 MultiLogin 仍运行，UA3F nft 表存在；路由器本机 IPv4、IPv6 HTTPS 均返回 200。可写区剩余 4,680 KiB，变化包含包管理记录、备份和隐藏记录，不能据此衡量精简收益。

## 编译验证

`.config` 排除上述包，移除已无用的 PassWall feeds 和 SyncDial 导入步骤。OpenClash Makefile 补丁在生成包内容时过滤 Zashboard，保留其余文件，避免对源目录做递归删除。

本地回归检查通过 `tests/test_firmware_trim.py`：验证包选择，实际应用安装补丁并执行其打包复制命令，检查 MetaCubeXD、普通文件、隐藏文件、权限和符号链接均保留，Zashboard 不进入包内容。已有 UA3F 生命周期测试继续执行。

CI 在 `make defconfig` 后拒绝被重新选择的排除包，并在编译后检查 manifest 和最终根目录只包含 MetaCubeXD。当前本地环境不执行完整交叉编译；此版本尚需完整构建和刷机验证容量。
