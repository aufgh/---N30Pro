#!/bin/bash
# Description: OpenWrt DIY script part 1 (Before Update feeds)

set -euo pipefail

echo ">> Adding UA2F v5.2.0..."
git clone --depth=1 --branch v5.2.0 https://github.com/Zxilly/UA2F.git package/UA2F
patch -d package/UA2F -p1 < ../patches/ua2f-release-build.patch

echo ">> Adding UA2F Chinese LuCI configuration page..."
UA2F_LUCI_REV=abce6b21c88643ead4a88d1a8144ef4813c002fd
git clone --depth=1 https://github.com/lucikap/luci-app-ua2f.git package/ua2f-luci
git -C package/ua2f-luci fetch --depth=1 origin "$UA2F_LUCI_REV"
git -C package/ua2f-luci checkout --detach "$UA2F_LUCI_REV"
patch -d package/ua2f-luci -p1 < ../patches/luci-app-ua2f-compat.patch

echo ">> Adding APK-compatible iStore feed..."
printf '\n%s\n' 'src-git istore https://github.com/linkease/istore^a97ace34f2da358a015b094d326bba2697697f2e' >> feeds.conf.default

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
sed -i 's|^include ../../luci.mk$|include $(TOPDIR)/feeds/luci/luci.mk|' package/luci-app-syncdial/Makefile
rm -rf package/immortalwrt-luci
