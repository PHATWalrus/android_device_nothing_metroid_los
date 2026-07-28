/*
 * Copyright (C) 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#define LOG_TAG "MetroidBluetoothAudio"

#include <android/binder_manager.h>
#include <android/binder_status.h>
#include <log/log.h>

#include <memory>
#include <mutex>
#include <utility>

#include "core-impl/Configuration.h"
#include "core-impl/Module.h"

using aidl::android::hardware::audio::core::Module;
using aidl::android::hardware::audio::core::internal::getConfiguration;

namespace {

constexpr char kServiceName[] = "android.hardware.audio.core.IModule/bluetooth";

std::mutex gModuleMutex;
std::shared_ptr<Module> gModule;

}  // namespace

extern "C" __attribute__((visibility("default"))) binder_status_t
registerIModuleBluetoothSWQti() {
    std::lock_guard<std::mutex> lock(gModuleMutex);
    if (gModule != nullptr) {
        return STATUS_OK;
    }

    auto module = Module::createInstance(
            Module::Type::BLUETOOTH,
            getConfiguration(Module::Type::BLUETOOTH));
    if (module == nullptr) {
        ALOGE("Failed to create %s", kServiceName);
        return STATUS_NO_MEMORY;
    }

    const binder_status_t status =
            AServiceManager_addService(module->asBinder().get(), kServiceName);
    if (status != STATUS_OK) {
        ALOGE("Failed to register %s: %d", kServiceName, status);
        return status;
    }

    gModule = std::move(module);
    ALOGI("Registered %s", kServiceName);
    return STATUS_OK;
}
