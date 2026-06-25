#!/bin/bash
# ============================================================
# 磊科 N30 Pro ImmortalWrt 编译 - Part 1
# 在 feeds update 之前执行
# 功能：添加第三方插件源
# ============================================================

echo "========================================="
echo "  DIY Part 1: 添加第三方插件源"
echo "========================================="

# 1. 添加常用第三方软件源 (kenzok8/small-package 包含 OpenClash, Argon 等大量常用插件)
echo ">> 添加 kenzok8/small-package 软件源..."
echo 'src-git smpackage https://github.com/kenzok8/small-package' >> feeds.conf.default

# 2. UA-Mask (防检测)
echo ">> 添加 UA-Mask..."
git clone --depth=1 https://github.com/Zesuy/UA-Mask.git package/uamask

echo "========================================="
echo "  DIY Part 1 完成！"
echo "========================================="
