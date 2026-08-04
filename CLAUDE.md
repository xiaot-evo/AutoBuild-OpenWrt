# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 仓库概述

基于 eSirPlayground/AutoBuild-OpenWrt 的 OpenWrt 固件自动构建项目。通过 GitHub Actions 为多个设备编译固件并发布到 GitHub Releases。

## 设备与源码矩阵

| 设备 | 工作流 | 源码 | 分支 | 架构 |
|---|---|---|---|---|
| JDCloud AX3000 | `Build_JDCloud_AX3000.yml` | coolsnowwolf/lede | master | qualcommax/ipq50xx |
| Redmi AX5 JDCloud | `Build_Redmi_AX5_JDCloud.yml` | LiBwrt/LibWrt | 25.12-nss | qualcommax/ipq60xx |
| x86_64 | `Build_OP_x86_64.yml` | coolsnowwolf/lede | master | x86/64 |

## 构建流程

每个工作流按固定顺序执行：

1. **Clone 源码** → 克隆对应 OpenWrt 源码
2. **运行设备定制脚本** (`devices/<name>/customize.sh`) — 在 OpenWrt 目录内执行，负责改 IP、添加自定义包、patch、feed 等所有设备定制操作
3. **更新 & 安装 feeds**
4. **配置** → 复制设备 config 为 `.config` → `make defconfig`
5. **下载包** → `make download`
6. **编译** → `yes "" | make -j$(nproc) V=s`（`yes ""` 防止内核 syncconfig 在 CI 无终端环境中进入交互模式）
7. **上传 artifact** + **发布到 Release**（固定 tag，每次覆盖更新）
8. Workflow 不做任何隐式定制操作（不添加 feed、不运行全局脚本），一切设备定制通过 `devices/<name>/customize.sh` 显式完成

## 文件结构

```
devices/<name>/
├── <name>.config          # OpenWrt .config，从本地构建目录复制
└── customize.sh           # 设备专属脚本，在 feeds 之前于 openwrt/ 内运行
.github/workflows/
├── Build_JDCloud_AX3000.yml
├── Build_Redmi_AX5_JDCloud.yml
├── Build_OP_x86_64.yml
└── Sync Code.yml          # 从上游 eSirPlayground 同步代码
```

## 新增设备

1. 创建 `devices/<name>/`，放入该设备本地能正常编译的 `.config` 和 `customize.sh`
2. 复制现有 workflow 创建 `Build_<name>.yml`，修改 `env` 中的 `DEVICE_NAME`、`REPO_URL`、`REPO_BRANCH`、`CONFIG_FILE`、`TARGET_BOARD`、`TARGET_SUBTARGET`、`RELEASE_TAG`

## Workflow 关键参数

- `permissions: contents: write` — 用于 Release 上传
- 定时构建：`schedule: cron: '0 0 * * 1'`（每周一 UTC 00:00）
- Release 使用 `softprops/action-gh-release@v1`，固定 tag 每次覆盖

## `.config` 管理

- config 来自本地能成功编译运行的构建目录（`../lede/.config`、`../lienol/.config`、`../libwrt/.config`）
- 切换设备源码时必须同步替换对应的 config
- config 路径在 workflow 的 `CONFIG_FILE` env 中指定，缺失会导致构建报错退出
