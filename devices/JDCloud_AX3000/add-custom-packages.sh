#!/bin/bash
#
# add-custom-packages.sh — 为 Lienol OpenWrt 25.12 添加自定义包
#
# 包含:
#   - msd_lite          IPTV 多播转单播工具 (来源: coolsnowwolf/packages)
#   - luci-app-msd_lite  msd_lite 的 LuCI Web 管理界面 (来源: ImmortalWrt)
#   - luci-theme-argon   第三方 Argon 主题 (来源: jerrykuku, v2.x for 25.12)
#   - luci-app-argon-config  Argon 主题配置插件 (来源: jerrykuku)
#
# 用法:
#   chmod +x add-custom-packages.sh
#   ./add-custom-packages.sh
#
# 可选参数:
#   --force    强制重新下载覆盖已有包
#   --clean    清理临时文件 (默认保留)
#   --help     显示帮助
#

set -e

# 配置
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_DIR="${SCRIPT_DIR}/package"
TMP_DIR="${SCRIPT_DIR}/tmp/.custom-packages"
FORCE=false
CLEAN_TMP=false

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# === 辅助函数 ===

log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "\n${BLUE}==== $1 ====${NC}\n"; }

usage() {
    cat << EOF
用法: $0 [选项]

为 Lienol OpenWrt 25.12 添加自定义包 (msd_lite + Argon 主题)

选项:
  --force     强制重新下载，覆盖已有包
  --clean     完成后清理临时文件
  --help      显示此帮助信息

添加的包:
  msd_lite              - IPTV 多播转单播核心程序
  luci-app-msd_lite     - msd_lite 的 LuCI 管理界面
  luci-theme-argon      - 第三方 Argon 主题
  luci-app-argon-config - Argon 主题配置插件
EOF
    exit 0
}

# 解析参数
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
        --clean) CLEAN_TMP=true ;;
        --help)  usage ;;
        *)       log_error "未知参数: $arg"; usage ;;
    esac
done

# 检查是否在 OpenWrt 根目录
if [ ! -f "${SCRIPT_DIR}/feeds.conf.default" ]; then
    log_error "未找到 feeds.conf.default，请在 OpenWrt 根目录下运行此脚本"
    exit 1
fi

# 创建必要目录
mkdir -p "${PACKAGE_DIR}" "${TMP_DIR}"

# === 1. msd_lite 核心包 ===
add_msd_lite() {
    local target="${PACKAGE_DIR}/msd_lite"

    if [ -d "$target" ] && [ "$FORCE" != true ]; then
        log_info "msd_lite 已存在，跳过 (使用 --force 强制覆盖)"
        return 0
    fi

    log_step "1/4 添加 msd_lite 核心包"

    rm -rf "$target"

    # 从 coolsnowwolf/packages 浅克隆，仅检出 net/msd_lite 目录
    local repo="${TMP_DIR}/lean-packages"
    if [ ! -d "$repo" ]; then
        log_info "克隆 coolsnowwolf/packages (浅克隆)..."
        git clone --depth 1 --filter=blob:none --sparse \
            https://github.com/coolsnowwolf/packages.git "$repo" 2>&1 | tail -1
        (
            cd "$repo"
            git sparse-checkout set net/msd_lite
            git checkout 2>&1 | tail -1
        )
    fi

    if [ ! -f "$repo/net/msd_lite/Makefile" ]; then
        log_error "无法获取 msd_lite Makefile"
        return 1
    fi

    cp -r "$repo/net/msd_lite" "$target"
    log_info "msd_lite -> package/msd_lite/"
}

# === 2. luci-app-msd_lite ===
add_luci_app_msd_lite() {
    local target="${PACKAGE_DIR}/luci-app-msd_lite"

    if [ -d "$target" ] && [ "$FORCE" != true ]; then
        log_info "luci-app-msd_lite 已存在，跳过 (使用 --force 强制覆盖)"
        return 0
    fi

    log_step "2/4 添加 luci-app-msd_lite 界面包"

    rm -rf "$target"

    # 从 ImmortalWrt luci 浅克隆，仅检出 applications/luci-app-msd_lite
    local repo="${TMP_DIR}/imm-luci"
    if [ ! -d "$repo" ]; then
        log_info "克隆 immortalwrt/luci (浅克隆)..."
        git clone --depth 1 --filter=blob:none --sparse \
            https://github.com/immortalwrt/luci.git "$repo" 2>&1 | tail -1
        (
            cd "$repo"
            git sparse-checkout set applications/luci-app-msd_lite
            git checkout 2>&1 | tail -1
        )
    fi

    if [ ! -f "$repo/applications/luci-app-msd_lite/Makefile" ]; then
        log_error "无法获取 luci-app-msd_lite Makefile"
        return 1
    fi

    cp -r "$repo/applications/luci-app-msd_lite" "$target"

    # 修正 include 路径: ImmortalWrt 的相对路径 -> 适配 package/ 目录
    sed -i 's|include ../../luci.mk|include $(TOPDIR)/feeds/luci/luci.mk|' \
        "$target/Makefile"

    log_info "luci-app-msd_lite -> package/luci-app-msd_lite/ (include 路径已修正)"
}

# === 3. luci-theme-argon ===
add_theme_argon() {
    local target="${PACKAGE_DIR}/luci-theme-argon"

    if [ -d "$target" ] && [ "$FORCE" != true ]; then
        log_info "luci-theme-argon 已存在，跳过 (使用 --force 强制覆盖)"
        return 0
    fi

    log_step "3/4 添加 luci-theme-argon 主题"

    rm -rf "$target"

    log_info "克隆 jerrykuku/luci-theme-argon (master 分支, v2.x for 25.12)..."
    git clone --depth 1 -b master \
        https://github.com/jerrykuku/luci-theme-argon.git "$target" 2>&1 | tail -1

    # 清理 .git 和 .github 目录
    rm -rf "$target/.git" "$target/.github" "$target/.gitignore"

    log_info "luci-theme-argon -> package/luci-theme-argon/"
}

# === 4. luci-app-argon-config ===
add_argon_config() {
    local target="${PACKAGE_DIR}/luci-app-argon-config"

    if [ -d "$target" ] && [ "$FORCE" != true ]; then
        log_info "luci-app-argon-config 已存在，跳过 (使用 --force 强制覆盖)"
        return 0
    fi

    log_step "4/4 添加 luci-app-argon-config 配置插件"

    rm -rf "$target"

    log_info "克隆 jerrykuku/luci-app-argon-config..."
    git clone --depth 1 -b master \
        https://github.com/jerrykuku/luci-app-argon-config.git "$target" 2>&1 | tail -1

    # 清理 .git 和 .github 目录
    rm -rf "$target/.git" "$target/.github"

    log_info "luci-app-argon-config -> package/luci-app-argon-config/"
}

# === 验证 ===
verify_packages() {
    log_step "验证包结构"

    local errors=0

    check_pkg() {
        local name="$1"
        local path="${PACKAGE_DIR}/${name}"
        if [ -f "${path}/Makefile" ]; then
            log_info "✓ ${name}"
        else
            log_error "✗ ${name} — Makefile 缺失"
            errors=$((errors + 1))
        fi
    }

    check_pkg "msd_lite"
    check_pkg "luci-app-msd_lite"
    check_pkg "luci-theme-argon"
    check_pkg "luci-app-argon-config"

    if [ "$errors" -gt 0 ]; then
        log_error "有 ${errors} 个包验证失败"
        return 1
    fi

    log_info "所有 4 个包验证通过"
}

# === 清理 ===
cleanup() {
    if [ "$CLEAN_TMP" = true ]; then
        log_info "清理临时文件..."
        rm -rf "${TMP_DIR}"
    else
        log_info "临时文件保留在 ${TMP_DIR} (使用 --clean 自动清理)"
    fi
}

# === 主流程 ===
main() {
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║  OpenWrt 25.12 自定义包添加脚本              ║"
    echo "║  msd_lite + Argon 主题                       ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""

    add_msd_lite
    add_luci_app_msd_lite
    add_theme_argon
    add_argon_config
    verify_packages
    cleanup

    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║  ✅ 全部完成!                                ║"
    echo "║                                              ║"
    echo "║  后续步骤:                                   ║"
    echo "║  ./scripts/feeds update -a                   ║"
    echo "║  make menuconfig                             ║"
    echo "║    Network  -> msd_lite                      ║"
    echo "║    LuCI -> Applications -> luci-app-msd_lite ║"
    echo "║    LuCI -> Themes -> luci-theme-argon        ║"
    echo "║    LuCI -> Applications -> luci-app-argon-config ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""
}

main
