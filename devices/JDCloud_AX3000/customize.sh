#!/bin/bash
#=================================================
# Description: JDCloud AX3000 device-specific script
# Lisence: MIT
#=================================================

# Apply device-specific patches
for patch in *.patch; do
    [ -f "$patch" ] && { echo "Applying $patch..."; patch -p1 < "$patch"; }
done
