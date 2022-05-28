//package com.example.tracking_app_on_watch_flutter
//
//import android.os.Bundle
//
//import io.flutter.app.FlutterActivity
//import io.flutter.plugins.GeneratedPluginRegistrant
//
//import androidx.wear.ambient.AmbientMode
//
//import com.example.tracking_app_on_watch_flutter.FlutterAmbientCallback
//import com.example.tracking_app_on_watch_flutter.getChannel
//
//class MainActivity: FlutterActivity(), AmbientMode.AmbientCallbackProvider {
//    override fun onCreate(savedInstanceState: Bundle?) {
//        super.onCreate(savedInstanceState)
//        GeneratedPluginRegistrant.registerWith(this)
//
//        // Wire up the activity for ambient callbacks
//        AmbientMode.attachAmbientSupport(this)
//    }
//
//    override fun getAmbientCallback(): AmbientMode.AmbientCallback {
//        return FlutterAmbientCallback(getChannel(flutterView))
//    }
//}

package com.example.tracking_app_on_watch_flutter

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
}