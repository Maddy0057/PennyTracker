package com.pennytracker.pennytracker

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.os.Bundle
import android.text.InputType
import android.util.Log
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.Toast
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import java.io.File
import org.json.JSONObject

/**
 * Transparent activity launched from the "Quick Add ₹" notification action.
 *
 * Shows a native Android AlertDialog for amount input, sends the amount
 * to the Flutter Dart side via MethodChannel for database saving, and
 * dismisses itself. No Flutter UI rendering needed.
 */
class QuickAddActivity : Activity() {

    companion object {
        private const val TAG = "PennyTracker"
        const val ACTION_CHANNEL = "com.pennytracker.pennytracker/foreground_actions"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "[QuickAddActivity] onCreate")

        val prefillAmount = intent?.getStringExtra(MainActivity.KEY_QUICK_AMOUNT)
        showAmountInputDialog(prefillAmount)
    }

    private fun showAmountInputDialog(prefillAmount: String?) {
        Log.d(TAG, "[QuickAddActivity] Showing dialog, prefill='$prefillAmount'")

        val input = EditText(this).apply {
            hint = "₹ Amount (e.g. 250)"
            inputType = InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_FLAG_DECIMAL
            setText(prefillAmount ?: "")
            setSelection(length())
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                marginStart = 48
                marginEnd = 48
                topMargin = 16
                bottomMargin = 8
            }
            setHintTextColor(resources.getColor(android.R.color.darker_gray, theme))
        }

        val dialog = AlertDialog.Builder(this)
            .setTitle("Quick Add Expense")
            .setMessage("Enter the amount spent:")
            .setView(input)
            .setCancelable(true)
            .setPositiveButton("Save") { _, _ ->
                val amountText = input.text.toString().trim()
                Log.d(TAG, "[QuickAddActivity] User entered: '$amountText'")
                processAmount(amountText)
            }
            .setNegativeButton("Cancel") { _, _ ->
                Log.d(TAG, "[QuickAddActivity] User cancelled")
                finish()
            }
            .setOnCancelListener {
                Log.d(TAG, "[QuickAddActivity] Dialog cancelled")
                finish()
            }
            .create()

        dialog.show()
        dialog.getButton(AlertDialog.BUTTON_POSITIVE)?.setTextColor(
            getColor(R.color.quick_add_accent)
        )
    }

    private fun processAmount(amountText: String) {
        if (amountText.isEmpty()) {
            Log.d(TAG, "[QuickAddActivity] Empty amount")
            Toast.makeText(this, "Please enter an amount", Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        val cleaned = amountText
            .replace("₹", "")
            .replace(",", "")
            .replace(" ", "")
            .trim()

        val amount = cleaned.toDoubleOrNull()
        if (amount == null || amount <= 0) {
            Log.e(TAG, "[QuickAddActivity] Invalid amount: '$amountText' -> '$cleaned'")
            Toast.makeText(this, "Invalid amount. Enter a valid number.", Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        Log.d(TAG, "[QuickAddActivity] Parsed amount: ₹$amount")

        // Step 1: Try MethodChannel to Flutter (engine should be in same process)
        val engine = FlutterEngineCache.getInstance().get("foreground_service_engine")
        if (engine != null && engine.dartExecutor.isExecutingDart) {
            Log.d(TAG, "[QuickAddActivity] Engine available — invoking MethodChannel")
            try {
                MethodChannel(
                    engine.dartExecutor.binaryMessenger,
                    ACTION_CHANNEL
                ).invokeMethod("onQuickAdd", amount.toString())
                Log.d(TAG, "[QuickAddActivity] Quick Add sent to Flutter successfully")
                Toast.makeText(this, "✅ ₹${formatAmount(amount)} added", Toast.LENGTH_SHORT).show()
                finish()
                return
            } catch (e: Exception) {
                Log.e(TAG, "[QuickAddActivity] MethodChannel failed: ${e.message}")
            }
        } else {
            Log.w(TAG, "[QuickAddActivity] Engine not available (engine=${engine != null}, executing=${engine?.dartExecutor?.isExecutingDart})")
        }

        // Step 2: Fallback — save to pending file for Flutter to pick up later
        Log.d(TAG, "[QuickAddActivity] Saving pending transaction to disk")
        val saved = savePendingTransaction(amount)
        if (saved) {
            Toast.makeText(this, "✅ ₹${formatAmount(amount)} added (will sync)", Toast.LENGTH_SHORT).show()
            // Notify Flutter if engine becomes available
            if (engine != null) {
                try {
                    MethodChannel(
                        engine.dartExecutor.binaryMessenger,
                        ACTION_CHANNEL
                    ).invokeMethod("onPendingQuickAdd", null)
                } catch (_: Exception) {}
            }
        } else {
            Toast.makeText(this, "Failed to save. Open the app and try again.", Toast.LENGTH_SHORT).show()
        }

        finish()
    }

    /** Write a pending quick-add transaction as a JSON file */
    private fun savePendingTransaction(amount: Double): Boolean {
        return try {
            val pendingDir = File(filesDir, "pending_quick_add")
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
                put("note", JSONObject.NULL)
                put("createdAt", now)
            }.toString()

            val file = File(pendingDir, "${id}.json")
            file.writeText(json)
            Log.d(TAG, "[QuickAddActivity] Pending transaction saved: ${file.absolutePath}")
            true
        } catch (e: Exception) {
            Log.e(TAG, "[QuickAddActivity] Failed to save pending: ${e.message}")
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
}
