package com.sikkaplay.app

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.adscalex.sdk.AdScaleX

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.sikkaplay.app/device_info"
    private val ADSCALEX_CHANNEL = "sikkaplay/adscalex"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAndroidId") {
                val androidId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                result.success(androidId)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ADSCALEX_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openOfferwall") {
                val userId = call.argument<String>("userId")
                val appKey = call.argument<String>("appKey")
                
                if (userId.isNullOrEmpty() || appKey.isNullOrEmpty()) {
                    result.error("INVALID_ARGS", "User ID or App Key cannot be null or empty", null)
                    return@setMethodCallHandler
                }
                
                try {
                    AdScaleX.init(
                        context = applicationContext,
                        appKey = appKey,
                        userId = userId
                    )
                    AdScaleX.showOfferwall(this)
                    result.success(mapOf("success" to true))
                } catch (e: Exception) {
                    result.error("ADSCALEX_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
