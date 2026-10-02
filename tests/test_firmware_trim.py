"""Check package selection and exercise the actual OpenClash install patch."""
from pathlib import Path
import os
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
EXCLUDED = (
    "luci-app-passwall", "luci-app-syncdial", "sing-box", "geoview",
    "v2ray-geoip", "v2ray-geosite",
)
# The install section of upstream OpenClash 0.47.156 Makefile.
INSTALL_SECTION = """define Package/$(PKG_NAME)/install
\t$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
\t$(INSTALL_DATA) $(PKG_BUILD_DIR)/*.*.lmo $(1)/usr/lib/lua/luci/i18n/
\t$(CP) $(PKG_BUILD_DIR)/root/* $(1)/
\t$(CP) $(PKG_BUILD_DIR)/luasrc/* $(1)/usr/lib/lua/luci/
endef
"""


class FirmwareTrimTests(unittest.TestCase):
    def test_package_policy(self):
        config = REPO.joinpath(".config").read_text().splitlines()
        for package in EXCLUDED:
            self.assertIn(f"# CONFIG_PACKAGE_{package} is not set", config)
            self.assertNotIn(f"CONFIG_PACKAGE_{package}=y", config)
        for package in ("ua3f", "hev-socks5-tproxy", "luci-app-multilogin",
                        "mwan3", "openlist", "zerotier", "luci-app-openclash",
                        "odhcp6c", "odhcpd-ipv6only"):
            self.assertIn(f"CONFIG_PACKAGE_{package}=y", config)

    def test_package_payload_omits_only_zashboard(self):
        with tempfile.TemporaryDirectory(prefix="openclash-trim-") as directory:
            root = Path(directory)
            makefile = root / "Makefile"
            makefile.write_text(INSTALL_SECTION)
            subprocess.run([
                "patch", "--batch", "-p1", "-i",
                str(REPO / "patches/openclash-single-dashboard.patch"),
            ], cwd=root, check=True, capture_output=True, text=True)
            source = root / "build/root"
            target = root / "payload"
            target.mkdir()
            files = (
                "usr/share/openclash/ui/metacubexd/index.html",
                "usr/share/openclash/ui/metacubexd/assets/main.js",
                "usr/share/openclash/ui/zashboard/index.html",
                "usr/share/openclash/ui/zashboard/assets/main.js",
                "usr/share/openclash/zashboard-helper.sh",
                "etc/init.d/openclash", "etc/openclash/.keep",
            )
            for name in files:
                path = source / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(name)
            os.chmod(source / "etc/init.d/openclash", 0o755)
            os.symlink("metacubexd", source / "usr/share/openclash/ui/default")
            command = next(line.strip() for line in makefile.read_text().splitlines()
                           if line.lstrip().startswith("tar -C"))
            command = command.replace("$(PKG_BUILD_DIR)", str(root / "build"))
            command = command.replace("$(1)", str(target))
            subprocess.run(["bash", "-o", "pipefail", "-c", command], check=True)
            self.assertFalse((target / "usr/share/openclash/ui/zashboard").exists())
            for name in files:
                if "/ui/zashboard/" not in name:
                    self.assertEqual((target / name).read_bytes(),
                                     (source / name).read_bytes())
            self.assertEqual(os.readlink(target / "usr/share/openclash/ui/default"),
                             "metacubexd")
            self.assertTrue(os.access(target / "etc/init.d/openclash", os.X_OK))


if __name__ == "__main__":
    unittest.main()
