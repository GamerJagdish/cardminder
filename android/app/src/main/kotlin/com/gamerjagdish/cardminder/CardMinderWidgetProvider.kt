package com.gamerjagdish.cardminder

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews

class CardMinderWidgetProvider : AppWidgetProvider() {

    @Suppress("DEPRECATION")
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

                // 2. Explicit theme overrides when user forced light or dark in settings
                if (themePref == "dark") {
                    views.setInt(R.id.widget_container, "setBackgroundColor", Color.parseColor("#1E293B"))
                    views.setTextColor(R.id.widget_title, Color.parseColor("#F8FAFC"))
                    views.setTextColor(R.id.widget_cards_count_label, Color.parseColor("#F8FAFC"))
                    views.setInt(R.id.widget_divider, "setBackgroundColor", Color.parseColor("#334155"))
                } else if (themePref == "light") {
                    views.setInt(R.id.widget_container, "setBackgroundColor", Color.parseColor("#FFFFFF"))
                    views.setTextColor(R.id.widget_title, Color.parseColor("#0F172A"))
                    views.setTextColor(R.id.widget_cards_count_label, Color.parseColor("#0F172A"))
                    views.setInt(R.id.widget_divider, "setBackgroundColor", Color.parseColor("#E2E8F0"))
                }

                // 3. Card Count Header
                val totalCards = prefs.getInt("total_cards", 0)
                views.setTextViewText(
                    R.id.widget_cards_count_label,
                    if (totalCards == 1) "1 CARD" else "$totalCards CARDS"
                )

                // 4. Bind Remote Adapter for Scrollable ListView
                val serviceIntent = Intent(context, CardMinderWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                }
                views.setRemoteAdapter(R.id.widget_cards_list, serviceIntent)
                views.setEmptyView(R.id.widget_cards_list, R.id.widget_empty_container)

                // 5. Pending Intent to launch CardMinder MainActivity
                val clickIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    clickIntent,
                    flags
                )
                views.setPendingIntentTemplate(R.id.widget_cards_list, pendingIntent)
                views.setOnClickPendingIntent(R.id.widget_header, pendingIntent)
                views.setOnClickPendingIntent(R.id.widget_empty_container, pendingIntent)

                // 6. Update widget and notify data change to refresh ListView
                appWidgetManager.updateAppWidget(appWidgetId, views)
                appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_cards_list)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
