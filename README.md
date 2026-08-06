# AutoBuild-OpenWrt
[![LICENSE](https://img.shields.io/github/license/xiaot-evo/AutoBuild-OpenWrt.svg?style=flat&logo=github&label=LICENSE)](https://github.com/xiaot-evo/AutoBuild-OpenWrt/blob/master/LICENSE)
![GitHub Stars](https://img.shields.io/github/stars/xiaot-evo/AutoBuild-OpenWrt.svg?style=flat&logo=appveyor&label=Stars&logo=github)
![GitHub Forks](https://img.shields.io/github/forks/xiaot-evo/AutoBuild-OpenWrt.svg?style=flat&logo=appveyor&label=Forks&logo=github)
![GitHub last commit](https://img.shields.io/github/last-commit/xiaot-evo/AutoBuild-OpenWrt?label=Latest%20Commit&logo=github)

English | [简体中文](README_zh.md)

Build OpenWrt firmware for multiple devices via GitHub Actions. Forked from [eSirPlayground/AutoBuild-OpenWrt](https://github.com/eSirPlayground/AutoBuild-OpenWrt); all builds run in CI, no local toolchain required.

Thanks to:
- [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt/)
- [KFERMercer/OpenWrt-CI](https://github.com/KFERMercer/OpenWrt-CI/)

## Supported Devices

| Device | Workflow | Source | Branch | Arch |
|---|---|---|---|---|
| JDCloud AX3000 | `Build_JDCloud_AX3000.yml` | immortalwrt/immortalwrt | openwrt-25.12 | qualcommax/ipq50xx |
| Redmi AX5 JDCloud | `Build_Redmi_AX5_JDCloud.yml` | LiBwrt/LibWrt | 25.12-nss | qualcommax/ipq60xx |
| x86_64 | `Build_OP_x86_64.yml` | coolsnowwolf/lede | master | x86/64 |

## Usage

**1. Prerequisite**
  - Sign up for [GitHub Actions](https://github.com/features/actions/signup)
  - Fork [this repository](https://github.com/xiaot-evo/AutoBuild-OpenWrt)

**2. Compile Firmware**
  - Click `[.github/workflows]` folder on the top of repo and you could see few workflow files, each for one particular device.
  - Click "Actions" on the menu, click your favorite device on the left side, then click the "Run workflow" button on the right side and confirm.
  - The build starts automatically. Progress can be viewed on the Actions page.
  - When the build is complete, click the `Artifacts` button in the upper right corner of the Actions page to download the binaries.
  - The firmware is also published to GitHub Releases (fixed tag, overwritten on each build).
  - Default Web Admin IP: `192.168.10.1`, username `root`, no login password

**3. Sync Code**
  - Uncomment the `push-branches-master` lines under **`On`** section and commit changes to let the `Sync Code.yml` workflow sync the code from upstream once.
  - Uncomment the `schedule-cron` lines under **`On`** section to sync on a schedule.

## Build Customization

- Global `customize.sh` (all devices): rewrites the default LuCI IP to `192.168.10.1` in `package/base-files/files/bin/config_generate`.
- Device-specific `devices/<name>/customize.sh` runs inside the cloned source tree before feeds are updated:
  - **JDCloud AX3000**
    - Applies `device-files/*.patch` — full RE-CS-03 device support (DTS / ath11k BDF / eMMC upgrade / uboot-env / caldata), migrated from [jdc_re-cs-03](https://github.com/pmyy-wt/jdc_re-cs-03) (openwrt main) to immortalwrt openwrt-25.12
    - Adapted for the **big-partition** layout (`gpt.bin`): single-slot eMMC partitions `0:HLOS` / `rootfs` / `rootfs_data` / `swap`; `sysupgrade` targets the actual partition names (not the upstream dual-slot `*_1` names)
    - Persistent `rootfs_data` overlay via `fstools_partname_fallback_scan=1` bootarg (matched by GPT PARTNAME, so partition layout changes are tolerated)
  - **Redmi AX5 JDCloud / x86_64**: currently an empty template
- Build flow: checkout → free disk space → install deps → clone source + customize → `feeds update -a` / `feeds install -a` → config + `make defconfig` → `make download` → `make -j$(nproc) V=s` → upload artifact & release.
