#!/bin/bash
#=================================================
# Description: JDCloud AX3000 device-specific script
# Lisence: MIT
#=================================================

# Apply device-specific patches
for patch in device-files/*.patch; do
    [ -f "$patch" ] && { echo "Applying $patch..."; patch -p1 < "$patch"; }
done

# Fetch only msd_lite + luci-app-msd_lite from kenzok8/small-package
# Sparse checkout: avoids cloning the whole feed and any package conflicts
# (e.g. luci-app-zerotier init.d clash with the zerotier package).
git clone --depth 1 --filter=blob:none --sparse https://github.com/kenzok8/small-package /tmp/small-package
git -C /tmp/small-package sparse-checkout set msd_lite luci-app-msd_lite
cp -r /tmp/small-package/msd_lite /tmp/small-package/luci-app-msd_lite package/
rm -rf /tmp/small-package
