package com.gamerjagdish.cardminder

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
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

                // 1. Card Count Header
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

                // 5. Pending Intents to launch CardMinder MainActivity
                // 5a. PendingIntentTemplate for individual card clicks (fillInIntent supplies card deep-link)
                val listClickIntent = Intent(context, MainActivity::class.java).apply {
                    action = "es.antonborri.home_widget.action.LAUNCH"
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val listFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val listPendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    listClickIntent,
                    listFlags
                )
                views.setPendingIntentTemplate(R.id.widget_cards_list, listPendingIntent)

                // 5b. General PendingIntent for clicking header / empty container to open home
                val generalClickIntent = Intent(context, MainActivity::class.java).apply {
                    action = "es.antonborri.home_widget.action.LAUNCH"
                    data = Uri.parse("cardminder://home")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val generalFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val generalPendingIntent = PendingIntent.getActivity(
                    context,
                    1,
                    generalClickIntent,
                    generalFlags
                )
                views.setOnClickPendingIntent(R.id.widget_header, generalPendingIntent)
                views.setOnClickPendingIntent(R.id.widget_empty_container, generalPendingIntent)

                // 6. Update widget and notify data change to refresh ListView
                appWidgetManager.updateAppWidget(appWidgetId, views)
                appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_cards_list)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
