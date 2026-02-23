package com.example.do_an

import android.content.*
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.do_an/location_stream"
    private var locationReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    locationReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            val lat = intent?.getDoubleExtra("lat", 0.0) ?: 0.0
                            val lng = intent?.getDoubleExtra("lng", 0.0) ?: 0.0
                            events?.success(mapOf("lat" to lat, "lng" to lng))
                        }
                    }
                    val filter = IntentFilter("LOCATION_UPDATE")
                    // Đăng ký nhận tọa độ từ LocationService.kt
                    registerReceiver(locationReceiver, filter, RECEIVER_EXPORTED)

                    // Khởi chạy Service khi bắt đầu lắng nghe
                    val serviceIntent = Intent(this@MainActivity, LocationService::class.java)
                    startForegroundService(serviceIntent)
                }

                override fun onCancel(arguments: Any?) {
                    unregisterReceiver(locationReceiver)
                    locationReceiver = null
                }
            }
        )
    }
}
