package com.juventud.palabramiel

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.ComponentName
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.view.KeyEvent

class RadioWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            "TOGGLE_PLAY" -> {
                // Enviar comando de media button para toggle play/pause
                // Esto funciona con audio_service sin abrir la app
                val keyEvent = KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
                val mediaIntent = Intent(Intent.ACTION_MEDIA_BUTTON)
                mediaIntent.putExtra(Intent.EXTRA_KEY_EVENT, keyEvent)
                mediaIntent.setPackage(context.packageName)
                context.sendBroadcast(mediaIntent)

                // Enviar KEY_UP también
                val keyEventUp = KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
                val mediaIntentUp = Intent(Intent.ACTION_MEDIA_BUTTON)
                mediaIntentUp.putExtra(Intent.EXTRA_KEY_EVENT, keyEventUp)
                mediaIntentUp.setPackage(context.packageName)
                context.sendBroadcast(mediaIntentUp)
            }
            "OPEN_APP" -> {
                // Solo abrir la app
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(launchIntent)
            }
        }
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.radio_widget)

            // Obtener datos de SharedPreferences (donde home_widget guarda los datos)
            val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val title = prefs.getString("widget_title", "Toca para sintonizar") ?: "Toca para sintonizar"
            val streak = prefs.getInt("widget_streak", 0)
            val isPlaying = prefs.getBoolean("widget_is_playing", false)

            // Actualizar textos
            views.setTextViewText(R.id.widget_title, title)
            views.setTextViewText(R.id.widget_streak, streak.toString())

            // Actualizar estado - siempre muestra Radio Juventud
            views.setTextViewText(R.id.widget_status, "Radio Juventud")
            if (isPlaying) {
                views.setImageViewResource(R.id.widget_play_button, R.drawable.ic_pause)
            } else {
                views.setImageViewResource(R.id.widget_play_button, R.drawable.ic_play)
            }

            // Intent para toggle play/pause al tocar el botón
            val toggleIntent = Intent(context, RadioWidgetProvider::class.java).apply {
                action = "TOGGLE_PLAY"
            }
            val togglePendingIntent = PendingIntent.getBroadcast(
                context,
                1,
                toggleIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Intent para abrir la app al tocar el widget
            val openIntent = Intent(context, RadioWidgetProvider::class.java).apply {
                action = "OPEN_APP"
            }
            val openPendingIntent = PendingIntent.getBroadcast(
                context,
                2,
                openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Botón play/pause toggle
            views.setOnClickPendingIntent(R.id.widget_play_button, togglePendingIntent)
            // El resto del widget solo abre la app
            views.setOnClickPendingIntent(R.id.widget_container, openPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        // Método para actualizar todos los widgets desde Flutter
        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val widgetComponent = ComponentName(context, RadioWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(widgetComponent)

            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }
}
