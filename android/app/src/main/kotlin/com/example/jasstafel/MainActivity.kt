package ch.simonste.jasstafel

import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.location.LocationManagerCompat
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge for Android 10+
        // WindowCompat.setDecorFitsSystemWindows replaces the deprecated APIs
        // setStatusBarColor/setNavigationBarColor which are deprecated in Android 15
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "jasstafel/platform")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // During a sync session, Back on the board moves the app
                    // to the background like Android 12+ does, rather than
                    // finishing it. A finished activity would leave the
                    // session's Bluetooth link open without the app to serve
                    // it.
                    "moveTaskToBack" -> {
                        moveTaskToBack(true)
                        result.success(null)
                    }
                    // Up to Android 11 a Bluetooth scan finds nothing while the
                    // location is turned off, the sync dialog asks to turn it on.
                    "scanNeedsLocation" -> {
                        val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
                        result.success(
                            Build.VERSION.SDK_INT < Build.VERSION_CODES.S &&
                                !LocationManagerCompat.isLocationEnabled(manager)
                        )
                    }
                    "openLocationSettings" -> {
                        startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
                        result.success(null)
                    }
                    // The name a shared board goes by in the join list.
                    "deviceName" -> result.success(deviceName())
                    else -> result.notImplemented()
                }
            }
    }

    // The Bluetooth name, which needs BLUETOOTH_CONNECT from Android 12,
    // else the device name of the settings.
    private fun deviceName(): String? {
        try {
            val manager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            val name = manager.adapter?.name
            if (!name.isNullOrBlank()) return name
        } catch (_: SecurityException) {}
        return Settings.Global.getString(contentResolver, Settings.Global.DEVICE_NAME)
    }
}
