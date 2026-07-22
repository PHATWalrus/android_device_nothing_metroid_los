#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: 2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)
from extract_utils.makefiles import (
    MakefilesCtx,
    ProductPackagesCtx,
)
from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import lib_fixups

namespace_imports = [
    'hardware/qcom-caf/sm8750',
    'hardware/qcom-caf/wlan/qcwcn',
    'hardware/qcom-caf/wlan',
    'vendor/qcom/opensource/commonsys/display',
    'vendor/qcom/opensource/commonsys-intf/display',
    'vendor/qcom/opensource/dataservices',
    'vendor/qcom/opensource/display',
    'device/nothing/metroid',
]

blob_fixups: blob_fixups_user_type = {
    (
        'vendor/lib64/libVoiceSdk.so',
        'vendor/lib64/libcapiv2uvvendor.so',
        'vendor/lib64/liblistensoundmodel2vendor.so',
    ): blob_fixup().replace_needed(
        'libtensorflowlite_c.so',
        'libtensorflowlite_c_vendor.so',
    ),
    'vendor/lib64/libmorpho_RapidEffect.so': blob_fixup()
        .clear_symbol_version('AHardwareBuffer_allocate')
        .clear_symbol_version('AHardwareBuffer_describe')
        .clear_symbol_version('AHardwareBuffer_lockPlanes')
        .clear_symbol_version('AHardwareBuffer_release')
        .clear_symbol_version('AHardwareBuffer_unlock'),
    'vendor/lib64/libntcamskia.so': blob_fixup()
        .add_needed('libnativewindow.so'),
    (
        'vendor/lib64/com.nothing.camera.postproc@1.0-service-impl.so',
        'vendor/lib64/camera/components/com.qti.node.dewarp.so',
        'vendor/lib64/hw/com.qti.chi.override.so',
        'vendor/lib64/libcamximageformatutils.so',
        'vendor/lib64/libchifeature2.so',
        'vendor/lib64/vendor.qti.hardware.camera.offlinecamera-service-impl.so',
    ): blob_fixup()
        .replace_needed(
            'android.hardware.graphics.allocator-V1-ndk.so',
            'android.hardware.graphics.allocator-V2-ndk.so',
        ),
    'vendor/etc/init/hw/init.target.rc': blob_fixup()
        .regex_replace(
            r'(?ms)^on property:vold\.decrypt=trigger_restart_framework\n'
            r'\s+start vendor\.cnss_diag\n\n'
            r'service vendor\.cnss_diag .*?^\s+oneshot\n\n?',
            '',
        ),
    'system_ext/etc/permissions/vendor.qti.hardware.c2pa-V1-java.xml': blob_fixup()
        .regex_replace(
            r'^<\?xml version="2\.0"',
            '<?xml version="1.0"',
        ),
    'system_ext/lib64/libwfdnative.so': blob_fixup()
        .add_needed('libinput_shim.so'),
    'system_ext/lib64/vendor.qti.hardware.qccsyshal@1.2-halimpl.so': blob_fixup()
        .replace_needed(
            'libprotobuf-cpp-full.so',
            'libprotobuf-cpp-full-21.7.so',
        ),
    'vendor/lib64/libqcodec2_core.so': blob_fixup()
        .replace_needed(
            'android.hardware.graphics.common-V5-ndk.so',
            'android.hardware.graphics.common-V7-ndk.so',
        ),
    'vendor/lib64/libwfdmmsrc_proprietary.so': blob_fixup()
        .replace_needed(
            'android.media.audio.common.types-V2-ndk.so',
            'android.media.audio.common.types-V3-ndk.so',
        ),
}


def write_recovery_touch_modules(
    ctx: MakefilesCtx,
    _packages_ctx: ProductPackagesCtx,
) -> None:
    ctx.bp_out.write(
        '''\
prebuilt_vendor {
    name: "qts_ko_recovery",
    src: "proprietary/vendor_dlkm/lib/modules/qts.ko",
    filename: "qts.ko",
    relative_install_path: "lib/modules",
    recovery: true,
}

prebuilt_vendor {
    name: "focaltech_tp_ko_recovery",
    src: "proprietary/vendor_dlkm/lib/modules/focaltech_tp.ko",
    filename: "focaltech_tp.ko",
    relative_install_path: "lib/modules",
    recovery: true,
}
'''
    )


module = ExtractUtilsModule(
    'metroid',
    'nothing',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
    skip_main_proprietary_file=True,
)

proprietary_file = module.add_proprietary_file('proprietary-files.txt')
proprietary_file.add_post_makefile_generation_fn(write_recovery_touch_modules)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
