#!/bin/bash
#=================================================
# Description: JDCloud AX3000 device-specific script
# Lisence: MIT
#=================================================
#
# 此脚本在 OpenWrt 源码根目录下运行 (已 cd openwrt)
# 执行时机: clone 之后、feeds update 之前
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_DIR="${SCRIPT_DIR}/package"
TMP_DIR="${SCRIPT_DIR}/tmp/.custom-packages"

log_info()  { echo -e "\033[0;32m[INFO]\033[0m  $1"; }
log_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

# 检查是否在 OpenWrt 根目录
if [ ! -f "${SCRIPT_DIR}/feeds.conf.default" ]; then
    log_error "未找到 feeds.conf.default，请在 OpenWrt 根目录下运行此脚本"
    exit 1
fi

mkdir -p "${PACKAGE_DIR}" "${TMP_DIR}"

# === 1. msd_lite ===
add_msd_lite() {
    local target="${PACKAGE_DIR}/msd_lite"
    if [ -d "$target" ]; then
        log_info "msd_lite 已存在，跳过"
        return 0
    fi
    log_info "添加 msd_lite..."
    local repo="${TMP_DIR}/lean-packages"
    if [ ! -d "$repo" ]; then
        git clone --depth 1 --filter=blob:none --sparse \
            https://github.com/coolsnowwolf/packages.git "$repo" 2>&1 | tail -1
        (cd "$repo" && git sparse-checkout set net/msd_lite && git checkout 2>&1 | tail -1)
    fi
    cp -r "$repo/net/msd_lite" "$target"
    log_info "msd_lite -> package/msd_lite/"
}

# === 2. luci-app-msd_lite ===
add_luci_app_msd_lite() {
    local target="${PACKAGE_DIR}/luci-app-msd_lite"
    if [ -d "$target" ]; then
        log_info "luci-app-msd_lite 已存在，跳过"
        return 0
    fi
    log_info "添加 luci-app-msd_lite..."
    local repo="${TMP_DIR}/imm-luci"
    if [ ! -d "$repo" ]; then
        git clone --depth 1 --filter=blob:none --sparse \
            https://github.com/immortalwrt/luci.git "$repo" 2>&1 | tail -1
        (cd "$repo" && git sparse-checkout set applications/luci-app-msd_lite && git checkout 2>&1 | tail -1)
    fi
    cp -r "$repo/applications/luci-app-msd_lite" "$target"
    sed -i 's|include ../../luci.mk|include $(TOPDIR)/feeds/luci/luci.mk|' "$target/Makefile"
    log_info "luci-app-msd_lite -> package/luci-app-msd_lite/"
}

# === 3. luci-theme-argon ===
add_theme_argon() {
    local target="${PACKAGE_DIR}/luci-theme-argon"
    if [ -d "$target" ]; then
        log_info "luci-theme-argon 已存在，跳过"
        return 0
    fi
    log_info "添加 luci-theme-argon..."
    git clone --depth 1 -b master \
        https://github.com/jerrykuku/luci-theme-argon.git "$target" 2>&1 | tail -1
    rm -rf "$target/.git" "$target/.github" "$target/.gitignore"
    log_info "luci-theme-argon -> package/luci-theme-argon/"
}

# === 4. luci-app-argon-config ===
add_argon_config() {
    local target="${PACKAGE_DIR}/luci-app-argon-config"
    if [ -d "$target" ]; then
        log_info "luci-app-argon-config 已存在，跳过"
        return 0
    fi
    log_info "添加 luci-app-argon-config..."
    git clone --depth 1 -b master \
        https://github.com/jerrykuku/luci-app-argon-config.git "$target" 2>&1 | tail -1
    rm -rf "$target/.git" "$target/.github"
    log_info "luci-app-argon-config -> package/luci-app-argon-config/"
}

# === 主流程 ===
log_info "JDCloud AX3000 设备自定义脚本开始..."
add_msd_lite
add_luci_app_msd_lite
add_theme_argon
add_argon_config
log_info "JDCloud AX3000 自定义包添加完成"
