#!/bin/bash
# Description: OpenWrt DIY script part 1 (Before Update feeds)

set -euo pipefail

echo ">> Adding UA3F v3.6.0 (includes LuCI and Chinese translation)..."
git clone --depth=1 --branch v3.6.0 https://github.com/SunBK201/UA3F.git package/UA3F

echo ">> Adding OpenClash..."
git clone --depth=1 --filter=blob:none --sparse https://github.com/vernesong/OpenClash.git package/openclash
git -C package/openclash sparse-checkout set luci-app-openclash

echo ">> Adding OpenList..."
git clone --depth=1 https://github.com/OpenListTeam/OpenList-OpenWRT.git package/openlist

echo ">> Adding luci-app-multi-login..."
# Keep the source revision used by the existing authentication/IPv6 patches.
# Upstream v3 rewrote these files and is not compatible with the patches.
MULTILOGIN_REV=fb272e8285c65415dea8a9a359a4204b94be06a0
git clone --depth=1 https://github.com/Zesuy/luci-app-multi-login.git package/luci-app-multi-login
git -C package/luci-app-multi-login fetch --depth=1 origin "$MULTILOGIN_REV"
git -C package/luci-app-multi-login checkout --detach "$MULTILOGIN_REV"

echo ">> Patching MultiLogin authentication checks..."
patch -d package/luci-app-multi-login -p1 < ../patches/multilogin-auth-check.patch

echo ">> Patching MultiLogin IPv6 uplink generation..."
patch -d package/luci-app-multi-login -p1 < ../patches/multilogin-ipv6-uplink.patch

echo ">> Adding luci-app-syncdial (from ImmortalWrt)..."
git clone --depth=1 --filter=blob:none --sparse https://github.com/immortalwrt/luci.git package/immortalwrt-luci
git -C package/immortalwrt-luci sparse-checkout set applications/luci-app-syncdial
cp -r package/immortalwrt-luci/applications/luci-app-syncdial package/luci-app-syncdial
rm -rf package/immortalwrt-luci
