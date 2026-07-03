#!/bin/bash
# Description: OpenWrt DIY script part 1 (Before Update feeds)

echo ">> Adding UA3F..."
git clone --depth=1 https://github.com/SunBK201/UA3F.git package/UA3F

echo ">> Adding iStore feed..."
echo 'src-git istore https://github.com/linkease/istore;main' >> feeds.conf.default

echo ">> Adding luci-app-multi-login..."
git clone --depth=1 https://github.com/Zesuy/luci-app-multi-login.git package/luci-app-multi-login

echo ">> Adding luci-app-syncdial (from ImmortalWrt)..."
git clone --depth=1 --filter=blob:none --sparse https://github.com/immortalwrt/luci.git package/immortalwrt-luci
cd package/immortalwrt-luci
git sparse-checkout set applications/luci-app-syncdial
cd ../..
cp -r package/immortalwrt-luci/applications/luci-app-syncdial package/luci-app-syncdial
rm -rf package/immortalwrt-luci
