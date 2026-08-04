#!/bin/bash
#=================================================
# Description: JDCloud AX3000 device-specific script
# Lisence: MIT
#=================================================

# Apply device-specific patches (non-fatal, may not apply cleanly)
for patch in device-files/*.patch; do
    [ -f "$patch" ] && { echo "Applying $patch..."; patch -p1 < "$patch" || echo "Skipped (may already be applied)"; }
done
