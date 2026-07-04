#!/bin/bash
# Description: OpenWrt DIY script part 1 (Before Update feeds)

echo ">> Adding UAMask..."
git clone --depth=1 https://github.com/Zesuy/UA-Mask.git package/UA-Mask

echo ">> Adding luci-app-multi-login..."
git clone --depth=1 https://github.com/Zesuy/luci-app-multi-login.git package/luci-app-multi-login

echo ">> Adding luci-app-syncdial (from ImmortalWrt)..."
git clone --depth=1 --filter=blob:none --sparse https://github.com/immortalwrt/luci.git package/immortalwrt-luci
cd package/immortalwrt-luci
git sparse-checkout set applications/luci-app-syncdial
cd ../..
cp -r package/immortalwrt-luci/applications/luci-app-syncdial package/luci-app-syncdial
rm -rf package/immortalwrt-luci
