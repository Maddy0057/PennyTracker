package com.pennytracker.pennytracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class SmsReceiver : BroadcastReceiver() {

    companion object {
        const val SMS_RECEIVED_CHANNEL = "com.pennytracker.pennytracker/sms_received"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isEmpty()) return

        // Combine multi-part SMS into a single body
        val fullBody = messages.joinToString("") { it.messageBody ?: "" }
        val sender = messages.firstOrNull()?.originatingAddress ?: "Unknown"
        val timestamp = messages.firstOrNull()?.timestampMillis ?: System.currentTimeMillis()

        // Send to Flutter via the cached engine
        val engine = FlutterEngineCache.getInstance().get("foreground_service_engine")
        if (engine != null) {
            try {
                MethodChannel(
                    engine.dartExecutor.binaryMessenger,
                    SMS_RECEIVED_CHANNEL
                ).invokeMethod(
                    "onSmsReceived",
                    mapOf(
                        "body" to fullBody,
                        "address" to sender,
                        "date" to timestamp.toString()
                    )
                )
            } catch (_: Exception) {
                // Engine may not be active
            }
        }
    }
}
