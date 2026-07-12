package com.juventud.palabramiel

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * BroadcastReceiver que abre la app cuando llega la hora de la alarma.
 * Se dispara junto con android_alarm_manager_plus via setAlarmClock().
 */
class AlarmLaunchReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("from_alarm", true)
        }
        context.startActivity(launchIntent)
    }
}
