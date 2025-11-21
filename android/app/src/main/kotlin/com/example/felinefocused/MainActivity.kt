package com.example.felinefocused

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app_exit_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "forceCloseApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val success = forceCloseApp(packageName)
                        result.success(success)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                "goToHomeScreen" -> {
                    goToHomeScreen()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun forceCloseApp(packageName: String): Boolean {
        return try {
            val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            
            // Method 1: Kill background processes (works for most apps)
            activityManager.killBackgroundProcesses(packageName)
            
            // Method 2: For Android 8.0+ (API 26+), also try to remove tasks
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val tasks = activityManager.appTasks
                for (task in tasks) {
                    val taskInfo = task.taskInfo
                    if (taskInfo.baseIntent?.component?.packageName == packageName) {
                        task.finishAndRemoveTask()
                    }
                }
            }
            
            true
        } catch (e: Exception) {
            android.util.Log.e("AppExitService", "Error closing app: ${e.message}")
            false
        }
    }

    private fun goToHomeScreen() {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
    }
}