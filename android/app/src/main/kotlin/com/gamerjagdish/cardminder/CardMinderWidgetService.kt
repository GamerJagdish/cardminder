package com.gamerjagdish.cardminder

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject

class CardMinderWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return CardMinderRemoteViewsFactory(applicationContext)
    }
}

class CardMinderRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private val cardsList = mutableListOf<JSONObject>()

    override fun onCreate() {
        loadData()
    }

    override fun onDataSetChanged() {
        loadData()
    }

    private fun loadData() {
        cardsList.clear()
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

        val jsonString = prefs.getString("widget_cards_json", null)
        if (!jsonString.isNullOrEmpty()) {
            try {
                val jsonArray = JSONArray(jsonString)
                val items = mutableListOf<JSONObject>()
                for (i in 0 until jsonArray.length()) {
                    items.add(jsonArray.getJSONObject(i))
                }
                // Sort by urgency (fewest days remaining first), then tie-break by name
                items.sortWith(compareBy({ it.optInt("days", 0) }, { it.optString("name", "").lowercase() }))
                cardsList.addAll(items)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    override fun onDestroy() {
        cardsList.clear()
    }

    override fun getCount(): Int = cardsList.size

    override fun getViewAt(position: Int): RemoteViews {
        if (position < 0 || position >= cardsList.size) {
            return RemoteViews(context.packageName, R.layout.card_minder_widget_item)
        }

        val views = RemoteViews(context.packageName, R.layout.card_minder_widget_item)
        try {
            val item = cardsList[position]
            val id = item.optString("id", "")
            val name = item.optString("name", "Card")
            val digits = item.optString("digits", "0000")
            val colorHex = item.optString("color", "#273B66")
            val network = item.optString("network", "Card")
            val bank = item.optString("bank", "")
            val days = item.optInt("days", 0)
            val status = item.optString("status", "SAFE")

            views.setTextViewText(R.id.widget_name, name)
            val subText = if (bank.isNotEmpty()) "$bank • $network" else "$network • •••• $digits"
            views.setTextViewText(R.id.widget_subtitle, subText)

            // Render mini credit card bitmap
            val cardBmp = createMiniCardBitmap(context, digits, colorHex, network)
            views.setImageViewBitmap(R.id.widget_card_image, cardBmp)

            // Days Remaining Text
            views.setTextViewText(R.id.widget_days, "${days}d")

            // Urgency Status Pill (High-contrast text colors following device theme)
            val (pillRes, pillTextColorRes, statusLabel) = getUrgencyStyle(status, days)
            views.setTextViewText(R.id.widget_status, statusLabel)
            views.setInt(R.id.widget_status, "setBackgroundResource", pillRes)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                views.setColor(R.id.widget_status, "setTextColor", pillTextColorRes)
                views.setColor(R.id.widget_days, "setTextColor", pillTextColorRes)
            } else {
                val color = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    context.getColor(pillTextColorRes)
                } else {
                    @Suppress("DEPRECATION")
                    context.resources.getColor(pillTextColorRes)
                }
                views.setTextColor(R.id.widget_status, color)
                views.setTextColor(R.id.widget_days, color)
            }

            // Fill-in Intent to trigger the widget's PendingIntentTemplate with card deep-link
            val fillInIntent = Intent().apply {
                action = "es.antonborri.home_widget.action.LAUNCH"
                val uri = if (id.isNotEmpty()) {
                    Uri.parse("cardminder://card?id=$id")
                } else {
                    Uri.parse("cardminder://card?name=${Uri.encode(name)}&digits=$digits")
                }
                data = uri
                putExtra("card_id", id)
                putExtra("card_name", name)
                putExtra("card_digits", digits)
            }
            views.setOnClickFillInIntent(R.id.widget_item_container, fillInIntent)
            views.setOnClickFillInIntent(R.id.widget_card_image, fillInIntent)
            views.setOnClickFillInIntent(R.id.widget_text_container, fillInIntent)
            views.setOnClickFillInIntent(R.id.widget_name, fillInIntent)
            views.setOnClickFillInIntent(R.id.widget_subtitle, fillInIntent)
            views.setOnClickFillInIntent(R.id.widget_status_container, fillInIntent)
            views.setOnClickFillInIntent(R.id.widget_days, fillInIntent)
            views.setOnClickFillInIntent(R.id.widget_status, fillInIntent)
        } catch (e: Exception) {
            e.printStackTrace()
        }

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    private fun getUrgencyStyle(status: String, days: Int): Triple<Int, Int, String> {
        return when {
            status.equals("EXPIRED", ignoreCase = true) || days <= 0 -> {
                Triple(R.drawable.widget_badge_expired, R.color.widget_status_expired_text, "EXPIRED")
            }
            status.equals("CRITICAL", ignoreCase = true) || status.equals("URGENT", ignoreCase = true) || days <= 30 -> {
                Triple(R.drawable.widget_badge_critical, R.color.widget_status_critical_text, "URGENT")
            }
            status.equals("WARNING", ignoreCase = true) || days <= 90 -> {
                Triple(R.drawable.widget_badge_warning, R.color.widget_status_warning_text, "WARNING")
            }
            else -> {
                Triple(R.drawable.widget_badge_safe, R.color.widget_status_safe_text, "SAFE")
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
