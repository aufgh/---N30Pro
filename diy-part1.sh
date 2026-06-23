#!/bin/bash
# ============================================================
# 磊科 N30 Pro OpenWrt 编译 - Part 1
# 在 feeds update 之前执行
# 功能：添加第三方插件源
# ============================================================

echo "========================================="
echo "  DIY Part 1: 添加第三方插件源"
echo "========================================="

# 1. UA3F - 校园网防检测（伪装 HTTP User-Agent）
echo ">> 添加 UA3F..."
git clone --depth=1 https://github.com/SunBK201/UA3F.git package/ua3f

# 2. OpenClash - 代理工具
echo ">> 添加 OpenClash..."
git clone --depth=1 https://github.com/vernesong/OpenClash.git package/OpenClash

# 3. Argon 主题 - 现代化 LuCI 主题
echo ">> 添加 Argon 主题..."
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

echo "========================================="
echo "  DIY Part 1 完成！"
echo "========================================="
