#!/bin/bash
#=================================================
# Description: JDCloud AX3000 device-specific script
# Lisence: MIT
#=================================================

# Apply device-specific patches
for patch in device-files/*.patch; do
    [ -f "$patch" ] && { echo "Applying $patch..."; git apply "$patch" 2>/dev/null || patch -p1 < "$patch"; }
done
