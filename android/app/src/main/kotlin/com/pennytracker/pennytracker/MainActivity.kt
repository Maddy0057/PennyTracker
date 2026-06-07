package com.pennytracker.pennytracker

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Telephony
import android.util.Log
import androidx.core.app.ActivityCompat
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "PennyTracker"
        private const val SMS_CHANNEL = "com.pennytracker.pennytracker/sms_inbox"
        private const val FOREGROUND_CHANNEL = "com.pennytracker.pennytracker/foreground_service"
        private const val ACTION_CHANNEL = "com.pennytracker.pennytracker/foreground_actions"

        const val ACTION_ADD_TRANSACTION = "add_transaction"
        const val ACTION_OPEN_APP = "open_app"
        const val ACTION_OVERVIEW = "overview"
        const val ACTION_QUICK_ADD = "quick_add"
        const val KEY_QUICK_AMOUNT = "quick_amount"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "[MainActivity] configureFlutterEngine — caching engine")

        // Cache the engine so the foreground service & QuickAddActivity
        // can use it for MethodChannel communication
        FlutterEngineCache.getInstance().put("foreground_service_engine", flutterEngine)

        // ─── SMS Inbox Reader Channel ───
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSmsInbox" -> {
                    val limit = call.argument<Int>("limit") ?: 50
                    Log.d(TAG, "[MainActivity] getSmsInbox called, limit=$limit")
                    if (hasSmsPermission()) {
                        result.success(fetchSmsInbox(limit))
                    } else {
                        result.error("PERMISSION_DENIED", "READ_SMS permission not granted", null)
                    }
                }
                else -> {
                    Log.w(TAG, "[MainActivity] Unknown SMS channel method: ${call.method}")
                    result.notImplemented()
                }
            }
        }

        // ─── Foreground Service Control Channel ───
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOREGROUND_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    Log.d(TAG, "[MainActivity] startService requested")
                    PennyTrackerForegroundService.start(this)
                    result.success(true)
                }
                "stopService" -> {
                    Log.d(TAG, "[MainActivity] stopService requested")
                    PennyTrackerForegroundService.stop(this)
                    result.success(true)
                }
                "isServiceRunning" -> {
                    result.success(true)
                }
                else -> {
                    Log.w(TAG, "[MainActivity] Unknown foreground channel method: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }

    private fun hasSmsPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        Log.d(TAG, "[MainActivity] onNewIntent action=${intent.action}")
        handleNotificationAction(intent)
    }

    override fun onStart() {
        super.onStart()
        Log.d(TAG, "[MainActivity] onStart action=${intent?.action}")
        handleNotificationAction(intent)
    }

    override fun onResume() {
        super.onResume()
        // Check for any pending quick-add transactions from disk
        checkPendingQuickAdds()
    }

    private fun handleNotificationAction(intent: Intent?) {
        val action = intent?.action ?: run {
            Log.d(TAG, "[MainActivity] handleNotificationAction: no action on intent")
            return
        }
        Log.d(TAG, "[MainActivity] handleNotificationAction: action=$action")

        val flutterEngine = FlutterEngineCache.getInstance()
            .get("foreground_service_engine") ?: run {
                Log.e(TAG, "[MainActivity] No cached Flutter engine — cannot forward action")
                return
            }

        if (action == ACTION_QUICK_ADD) {
            val amount = intent.getStringExtra(KEY_QUICK_AMOUNT)
            Log.d(TAG, "[MainActivity] Handling QUICK_ADD action, amount=$amount")
            if (amount != null) {
                Handler(Looper.getMainLooper()).postDelayed({
                    try {
                        MethodChannel(
                            flutterEngine.dartExecutor.binaryMessenger,
                            ACTION_CHANNEL
                        ).invokeMethod("onQuickAdd", amount)
                        Log.d(TAG, "[MainActivity] QUICK_ADD forwarded to Flutter")
                    } catch (e: Exception) {
                        Log.e(TAG, "[MainActivity] QUICK_ADD MethodChannel failed: ${e.message}")
                    }
                }, 500)
            }
            return
        }

        val actionToSend = when (action) {
            ACTION_ADD_TRANSACTION -> ACTION_ADD_TRANSACTION
            ACTION_OPEN_APP -> ACTION_OPEN_APP
            ACTION_OVERVIEW -> ACTION_OVERVIEW
            else -> {
                Log.w(TAG, "[MainActivity] Unknown notification action: $action")
                return
            }
        }

        Handler(Looper.getMainLooper()).postDelayed({
            try {
                MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    ACTION_CHANNEL
                ).invokeMethod("onForegroundAction", actionToSend)
                Log.d(TAG, "[MainActivity] Action '$actionToSend' forwarded to Flutter")
            } catch (e: Exception) {
                Log.e(TAG, "[MainActivity] MethodChannel failed for $actionToSend: ${e.message}")
            }
        }, 500)
    }

    /** Read pending Quick Add JSON files and forward them to Flutter */
    private fun checkPendingQuickAdds() {
        try {
            Log.d(TAG, "[MainActivity] Checking for pending Quick Add files")
            val pendingDir = File(filesDir, "pending_quick_add")
            if (!pendingDir.exists()) {
                Log.d(TAG, "[MainActivity] No pending directory")
                return
            }

            val files = pendingDir.listFiles { f -> f.name.endsWith(".json") }
            if (files.isNullOrEmpty()) {
                Log.d(TAG, "[MainActivity] No pending Quick Add files")
                return
            }

            Log.d(TAG, "[MainActivity] Found ${files.size} pending Quick Add files")

            val flutterEngine = FlutterEngineCache.getInstance()
                .get("foreground_service_engine") ?: return

            for (file in files) {
                try {
                    val json = file.readText()
                    Log.d(TAG, "[MainActivity] Processing pending: ${file.name}")
                    MethodChannel(
                        flutterEngine.dartExecutor.binaryMessenger,
                        ACTION_CHANNEL
                    ).invokeMethod("onPendingQuickAddData", json)
                    file.delete()
                    Log.d(TAG, "[MainActivity] Processed and deleted: ${file.name}")
                } catch (e: Exception) {
                    Log.e(TAG, "[MainActivity] Failed to process ${file.name}: ${e.message}")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "[MainActivity] checkPendingQuickAdds failed: ${e.message}")
        }
    }

    private fun fetchSmsInbox(limit: Int): List<Map<String, String>> {
        Log.d(TAG, "[MainActivity] fetchSmsInbox: limit=$limit")
        val smsList = mutableListOf<Map<String, String>>()
        val cursor = contentResolver.query(
            Uri.parse("content://sms/inbox"),
            arrayOf(
                Telephony.Sms._ID,
                Telephony.Sms.DATE,
                Telephony.Sms.BODY,
                Telephony.Sms.ADDRESS
            ),
            null,
            null,
            "${Telephony.Sms.DATE} DESC LIMIT $limit"
        )

        cursor?.use {
            val idIdx = it.getColumnIndexOrThrow(Telephony.Sms._ID)
            val dateIdx = it.getColumnIndexOrThrow(Telephony.Sms.DATE)
            val bodyIdx = it.getColumnIndexOrThrow(Telephony.Sms.BODY)
            val addressIdx = it.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)

            while (it.moveToNext()) {
                smsList.add(
                    mapOf(
                        "id" to (it.getString(idIdx) ?: ""),
                        "date" to (it.getString(dateIdx) ?: "0"),
                        "body" to (it.getString(bodyIdx) ?: ""),
                        "address" to (it.getString(addressIdx) ?: "Unknown")
                    )
                )
            }
        }
        Log.d(TAG, "[MainActivity] fetchSmsInbox: found ${smsList.size} messages")
        return smsList
    }
}
