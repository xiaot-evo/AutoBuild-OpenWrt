#!/bin/bash
#=================================================
# Description: Redmi AX5 JDCloud device-specific script
# Lisence: MIT
#=================================================

# Custom feed: nikki (LuCI proxy app). Must be appended before `feeds update -a`,
# because libwrt's own feeds.conf.default does not carry it.
FEED_LINE="src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main"
grep -qF "$FEED_LINE" feeds.conf.default || echo "$FEED_LINE" >> feeds.conf.default

# Custom theme package, cloned straight into package/ (not a feed).
# Local build was validated with v1.4.0; the clone tracks the default branch head.
[ -d package/luci-theme-aurora ] || git clone --depth 1 https://github.com/eamonxg/luci-theme-aurora.git package/luci-theme-aurora
