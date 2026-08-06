# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 仓库概述

基于 eSirPlayground/AutoBuild-OpenWrt 的 OpenWrt 固件自动构建项目。通过 GitHub Actions 为多个设备编译固件并发布到 GitHub Releases。本仓库不含可本地编译的 OpenWrt 源码，一切构建都在 CI 中完成。

## 设备与源码矩阵

| 设备 | 工作流 | 源码 | 分支 | 架构 |
|---|---|---|---|---|
| JDCloud AX3000 | `Build_JDCloud_AX3000.yml` | immortalwrt/immortalwrt | openwrt-25.12 | qualcommax/ipq50xx |
| Redmi AX5 JDCloud | `Build_Redmi_AX5_JDCloud.yml` | LiBwrt/LibWrt | 25.12-nss | qualcommax/ipq60xx |
| x86_64 | `Build_OP_x86_64.yml` | coolsnowwolf/lede | master | x86/64 |

## 构建流程（三个 Build workflow 步骤完全一致）

1. **Checkout** — 检出本仓库（`actions/checkout@master`）
2. **Free disk space** — `jlumbroso/free-disk-space@main` 清理磁盘
3. **Install build dependencies** — apt 安装完整 OpenWrt 编译依赖
4. **Clone source code** — `git clone --depth 1 $REPO_URL -b $REPO_BRANCH openwrt`；将 `devices/$DEVICE_NAME/` 整体复制为 `openwrt/device-files/`，随后 `cd openwrt && ./device-files/customize.sh`（设备定制，在 feeds 之前运行）
5. **Update & Install feeds** — `./scripts/feeds update -a` + `./scripts/feeds install -a`
6. **Configuration Customization** — 校验 `$CONFIG_FILE` 存在（缺失 `exit 1`）→ `mv $CONFIG_FILE openwrt/.config` → 运行仓库根目录的全局 `./customize.sh`（sed 将默认 IP 改为 192.168.10.1）→ `make defconfig`
7. **Download package** — `make download -j$(nproc)`
8. **Build firmware** — `make -j$(nproc) V=s`
9. **Upload artifact** — `actions/upload-artifact@master`，上传整个 `openwrt/bin`
10. **Upload to Release** — `softprops/action-gh-release@v3`，固定 tag（`RELEASE_TAG`）每次覆盖，文件为 `openwrt/bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET/*`

### 两个 customize.sh 的分工

- `devices/<name>/customize.sh` — 设备专属，复制到 `openwrt/device-files/` 后在 openwrt/ 内执行（feeds 之前）。JDCloud AX3000 用它以 `git apply`（失败回退 `patch -p1`）循环应用 `device-files/*.patch`；Redmi / x86_64 目前是空模板
- 根目录 `customize.sh` — 全局隐式定制，配置阶段（feeds 之后）执行，把 `openwrt/package/base-files/files/config_generate` 中的默认 IP 从 192.168.1.1 改为 192.168.10.1，所有设备构建都会生效

## 文件结构

```
customize.sh                  # 全局定制（改默认 IP 为 192.168.10.1），三个 workflow 都会运行
patches/                      # 遗留空目录，未使用
devices/<name>/
├── <name>.config             # OpenWrt .config，从本地构建目录复制
├── customize.sh              # 设备专属脚本，在 feeds 之前于 openwrt/ 内运行
└── *.patch                   # 可选设备补丁，由 customize.sh 用 git apply 应用
.github/workflows/
├── Build_JDCloud_AX3000.yml
├── Build_Redmi_AX5_JDCloud.yml
├── Build_OP_x86_64.yml
└── Sync Code.yml             # 从上游 eSirPlayground 同步代码（push/schedule 触发器默认注释掉）
```

## Commands

本仓库没有本地构建/测试命令（无 manifest、无 Makefile，且 CI 镜像才装有编译工具链）。事实规范就是三个 Build workflow 里的固定步骤序列；本地只做 YAML / shell 脚本的静态检查（如 `bash -n` 语法校验）。

## 新增设备

1. 创建 `devices/<name>/`，放入该设备本地能正常编译的 `.config` 和 `customize.sh`
2. 复制现有 workflow 创建 `Build_<name>.yml`，修改 `env` 中的 `DEVICE_NAME`、`REPO_URL`、`REPO_BRANCH`、`CONFIG_FILE`、`TARGET_BOARD`、`TARGET_SUBTARGET`、`RELEASE_TAG`

## Workflow 关键参数

- `permissions: contents: write` — 用于 Release 上传
- 定时构建：`schedule: cron: '0 0 * * 1'`（每周一 UTC 00:00）
- `CONFIG_FILE` env 指向 config 路径，配置阶段先 `[ -e $CONFIG_FILE ]` 校验，缺失即报错退出

## `.config` 管理

- config 来自本地能成功编译运行的构建目录（`../lede/.config`、`../immortalwrt/.config`、`../libwrt/.config`），分别对应 x86_64 / JDCloud AX3000 / Redmi AX5 的源码
- 切换设备源码时必须同步替换对应的 config（Redmi 的 config 头部有 "LibWrt Configuration" 标识）
- x86_64 的 config 是最小配置（约 100 行，靠 `make defconfig` 展开）；其余为完整生成的配置（数千行）
- 修改 config 后保持 `make defconfig` 能通过，并在 `make download` / 编译阶段无报错

## Notes

<!-- 后续快速补充点： -->
