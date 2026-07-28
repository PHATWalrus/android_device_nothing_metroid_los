#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: 2026 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)
from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import lib_fixups

METROID_VIBRATOR_MODULES = {
    'libqtivibratoreffect': 'metroid_prebuilt_libqtivibratoreffect',
    'libqtivibratoreffectoffload': 'metroid_prebuilt_libqtivibratoreffectoffload',
    'vendor.qti.hardware.vibrator.impl': 'metroid_prebuilt_vendor_qti_hardware_vibrator_impl',
    'vendor.qti.hardware.vibratorCL.impl': 'metroid_prebuilt_vendor_qti_hardware_vibratorCL_impl',
    'vendor.qti.hardware.vibratorOL.impl': 'metroid_prebuilt_vendor_qti_hardware_vibratorOL_impl',
    'vendor.qti.hardware.vibratorSel.impl': 'metroid_prebuilt_vendor_qti_hardware_vibratorSel_impl',
}


def fixup_metroid_vibrator_dependency(lib: str, partition: str) -> str:
    if partition != 'vendor':
        return lib

    return METROID_VIBRATOR_MODULES.get(lib, lib)


lib_fixups = {
    **lib_fixups,
    **{
        lib: fixup_metroid_vibrator_dependency
        for lib in METROID_VIBRATOR_MODULES
    },
}

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
        'vendor/bin/hw/vendor.qti.hardware.display.composer-service',
        'vendor/bin/poweropt-service',
        'vendor/lib64/camera/components/com.arcsoft.node.motiondetect.so',
        'vendor/lib64/hw/camera.qcom.so',
        'vendor/lib64/libaodoptfeature.so',
        'vendor/lib64/libapengine.so',
        'vendor/lib64/libcamerapoweroptfeature.so',
        'vendor/lib64/libcamxcoreutils.so',
        'vendor/lib64/libcamxods.so',
        'vendor/lib64/libgamepoweroptfeature.so',
        'vendor/lib64/liblearningmodule.so',
        'vendor/lib64/liboffscreenpoweroptfeature.so',
        'vendor/lib64/libpowercallback.so',
        'vendor/lib64/libpowercore.so',
        'vendor/lib64/libpsmoptfeature.so',
        'vendor/lib64/libsdmclient.so',
        'vendor/lib64/libstandbyfeature.so',
        'vendor/lib64/libvideooptfeature.so',
        'vendor/lib64/libaudioeffecthal.qti.so',
        'vendor/lib64/soundfx/libquasar.so',
    ): blob_fixup().replace_needed(
        'libtinyxml2.so',
        'libtinyxml2-v35.so',
    ),
    'vendor/bin/hw/android.hardware.wifi-service.metroid': blob_fixup()
        .replace_needed(
            'libwifi-hal.so',
            'libwifi-hal-metroid.so',
        ),
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
    'vendor/lib64/libaudioserviceexampleimpl.so': blob_fixup()
        .add_needed('libaudioutils_shim.so')
        .replace_needed(
            'libalsautilsv2.so',
            'libalsautilsv2-metroid.so',
        )
        .replace_needed(
            'libtinyalsav2.so',
            'libtinyalsav2-metroid.so',
        )
        .replace_needed(
            'android.hardware.bluetooth.audio-impl.so',
            'android.hardware.bluetooth.audio-impl-metroid.so',
        )
        .replace_needed(
            'libbluetooth_audio_session_aidl.so',
            'libbluetooth_audio_session_aidl-metroid.so',
        ),
    'vendor/lib64/android.hardware.bluetooth.audio-impl-metroid.so': blob_fixup()
        .replace_needed(
            'libbluetooth_audio_session_aidl.so',
            'libbluetooth_audio_session_aidl-metroid.so',
        ),
    'vendor/lib64/libalsautilsv2-metroid.so': blob_fixup()
        .replace_needed(
            'libtinyalsav2.so',
            'libtinyalsav2-metroid.so',
        ),
    'vendor/lib64/soundfx/libhapticgenerator.so': blob_fixup()
        .replace_needed(
            'libvibratorutils.so',
            'libvibratorutils-metroid.so',
        ),
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
    'vendor/etc/init/init.nt_cit.rc': blob_fixup()
        .regex_replace(
            r'(?ms)^#spencer\.chen copy from byd/configs-sys/'
            r'init\.factoryflag\.rc\n\n'
            r'#add for cit PSN FSN color\n'
            r'on post-fs-data\n.*?(?=^on property:sys\.boot_completed=1\n)',
            '',
        ),
    'vendor/etc/init/power.stats.rc': blob_fixup()
        .regex_replace(
            r'(?m)^(    group system)$',
            r'\1\n    interface aidl '
            r'android.hardware.power.stats.IPowerStats/default',
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

module = ExtractUtilsModule(
    'metroid',
    'nothing',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
