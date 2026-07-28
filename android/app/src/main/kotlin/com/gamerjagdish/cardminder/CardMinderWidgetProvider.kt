package com.gamerjagdish.cardminder

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class CardMinderWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                val views = RemoteViews(context.packageName, R.layout.card_minder_widget)

                // Retrieve saved data from HomeWidget preferences
                val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                val cardName = prefs.getString("urgent_card_name", null) ?: "No Cards Tracked"
                val cardDigits = prefs.getString("urgent_card_digits", null) ?: ""
                val daysLeft = prefs.getInt("urgent_card_days", -1)
                val totalCards = prefs.getInt("total_cards", 0)

                views.setTextViewText(R.id.widget_card_name, cardName)
                views.setTextViewText(R.id.widget_card_digits, cardDigits)

                if (totalCards > 0 && daysLeft >= 0) {
                    views.setTextViewText(R.id.widget_days_count, "$daysLeft")
                    views.setTextViewText(R.id.widget_days_label, "DAYS LEFT")

                    // Color code based on days remaining
                    if (daysLeft <= 30) {
                        views.setTextColor(R.id.widget_days_count, android.graphics.Color.parseColor("#EF4444"))
                    } else if (daysLeft <= 90) {
                        views.setTextColor(R.id.widget_days_count, android.graphics.Color.parseColor("#F59E0B"))
                    } else {
                        views.setTextColor(R.id.widget_days_count, android.graphics.Color.parseColor("#10B981"))
                    }
                } else {
                    views.setTextViewText(R.id.widget_days_count, "—")
                    views.setTextViewText(R.id.widget_days_label, "NO CARDS")
                    views.setTextColor(R.id.widget_days_count, android.graphics.Color.parseColor("#94A3B8"))
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
