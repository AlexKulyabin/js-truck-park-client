package com.mycompany.jstrackpark

import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        clearRestoredInstallStateOnce()
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_IDENTITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method != "getAndroidId") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val androidId = Settings.Secure.getString(
                    contentResolver,
                    Settings.Secure.ANDROID_ID,
                )
                if (androidId.isNullOrBlank()) {
                    result.error("ANDROID_ID_UNAVAILABLE", "Android ID is unavailable", null)
                } else {
                    result.success(androidId)
                }
            }
    }

    private fun clearRestoredInstallStateOnce() {
        runCatching {
            val marker = File(noBackupFilesDir, INSTALL_STATE_MARKER)
            if (marker.exists()) {
                return
            }

            getSharedPreferences(CHOTTU_PREFERENCES, MODE_PRIVATE)
                .edit()
                .clear()
                .commit()

            if (isFreshInstall()) {
                getSharedPreferences(FLUTTER_PREFERENCES, MODE_PRIVATE)
                    .edit()
                    .clear()
                    .commit()
            }

            marker.createNewFile()
        }
    }

    private fun isFreshInstall(): Boolean {
        val packageInfo = packageManager.getPackageInfo(packageName, 0)
        return packageInfo.firstInstallTime == packageInfo.lastUpdateTime
    }

    private companion object {
        const val INSTALL_STATE_MARKER = "referral_install_state_v3"
        const val CHOTTU_PREFERENCES = "chottu_prefs"
        const val FLUTTER_PREFERENCES = "FlutterSharedPreferences"
        const val DEVICE_IDENTITY_CHANNEL = "js_truck_park/device_identity"
    }
}
