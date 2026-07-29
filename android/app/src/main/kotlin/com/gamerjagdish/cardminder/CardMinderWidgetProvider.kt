package com.gamerjagdish.cardminder

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray

class CardMinderWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.card_minder_widget)
                val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

                // Static Widget Header Title: CARDMINDER
                views.setTextViewText(R.id.widget_title, "CARDMINDER")

                val jsonString = prefs.getString("widget_cards_json", null)
                val totalCards = prefs.getInt("total_cards", 0)

                views.setTextViewText(R.id.widget_cards_count_label, "$totalCards CARDS")

                val rowIds = arrayOf(
                    R.id.widget_row_1 to Triple(R.id.widget_name_1, R.id.widget_digits_1, R.id.widget_days_1),
                    R.id.widget_row_2 to Triple(R.id.widget_name_2, R.id.widget_digits_2, R.id.widget_days_2),
                    R.id.widget_row_3 to Triple(R.id.widget_name_3, R.id.widget_digits_3, R.id.widget_days_3),
                    R.id.widget_row_4 to Triple(R.id.widget_name_4, R.id.widget_digits_4, R.id.widget_days_4),
                    R.id.widget_row_5 to Triple(R.id.widget_name_5, R.id.widget_digits_5, R.id.widget_days_5)
                )

                if (jsonString != null && jsonString.isNotEmpty()) {
                    val jsonArray = JSONArray(jsonString)

                    for (i in 0 until 5) {
                        val (rowContainer, fields) = rowIds[i]
                        val (nameId, digitsId, daysId) = fields

                        if (i < jsonArray.length()) {
                            val item = jsonArray.getJSONObject(i)
                            views.setViewVisibility(rowContainer, View.VISIBLE)
                            views.setTextViewText(nameId, item.optString("name", "Card"))
                            views.setTextViewText(digitsId, item.optString("digits", "0000"))

                            val days = item.optInt("days", -1)
                            views.setTextViewText(daysId, if (days >= 0) "${days}d" else "—")

                            val color = if (days <= 30) "#EF4444" else if (days <= 90) "#F59E0B" else "#10B981"
                            views.setTextColor(daysId, android.graphics.Color.parseColor(color))
                        } else {
                            if (i == 0 && jsonArray.length() == 0) {
                                views.setViewVisibility(rowContainer, View.VISIBLE)
                                views.setTextViewText(nameId, "No Cards Tracked")
                                views.setTextViewText(digitsId, "0000")
                                views.setTextViewText(daysId, "—")
                            } else {
                                views.setViewVisibility(rowContainer, View.GONE)
                            }
                        }
                    }
                } else {
                    // Fallback
                    views.setViewVisibility(R.id.widget_row_1, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_row_2, View.GONE)
                    views.setViewVisibility(R.id.widget_row_3, View.GONE)
                    views.setViewVisibility(R.id.widget_row_4, View.GONE)
                    views.setViewVisibility(R.id.widget_row_5, View.GONE)

                    views.setTextViewText(R.id.widget_name_1, "No Cards Tracked")
                    views.setTextViewText(R.id.widget_digits_1, "0000")
                    views.setTextViewText(R.id.widget_days_1, "—")
                }

                // Tap widget to launch MainActivity
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

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
