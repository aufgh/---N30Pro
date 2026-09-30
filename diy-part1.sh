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
# This upstream controller is committed with CRLF; the patch uses LF.
sed -i 's/\r$//' package/ua2f-luci/luci-app-ua2f/controller/autoua2f.lua
patch -d package/ua2f-luci -p1 < ../patches/luci-app-ua2f-compat.patch

echo ">> Adding APK-compatible iStore feed..."
printf '\n%s\n' 'src-git istore https://github.com/linkease/istore^a97ace34f2da358a015b094d326bba2697697f2e' >> feeds.conf.default

echo ">> Adding pinned PassWall feeds before the default feeds..."
sed -i '1i src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git^cadc39bc5cfc67098de4797d52b1f12673351f09\nsrc-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git^1a826389f1920dbfcab1dbb811776347cc5fdfa8' feeds.conf.default

echo ">> Adding Argon theme and its configuration page..."
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git -C package/luci-theme-argon fetch --depth=1 origin 0546f975a66796a89ff988524290c4a2e2d01855
git -C package/luci-theme-argon checkout --detach 0546f975a66796a89ff988524290c4a2e2d01855
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config
git -C package/luci-app-argon-config fetch --depth=1 origin 3e099a37c3f71d0de677f1b6b0f4bffd57d91dac
git -C package/luci-app-argon-config checkout --detach 3e099a37c3f71d0de677f1b6b0f4bffd57d91dac

echo ">> Adding OpenClash..."
git clone --depth=1 --filter=blob:none --sparse https://github.com/vernesong/OpenClash.git package/openclash
git -C package/openclash sparse-checkout set luci-app-openclash

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
