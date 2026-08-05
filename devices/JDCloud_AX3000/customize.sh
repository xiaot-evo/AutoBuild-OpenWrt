#!/bin/bash
#=================================================
# Description: JDCloud AX3000 device-specific script
# Lisence: MIT
#=================================================

# Apply device-specific patches
for patch in device-files/*.patch; do
    [ -f "$patch" ] && { echo "Applying $patch..."; patch -p1 < "$patch"; }
done

# Add kenzok8/small-package feed (must run before `./scripts/feeds update -a`)
# Same entry as in local ../Lienol/feeds.conf.default
if ! grep -q "kenzok8/small-package" feeds.conf.default; then
    echo "src-git smpackage https://github.com/kenzok8/small-package" >> feeds.conf.default
fi
