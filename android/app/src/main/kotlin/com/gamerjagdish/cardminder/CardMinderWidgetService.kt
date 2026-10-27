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
import android.view.View
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
            // Show only the card network under the card name (no redundant card number)
            views.setTextViewText(R.id.widget_subtitle, network)

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

            // Hide hairline divider under the last card item in the list
            val isLastItem = position == cardsList.size - 1
            views.setViewVisibility(
                R.id.widget_item_divider,
                if (isLastItem) View.GONE else View.VISIBLE
            )

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
        // Proportional credit card dimensions (44dp x 30dp, aspect ratio ~1.47:1)
        val width = (44 * density).toInt().coerceAtLeast(88)
        val height = (30 * density).toInt().coerceAtLeast(60)

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
        hsv[2] = (hsv[2] * 0.75f).coerceIn(0f, 1f)
        val darkerColor = Color.HSVToColor(hsv)

        val cornerRadius = 8 * density
        val cardRect = RectF(0f, 0f, width.toFloat(), height.toFloat())

        // Strictly clip canvas to rounded rectangle so no drawing ever bleeds into the corners
        val cardPath = android.graphics.Path().apply {
            addRoundRect(cardRect, cornerRadius, cornerRadius, android.graphics.Path.Direction.CW)
        }
        canvas.clipPath(cardPath)

        // Diagonal gradient for subtle depth
        val cardPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(
                0f, 0f, width.toFloat(), height.toFloat(),
                cardColor, darkerColor, Shader.TileMode.CLAMP
            )
        }
        canvas.drawRoundRect(cardRect, cornerRadius, cornerRadius, cardPaint)

        // Subtle specular highlight rim simulating light reflection on rounded card edge
        val highlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            alpha = 35
            style = Paint.Style.STROKE
            strokeWidth = 1f * density
        }
        val strokeInset = 0.5f * density
        val strokeRect = RectF(
            strokeInset, strokeInset,
            width.toFloat() - strokeInset, height.toFloat() - strokeInset
        )
        canvas.drawRoundRect(strokeRect, cornerRadius - strokeInset, cornerRadius - strokeInset, highlightPaint)

        // Dynamic luminance-aware text color matching Flutter AppTheme (luminance > 0.45)
        val luminance = (0.299 * Color.red(cardColor) + 0.587 * Color.green(cardColor) + 0.114 * Color.blue(cardColor)) / 255.0
        val cardTextColor = if (luminance > 0.45) Color.parseColor("#0F172A") else Color.WHITE

        // Centered bold digits (last 4) matching app's _CardTileBody thumbnail
        val safeDigits = if (digits.length >= 4) digits.takeLast(4) else digits.padStart(4, '0')
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = cardTextColor
            textSize = 11.5f * density
            isFakeBoldText = true
            textAlign = Paint.Align.CENTER
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                letterSpacing = 0.08f
            }
        }
        val fontMetrics = textPaint.fontMetrics
        val textY = (height / 2f) - ((fontMetrics.ascent + fontMetrics.descent) / 2f)
        canvas.drawText(safeDigits, width / 2f, textY, textPaint)

        return bitmap
    }
}
