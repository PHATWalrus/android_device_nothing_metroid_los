/*
 * Copyright (C) 2026 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 *
 * Nothing Phone (3) "metroid" Essential Key (gpio-keys scancode 250 / 0xfa):
 * toggle the torch. Runs inside system_server (PhoneWindowManager
 * dispatchKeyToKeyHandlers), so keep it lightweight and never throw.
 */

package org.lineageos.settings.device;

import android.content.Context;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraManager;
import android.os.Handler;
import android.os.HandlerThread;
import android.util.Log;
import android.view.KeyEvent;

import com.android.internal.os.DeviceKeyHandler;

public class KeyHandler implements DeviceKeyHandler {
    private static final String TAG = "MetroidKeyHandler";
    private static final int SCANCODE_ESSENTIAL_KEY = 250;

    private final CameraManager mCameraManager;
    private final Handler mHandler;

    private String mTorchCameraId = null;
    private boolean mTorchEnabled = false;

    public KeyHandler(Context context) {
        HandlerThread thread = new HandlerThread(TAG);
        thread.start();
        mHandler = new Handler(thread.getLooper());
        mCameraManager = context.getSystemService(CameraManager.class);
        if (mCameraManager != null) {
            // Track real torch state (covers QS-tile / other-client changes too).
            mCameraManager.registerTorchCallback(new CameraManager.TorchCallback() {
                @Override
                public void onTorchModeChanged(String cameraId, boolean enabled) {
                    if (cameraId.equals(getTorchCameraId())) {
                        mTorchEnabled = enabled;
                    }
                }
            }, mHandler);
        }
    }

    private synchronized String getTorchCameraId() {
        if (mTorchCameraId != null) return mTorchCameraId;
        try {
            for (String id : mCameraManager.getCameraIdList()) {
                CameraCharacteristics c = mCameraManager.getCameraCharacteristics(id);
                Boolean flash = c.get(CameraCharacteristics.FLASH_INFO_AVAILABLE);
                Integer facing = c.get(CameraCharacteristics.LENS_FACING);
                if (Boolean.TRUE.equals(flash)
                        && facing != null && facing == CameraCharacteristics.LENS_FACING_BACK) {
                    mTorchCameraId = id;
                    break;
                }
            }
        } catch (Exception e) {
            Log.w(TAG, "Could not resolve torch camera id", e);
        }
        return mTorchCameraId;
    }

    @Override
    public KeyEvent handleKeyEvent(KeyEvent event) {
        if (event.getScanCode() != SCANCODE_ESSENTIAL_KEY) {
            return event; // not ours — pass through
        }
        if (event.getAction() == KeyEvent.ACTION_UP) {
            mHandler.post(this::toggleTorch);
        }
        return null; // consume both down and up
    }

    private void toggleTorch() {
        if (mCameraManager == null) return;
        String id = getTorchCameraId();
        if (id == null) {
            Log.w(TAG, "No back camera with flash available (provider down?)");
            return;
        }
        try {
            mCameraManager.setTorchMode(id, !mTorchEnabled);
        } catch (Exception e) {
            Log.w(TAG, "setTorchMode failed", e);
        }
    }
}
