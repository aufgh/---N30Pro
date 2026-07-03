#!/bin/bash
# Description: OpenWrt DIY script part 1 (Before Update feeds)

echo ">> Adding UA3F..."
git clone --depth=1 https://github.com/Zxilly/UA3F.git package/UA3F

echo ">> Adding iStore..."
git clone --depth=1 https://github.com/linkease/istore.git package/istore
git clone --depth=1 https://github.com/linkease/istore-ui.git package/istore-ui

echo ">> Adding luci-app-syncdial (from ImmortalWrt)..."
svn export https://github.com/immortalwrt/luci/trunk/applications/luci-app-syncdial package/luci-app-syncdial
