#!/usr/bin/env bash
cd /home/logix/dev/metroid/lineage
source build/envsetup.sh >/dev/null 2>&1
export TARGET_PRODUCT=lineage_metroid
export TARGET_RELEASE=bp2a
export TARGET_BUILD_VARIANT=userdebug
export LINEAGE_BUILD=metroid
export WITH_ADB_INSECURE=true
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR=/home/logix/.ccache
exec build/soong/soong_ui.bash --make-mode -j$(nproc) "$@"

