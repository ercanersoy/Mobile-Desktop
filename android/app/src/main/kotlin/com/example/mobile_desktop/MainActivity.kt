package net.ercanersoy.mobile_desktop

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.os.SystemClock
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "net.ercanersoy.mobile_desktop/system"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getDeviceInfo" -> result.success(deviceInfo())
                        "getMemoryInfo" -> result.success(memoryInfo())
                        "getStorageInfo" -> result.success(storageInfo())
                        "getBatteryInfo" -> result.success(batteryInfo())
                        "getUptime" -> result.success(
                            mapOf("uptime" to SystemClock.elapsedRealtime())
                        )
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("SYSTEM_INFO_ERROR", e.message, null)
                }
            }
    }

    private fun deviceInfo(): Map<String, Any?> {
        val info = mutableMapOf<String, Any?>(
            "manufacturer" to Build.MANUFACTURER,
            "brand" to Build.BRAND,
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
            "product" to Build.PRODUCT,
            "board" to Build.BOARD,
            "hardware" to Build.HARDWARE,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkInt" to Build.VERSION.SDK_INT,
            "buildId" to Build.DISPLAY,
            "abis" to Build.SUPPORTED_ABIS.joinToString(", "),
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            info["securityPatch"] = Build.VERSION.SECURITY_PATCH
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            info["socManufacturer"] = Build.SOC_MANUFACTURER
            info["socModel"] = Build.SOC_MODEL
        }
        return info
    }

    private fun memoryInfo(): Map<String, Any?> {
        val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memory = ActivityManager.MemoryInfo()
        manager.getMemoryInfo(memory)
        return mapOf(
            "total" to memory.totalMem,
            "available" to memory.availMem,
            "lowMemory" to memory.lowMemory,
        )
    }

    private fun storageInfo(): Map<String, Any?> {
        val internal = StatFs(Environment.getDataDirectory().path)
        val result = mutableMapOf<String, Any?>(
            "total" to internal.totalBytes,
            "free" to internal.availableBytes,
        )
        try {
            val external = StatFs(Environment.getExternalStorageDirectory().path)
            result["externalTotal"] = external.totalBytes
            result["externalFree"] = external.availableBytes
        } catch (e: Exception) {
            // Shared storage is not mounted.
        }
        return result
    }

    private fun batteryInfo(): Map<String, Any?> {
        val intent: Intent = registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        ) ?: return emptyMap()
        val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, 100)
        val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val plugged = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0)
        val temperature = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0)
        val voltage = intent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0)
        val health = intent.getIntExtra(BatteryManager.EXTRA_HEALTH, 0)
        val technology = intent.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY)
        val percent = if (level >= 0 && scale > 0) level * 100 / scale else -1
        return mapOf(
            "level" to percent,
            "charging" to (status == BatteryManager.BATTERY_STATUS_CHARGING ||
                status == BatteryManager.BATTERY_STATUS_FULL),
            "full" to (status == BatteryManager.BATTERY_STATUS_FULL),
            "plugged" to (plugged != 0),
            "temperature" to temperature / 10.0,
            "voltage" to voltage,
            "healthGood" to (health == BatteryManager.BATTERY_HEALTH_GOOD),
            "technology" to technology,
        )
    }
}
