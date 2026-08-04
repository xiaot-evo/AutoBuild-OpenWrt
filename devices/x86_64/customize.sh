#!/bin/bash
#=================================================
# Description: x86_64 device-specific script
# Lisence: MIT
#=================================================

# Modify default IP
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate
