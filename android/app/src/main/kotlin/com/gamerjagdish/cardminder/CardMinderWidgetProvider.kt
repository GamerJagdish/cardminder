package com.gamerjagdish.cardminder

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray

class CardMinderWidgetProvider : AppWidgetProvider() {

    data class RowBindings(
        val rowId: Int,
        val imageId: Int,
        val nameId: Int,
        val subtitleId: Int,
        val daysId: Int,
        val statusId: Int
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.card_minder_widget)
                val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

                // 1. Resolve Theme Mode
                val themePref = prefs.getString("theme_mode", "system") ?: "system"
                val isSystemDark = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
                val isDark = when (themePref) {
                    "dark" -> true
                    "light" -> false
                    else -> isSystemDark
                }

                // 2. Explicit theme overrides when user forced light or dark in settings
                if (themePref == "dark") {
                    views.setInt(R.id.widget_container, "setBackgroundColor", Color.parseColor("#1E293B"))
                    views.setTextColor(R.id.widget_title, Color.parseColor("#F8FAFC"))
                    views.setTextColor(R.id.widget_tracker_tag, Color.parseColor("#94A3B8"))
                    views.setTextColor(R.id.widget_cards_count_label, Color.parseColor("#F8FAFC"))
                    views.setInt(R.id.widget_divider, "setBackgroundColor", Color.parseColor("#334155"))
                } else if (themePref == "light") {
                    views.setInt(R.id.widget_container, "setBackgroundColor", Color.parseColor("#FFFFFF"))
                    views.setTextColor(R.id.widget_title, Color.parseColor("#0F172A"))
                    views.setTextColor(R.id.widget_tracker_tag, Color.parseColor("#334155"))
                    views.setTextColor(R.id.widget_cards_count_label, Color.parseColor("#0F172A"))
                    views.setInt(R.id.widget_divider, "setBackgroundColor", Color.parseColor("#E2E8F0"))
                }

                // 3. Card Count Header
                val totalCards = prefs.getInt("total_cards", 0)
                views.setTextViewText(
                    R.id.widget_cards_count_label,
                    if (totalCards == 1) "1 CARD" else "$totalCards CARDS"
                )

                val rows = arrayOf(
                    RowBindings(R.id.widget_row_1, R.id.widget_card_image_1, R.id.widget_name_1, R.id.widget_subtitle_1, R.id.widget_days_1, R.id.widget_status_1),
                    RowBindings(R.id.widget_row_2, R.id.widget_card_image_2, R.id.widget_name_2, R.id.widget_subtitle_2, R.id.widget_days_2, R.id.widget_status_2),
                    RowBindings(R.id.widget_row_3, R.id.widget_card_image_3, R.id.widget_name_3, R.id.widget_subtitle_3, R.id.widget_days_3, R.id.widget_status_3),
                    RowBindings(R.id.widget_row_4, R.id.widget_card_image_4, R.id.widget_name_4, R.id.widget_subtitle_4, R.id.widget_days_4, R.id.widget_status_4),
                    RowBindings(R.id.widget_row_5, R.id.widget_card_image_5, R.id.widget_name_5, R.id.widget_subtitle_5, R.id.widget_days_5, R.id.widget_status_5)
                )

                val jsonString = prefs.getString("widget_cards_json", null)
                if (!jsonString.isNullOrEmpty()) {
                    val jsonArray = JSONArray(jsonString)
                    if (jsonArray.length() == 0) {
                        views.setViewVisibility(R.id.widget_cards_list_container, View.GONE)
                        views.setViewVisibility(R.id.widget_empty_container, View.VISIBLE)
                    } else {
                        views.setViewVisibility(R.id.widget_cards_list_container, View.VISIBLE)
                        views.setViewVisibility(R.id.widget_empty_container, View.GONE)

                        for (i in 0 until 5) {
                            val row = rows[i]
                            if (i < jsonArray.length()) {
                                try {
                                    val item = jsonArray.getJSONObject(i)
                                    views.setViewVisibility(row.rowId, View.VISIBLE)

                                    val name = item.optString("name", "Card")
                                    val digits = item.optString("digits", "0000")
                                    val colorHex = item.optString("color", "#273B66")
                                    val network = item.optString("network", "Card")
                                    val bank = item.optString("bank", "")
                                    val days = item.optInt("days", 0)
                                    val status = item.optString("status", "SAFE")

                                    views.setTextViewText(row.nameId, name)

                                    val subText = if (bank.isNotEmpty()) "$bank • $network" else "$network • •••• $digits"
                                    views.setTextViewText(row.subtitleId, subText)

                                    // Explicit colors only if user forced a specific theme
                                    if (themePref == "dark") {
                                        views.setInt(row.rowId, "setBackgroundColor", Color.parseColor("#0F172A"))
                                        views.setTextColor(row.nameId, Color.parseColor("#F8FAFC"))
                                        views.setTextColor(row.subtitleId, Color.parseColor("#94A3B8"))
                                    } else if (themePref == "light") {
                                        views.setInt(row.rowId, "setBackgroundColor", Color.parseColor("#F8FAFC"))
                                        views.setTextColor(row.nameId, Color.parseColor("#0F172A"))
                                        views.setTextColor(row.subtitleId, Color.parseColor("#334155"))
                                    }

                                    // Render mini credit card bitmap
                                    val cardBmp = createMiniCardBitmap(context, digits, colorHex, network)
                                    views.setImageViewBitmap(row.imageId, cardBmp)

                                    // Days Remaining Text
                                    views.setTextViewText(row.daysId, "${days}d")

                                    // Urgency Status Pill (High-contrast text colors)
                                    val (pillRes, pillTextColor, statusLabel) = getUrgencyStyle(status, days, isDark)
                                    views.setTextViewText(row.statusId, statusLabel)
                                    views.setInt(row.statusId, "setBackgroundResource", pillRes)
                                    views.setTextColor(row.statusId, pillTextColor)
                                    views.setTextColor(row.daysId, pillTextColor)
                                } catch (rowEx: Exception) {
                                    rowEx.printStackTrace()
                                }
                            } else {
                                views.setViewVisibility(row.rowId, View.GONE)
                            }
                        }
                    }
                } else {
                    views.setViewVisibility(R.id.widget_cards_list_container, View.GONE)
                    views.setViewVisibility(R.id.widget_empty_container, View.VISIBLE)
                }

                // Tap widget to launch CardMinder MainActivity
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
                views.setOnClickPendingIntent(R.id.widget_empty_container, pendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun getUrgencyStyle(status: String, days: Int, isDark: Boolean): Triple<Int, Int, String> {
        return when {
            status.equals("EXPIRED", ignoreCase = true) || days <= 0 -> {
                val color = if (isDark) Color.parseColor("#94A3B8") else Color.parseColor("#334155")
                Triple(R.drawable.widget_badge_expired, color, "EXPIRED")
            }
            status.equals("CRITICAL", ignoreCase = true) || status.equals("URGENT", ignoreCase = true) || days <= 30 -> {
                val color = if (isDark) Color.parseColor("#FCA5A5") else Color.parseColor("#B91C1C")
                Triple(R.drawable.widget_badge_critical, color, "URGENT")
            }
            status.equals("WARNING", ignoreCase = true) || days <= 90 -> {
                val color = if (isDark) Color.parseColor("#FDE047") else Color.parseColor("#B45309")
                Triple(R.drawable.widget_badge_warning, color, "WARNING")
            }
            else -> {
                val color = if (isDark) Color.parseColor("#34D399") else Color.parseColor("#047857")
                Triple(R.drawable.widget_badge_safe, color, "SAFE")
            }
        }
    }

    private fun createMiniCardBitmap(
        context: Context,
        digits: String,
        colorHex: String?,
        network: String?
    ): Bitmap {
        val density = context.resources.displayMetrics.density
        val width = (42 * density).toInt().coerceAtLeast(84)
        val height = (26 * density).toInt().coerceAtLeast(52)

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val cardColor = try {
            if (!colorHex.isNullOrEmpty()) Color.parseColor(colorHex) else Color.parseColor("#273B66")
        } catch (e: Exception) {
            Color.parseColor("#273B66")
        }

        // Compute darker gradient color for card depth
        val hsv = FloatArray(3)
        Color.colorToHSV(cardColor, hsv)
        hsv[2] = (hsv[2] * 0.72f).coerceIn(0f, 1f)
        val darkerColor = Color.HSVToColor(hsv)

        val cardPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(
                0f, 0f, width.toFloat(), height.toFloat(),
                cardColor, darkerColor, Shader.TileMode.CLAMP
            )
        }

        val cornerRadius = 5 * density
        val cardRect = RectF(0f, 0f, width.toFloat(), height.toFloat())
        canvas.drawRoundRect(cardRect, cornerRadius, cornerRadius, cardPaint)

        // Compute luminance to ensure text on card has high contrast
        val luminance = (0.299 * Color.red(cardColor) + 0.587 * Color.green(cardColor) + 0.114 * Color.blue(cardColor)) / 255.0
        val cardTextColor = if (luminance > 0.65) Color.parseColor("#0F172A") else Color.WHITE

        // Ambient sheen circle in top-right
        val sheenPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = if (luminance > 0.65) Color.BLACK else Color.WHITE
            alpha = 20
        }
        canvas.drawCircle(width * 0.88f, height * 0.12f, width * 0.42f, sheenPaint)

        // Mini gold EMV chip in top-left
        val chipPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#EAB308")
        }
        val chipRect = RectF(
            width * 0.10f,
            height * 0.20f,
            width * 0.28f,
            height * 0.50f
        )
        canvas.drawRoundRect(chipRect, 1.5f * density, 1.5f * density, chipPaint)

        // Digits text (last 4)
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = cardTextColor
            textSize = 8.5f * density
            isFakeBoldText = true
        }
        val safeDigits = if (digits.length >= 4) digits.takeLast(4) else digits.padStart(4, '0')
        canvas.drawText(safeDigits, width * 0.10f, height * 0.84f, textPaint)

        // Network badge on top-right (e.g. VISA, MC, AMEX, RUPAY, DISC)
        val netStr = when ((network ?: "").lowercase()) {
            "visa" -> "VISA"
            "mastercard" -> "MC"
            "amex" -> "AMEX"
            "rupay" -> "RUPAY"
            "discover" -> "DISC"
            else -> network?.take(4)?.uppercase() ?: ""
        }
        if (netStr.isNotEmpty()) {
            val netPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                color = cardTextColor
                alpha = 220
                textSize = 6f * density
                isFakeBoldText = true
                textAlign = Paint.Align.RIGHT
            }
            canvas.drawText(netStr, width * 0.90f, height * 0.42f, netPaint)
        }

        return bitmap
    }
}
