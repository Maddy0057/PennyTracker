package com.pennytracker.pennytracker

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class PennyTrackerForegroundService : Service() {

    companion object {
        const val TAG = "PennyTracker"
        const val CHANNEL_ID = "pennytracker_foreground_service"
        const val NOTIFICATION_ID = 1
        const val ACTION_CHANNEL = "com.pennytracker.pennytracker/foreground_actions"
        const val ACTION_ADD_TRANSACTION = "add_transaction"
        const val ACTION_OPEN_APP = "open_app"
        const val ACTION_OVERVIEW = "overview"
        const val ACTION_QUICK_ADD = "quick_add"
        const val KEY_QUICK_AMOUNT = "quick_amount"

        /**
         * Re-build and re-show the foreground notification.
         * Useful after a Quick Add so the notification reflects latest state.
         */
        fun updateNotification(context: Context) {
            Log.d(TAG, "[ForegroundService] Updating notification after Quick Add")
            val intent = Intent(context, PennyTrackerForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun start(context: Context) {
            Log.d(TAG, "[ForegroundService] Starting service")
            val intent = Intent(context, PennyTrackerForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            Log.d(TAG, "[ForegroundService] Stopping service")
            val intent = Intent(context, PennyTrackerForegroundService::class.java)
            context.stopService(intent)
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "[ForegroundService] onCreate")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        Log.d(TAG, "[ForegroundService] onStartCommand action=$action flags=$flags startId=$startId")

        // Handle action intents from notification buttons
        if (action != null) {
            when (action) {
                ACTION_ADD_TRANSACTION -> {
                    Log.d(TAG, "[ForegroundService] Handling ADD_TRANSACTION action")
                    notifyFlutter(ACTION_ADD_TRANSACTION)
                }
                ACTION_OPEN_APP -> {
                    Log.d(TAG, "[ForegroundService] Handling OPEN_APP action")
                    notifyFlutter(ACTION_OPEN_APP)
                }
                ACTION_OVERVIEW -> {
                    Log.d(TAG, "[ForegroundService] Handling OVERVIEW action")
                    notifyFlutter(ACTION_OVERVIEW)
                }
                ACTION_QUICK_ADD -> {
                    Log.d(TAG, "[ForegroundService] Handling QUICK_ADD action")
                    val remoteInput = androidx.core.app.RemoteInput.getResultsFromIntent(intent)
                    val amountStr = remoteInput?.getCharSequence(KEY_QUICK_AMOUNT)?.toString()
                    
                    if (!amountStr.isNullOrBlank()) {
                        processQuickAddAmount(amountStr)
                    }
                    // Re-build notification to clear the loading spinner of RemoteInput
                    val notification = buildNotification()
                    startForeground(NOTIFICATION_ID, notification)
                    return START_STICKY
                }
                else -> {
                    Log.d(TAG, "[ForegroundService] Unknown action: $action")
                }
            }
        }

        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)
        Log.d(TAG, "[ForegroundService] Notification displayed (id=$NOTIFICATION_ID)")
        return START_STICKY
    }

    private fun buildNotification(): Notification {
        // ── Open App (requestCode=0) ──
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            action = ACTION_OPEN_APP
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // ── Add Transaction button (requestCode=1) ──
        val addTransactionIntent = Intent(this, MainActivity::class.java).apply {
            action = ACTION_ADD_TRANSACTION
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val addTransactionPendingIntent = PendingIntent.getActivity(
            this, 1, addTransactionIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // ── Overview button (requestCode=2) ──
        val overviewIntent = Intent(this, MainActivity::class.java).apply {
            action = ACTION_OVERVIEW
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val overviewPendingIntent = PendingIntent.getActivity(
            this, 2, overviewIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // ── Quick Add ₹ button (requestCode=3) ──
        // Direct Reply (RemoteInput) in the notification bar
        val remoteInput = androidx.core.app.RemoteInput.Builder(KEY_QUICK_AMOUNT)
            .setLabel("Amount (e.g. 250)")
            .build()
            
        val quickAddIntent = Intent(this, PennyTrackerForegroundService::class.java).apply {
            action = ACTION_QUICK_ADD
        }
        
        val quickAddFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }

        val quickAddPendingIntent = PendingIntent.getService(
            this, 3, quickAddIntent, quickAddFlags
        )
        
        val quickAddAction = NotificationCompat.Action.Builder(
            R.drawable.ic_action_add,
            "Quick Add ₹",
            quickAddPendingIntent
        ).addRemoteInput(remoteInput).build()

        Log.d(TAG, "[ForegroundService] Building notification with actions: open(0), add(1), overview(2), quickAdd(3)")

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("PennyTracker Active")
            .setContentText("Tap + to add · Quick Add ₹ to save instantly")
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setShowWhen(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setColor(0xFF6C3AED.toInt()) // Primary purple color
            .addAction(
                R.drawable.ic_action_add,
                "＋ Add",
                addTransactionPendingIntent
            )
            .addAction(quickAddAction)
            .setContentIntent(openAppPendingIntent)
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("Tracking expenses · Tap to open\nTap Quick Add ₹ to save an expense instantly"))
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Log.d(TAG, "[ForegroundService] Creating notification channel")
            val channel = NotificationChannel(
                CHANNEL_ID,
                "PennyTracker Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Persistent notification for expense tracking"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun notifyFlutter(action: String) {
        Log.d(TAG, "[ForegroundService] notifyFlutter: action=$action")
        try {
            val engine = FlutterEngineCache.getInstance().get("foreground_service_engine")
            if (engine != null) {
                if (engine.dartExecutor.isExecutingDart) {
                    Log.d(TAG, "[ForegroundService] Flutter engine active — invoking MethodChannel")
                    MethodChannel(
                        engine.dartExecutor.binaryMessenger,
                        ACTION_CHANNEL
                    ).invokeMethod("onForegroundAction", action)
                    Log.d(TAG, "[ForegroundService] MethodChannel invoke succeeded")
                } else {
                    Log.w(TAG, "[ForegroundService] Flutter engine found but Dart not executing")
                    // Fall through: launch activity directly since engine can't process
                    launchMainActivity(action)
                }
            } else {
                Log.w(TAG, "[ForegroundService] No Flutter engine cached — launching activity directly")
                launchMainActivity(action)
            }
        } catch (e: Exception) {
            Log.e(TAG, "[ForegroundService] notifyFlutter failed: ${e.message}")
            launchMainActivity(action)
        }
    }

    private fun launchMainActivity(action: String) {
        Log.d(TAG, "[ForegroundService] launchMainActivity: action=$action")
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                this.action = action
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            startActivity(intent)
            Log.d(TAG, "[ForegroundService] startActivity succeeded")
        } catch (e: Exception) {
            Log.e(TAG, "[ForegroundService] startActivity failed: ${e.message}")
        }
    }

    private fun processQuickAddAmount(amountText: String) {
        val cleaned = amountText
            .replace("₹", "")
            .replace(",", "")
            .replace(" ", "")
            .trim()
            
        val amount = cleaned.toDoubleOrNull()
        if (amount == null || amount <= 0) {
            android.widget.Toast.makeText(this, "Invalid amount", android.widget.Toast.LENGTH_SHORT).show()
            return
        }

        try {
            val engine = FlutterEngineCache.getInstance().get("foreground_service_engine")
            if (engine != null && engine.dartExecutor.isExecutingDart) {
                Log.d(TAG, "[ForegroundService] Flutter engine active — sending Quick Add")
                MethodChannel(
                    engine.dartExecutor.binaryMessenger,
                    ACTION_CHANNEL
                ).invokeMethod("onQuickAdd", amount.toString())
                android.widget.Toast.makeText(this, "✅ ₹${formatAmount(amount)} added", android.widget.Toast.LENGTH_SHORT).show()
            } else {
                Log.w(TAG, "[ForegroundService] Flutter engine unavailable — saving pending")
                if (savePendingTransaction(amount)) {
                    android.widget.Toast.makeText(this, "✅ ₹${formatAmount(amount)} added (will sync)", android.widget.Toast.LENGTH_SHORT).show()
                } else {
                    android.widget.Toast.makeText(this, "Failed to save.", android.widget.Toast.LENGTH_SHORT).show()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "[ForegroundService] processQuickAddAmount failed: ${e.message}")
        }
    }

    private fun savePendingTransaction(amount: Double): Boolean {
        return try {
            val pendingDir = java.io.File(filesDir, "pending_quick_add")
            pendingDir.mkdirs()
            val id = "qa_${System.currentTimeMillis()}_${(1000..9999).random()}"
            val now = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.US).format(java.util.Date())

            val json = org.json.JSONObject().apply {
                put("id", id)
                put("date", now)
                put("amount", amount)
                put("type", "DEBIT")
                put("category", "Miscellaneous")
                put("merchant", "Quick Add")
                put("paymentMethod", "UPI")
                put("source", "Manual")
                put("referenceId", "")
                put("note", org.json.JSONObject.NULL)
                put("createdAt", now)
            }.toString()

            val file = java.io.File(pendingDir, "${id}.json")
            file.writeText(json)
            Log.d(TAG, "[ForegroundService] Pending transaction saved: ${file.absolutePath}")
            true
        } catch (e: Exception) {
            Log.e(TAG, "[ForegroundService] Failed to save pending: ${e.message}")
            false
        }
    }

    private fun formatAmount(amount: Double): String {
        return if (amount == amount.toLong().toDouble()) {
            amount.toLong().toString()
        } else {
            String.format("%.2f", amount)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
