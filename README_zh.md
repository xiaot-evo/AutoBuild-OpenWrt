# AutoBuild-OpenWrt
[![LICENSE](https://img.shields.io/github/license/xiaot-evo/AutoBuild-OpenWrt.svg?style=flat&logo=github&label=LICENSE)](https://github.com/xiaot-evo/AutoBuild-OpenWrt/blob/master/LICENSE)
![GitHub Stars](https://img.shields.io/github/stars/xiaot-evo/AutoBuild-OpenWrt.svg?style=flat&logo=appveyor&label=Stars&logo=github)
![GitHub Forks](https://img.shields.io/github/forks/xiaot-evo/AutoBuild-OpenWrt.svg?style=flat&logo=appveyor&label=Forks&logo=github)
![GitHub last commit](https://img.shields.io/github/last-commit/xiaot-evo/AutoBuild-OpenWrt?label=Latest%20Commit&logo=github)

[English](README.md) | 简体中文

基于 [eSirPlayground/AutoBuild-OpenWrt](https://github.com/eSirPlayground/AutoBuild-OpenWrt) 的 OpenWrt 固件自动构建项目。通过 GitHub Actions 为多个设备编译固件并发布到 GitHub Releases，无需本地编译环境。

感谢：
- [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt/)
- [KFERMercer/OpenWrt-CI](https://github.com/KFERMercer/OpenWrt-CI/)

## 支持的设备

| 设备 | 工作流 | 源码 | 分支 | 架构 |
|---|---|---|---|---|
| JDCloud AX3000 | `Build_JDCloud_AX3000.yml` | immortalwrt/immortalwrt | openwrt-25.12 | qualcommax/ipq50xx |
| Redmi AX5 JDCloud | `Build_Redmi_AX5_JDCloud.yml` | LiBwrt/LibWrt | 25.12-nss | qualcommax/ipq60xx |
| x86_64 | `Build_OP_x86_64.yml` | coolsnowwolf/lede | master | x86/64 |

## 使用方法

**1. 准备**
  - 注册 [GitHub Actions](https://github.com/features/actions/signup)
  - Fork [本仓库](https://github.com/xiaot-evo/AutoBuild-OpenWrt)

**2. 编译固件**
  - 打开仓库顶部的 `[.github/workflows]` 文件夹，可以看到多个 workflow 文件，每个对应一台设备。
  - 点击菜单栏的 "Actions"，在左侧选择设备，点击右侧 "Run workflow" 按钮并确认。
  - 构建自动开始，进度可在 Actions 页面查看。
  - 构建完成后，点击 Actions 页面右上角的 `Artifacts` 按钮下载固件。
  - 固件同时发布到 GitHub Releases（固定 tag，每次构建覆盖更新）。
  - 默认管理地址：`192.168.10.1`，用户名 `root`，无登录密码

**3. 同步上游代码**
  - 取消注释 **`On`** 部分下的 `push-branches-master` 三行并提交，可让 `Sync Code.yml` 工作流同步一次上游代码。
  - 取消注释 **`On`** 部分下的 `schedule-cron` 两行，可按计划定时同步。

## 构建定制

- 全局 `customize.sh`（所有设备生效）：将 `package/base-files/files/bin/config_generate` 中的默认 IP 改写为 `192.168.10.1`。
- 设备专属 `devices/<name>/customize.sh`：在克隆的源码树内、feeds 更新之前运行：
  - **JDCloud AX3000**
    - 应用 `device-files/*.patch` —— RE-CS-03 完整设备支持（DTS / ath11k BDF / eMMC 升级 / uboot-env / caldata），从 [jdc_re-cs-03](https://github.com/pmyy-wt/jdc_re-cs-03)（openwrt main）迁移到 immortalwrt openwrt-25.12
    - 适配**大分区**（`gpt.bin`）：单槽 eMMC 分区 `0:HLOS` / `rootfs` / `rootfs_data` / `swap`；`sysupgrade` 按实际分区名写入（而非上游双槽 `*_1` 名）
    - `rootfs_data` 持久化 overlay：通过 `fstools_partname_fallback_scan=1` 启动参数（按 GPT 分区名匹配，分区表变动不影响）
  - **Redmi AX5 JDCloud / x86_64**：目前为空模板
- 构建流程：checkout → 清理磁盘 → 安装依赖 → 克隆源码 + 设备定制 → `feeds update -a` / `feeds install -a` → 配置 + `make defconfig` → `make download` → `make -j$(nproc) V=s` → 上传 artifact 并发布 Release。
