#!/bin/bash
# Description: OpenWrt DIY script part 1 (Before Update feeds)

set -euo pipefail

echo ">> Adding pinned UA3F v3.6.0 (with its LuCI page)..."
UA3F_REV=ac39645779823e94628435a2d69cd086a4e4b9fc
git clone --depth=1 --branch v3.6.0 https://github.com/SunBK201/UA3F.git package/UA3F
test "$(git -C package/UA3F rev-parse HEAD)" = "$UA3F_REV"
patch -d package/UA3F -p1 < ../patches/ua3f-openwrt-nft.patch

echo ">> Adding Argon theme and its configuration page..."
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git -C package/luci-theme-argon fetch --depth=1 origin 0546f975a66796a89ff988524290c4a2e2d01855
git -C package/luci-theme-argon checkout --detach 0546f975a66796a89ff988524290c4a2e2d01855
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config
git -C package/luci-app-argon-config fetch --depth=1 origin 3e099a37c3f71d0de677f1b6b0f4bffd57d91dac
git -C package/luci-app-argon-config checkout --detach 3e099a37c3f71d0de677f1b6b0f4bffd57d91dac

echo ">> Adding pinned OpenList and its LuCI page..."
OPENLIST_REV=4bf72661c700d7209e78228f3d3c618443d5b9df
git clone --depth=1 https://github.com/OpenListTeam/OpenList-OpenWRT.git package/openlist
git -C package/openlist fetch --depth=1 origin "$OPENLIST_REV"
git -C package/openlist checkout --detach "$OPENLIST_REV"

echo ">> Adding OpenClash..."
git clone --depth=1 --filter=blob:none --sparse https://github.com/vernesong/OpenClash.git package/openclash
git -C package/openclash sparse-checkout set luci-app-openclash
patch -d package/openclash/luci-app-openclash -p1 < ../patches/openclash-single-dashboard.patch

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

echo ">> Patching MultiLogin for single-uplink operation..."
patch -d package/luci-app-multi-login -p1 < ../patches/multilogin-single-uplink.patch

echo ">> Adding the ZeroTier LuCI page (from ImmortalWrt)..."
# Keep the donor checkout outside package/ to avoid duplicate package definitions.
git clone --depth=1 --filter=blob:none --sparse https://github.com/immortalwrt/luci.git ../immortalwrt-luci-source
git -C ../immortalwrt-luci-source sparse-checkout set applications/luci-app-zerotier
cp -r ../immortalwrt-luci-source/applications/luci-app-zerotier package/luci-app-zerotier
sed -i 's|^include ../../luci.mk$|include $(TOPDIR)/feeds/luci/luci.mk|' package/luci-app-zerotier/Makefile
