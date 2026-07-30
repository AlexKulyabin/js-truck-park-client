package com.mycompany.jstrackpark

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import java.io.File

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        clearRestoredInstallStateOnce()
        super.onCreate(savedInstanceState)
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
    }
}
