#!/bin/bash
# Description: OpenWrt DIY script part 1 (Before Update feeds)

set -euo pipefail

echo ">> Adding UAMask..."
git clone --depth=1 https://github.com/Zesuy/UA-Mask.git package/UA-Mask

echo ">> Adding OpenClash..."
git clone --depth=1 --filter=blob:none --sparse https://github.com/vernesong/OpenClash.git package/openclash
git -C package/openclash sparse-checkout set luci-app-openclash

echo ">> Adding OpenList..."
git clone --depth=1 https://github.com/OpenListTeam/OpenList-OpenWRT.git package/openlist

echo ">> Adding luci-app-multi-login..."
git clone --depth=1 https://github.com/Zesuy/luci-app-multi-login.git package/luci-app-multi-login

echo ">> Adding luci-app-syncdial (from ImmortalWrt)..."
git clone --depth=1 --filter=blob:none --sparse https://github.com/immortalwrt/luci.git package/immortalwrt-luci
git -C package/immortalwrt-luci sparse-checkout set applications/luci-app-syncdial
cp -r package/immortalwrt-luci/applications/luci-app-syncdial package/luci-app-syncdial
rm -rf package/immortalwrt-luci
