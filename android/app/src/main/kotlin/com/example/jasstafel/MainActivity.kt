package ch.simonste.jasstafel

import android.os.Build
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

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
}
