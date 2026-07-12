package com.juventud.palabramiel

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val WIDGET_CHANNEL = "com.juventud.palabramiel/widget"
    private val ALARM_CHANNEL  = "com.juventud.palabramiel/alarm"
    private var pendingAction: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Detectar si la app fue abierta por una alarma
        pendingAction = if (intent?.getBooleanExtra("from_alarm", false) == true) {
            "alarm"
        } else {
            intent?.getStringExtra("action")
        }

        // Canal del widget
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getIntentAction" -> {
                        val action = pendingAction
                        pendingAction = null
                        result.success(action)
                    }
                    "isAutomotive" -> {
                        val isAuto = packageManager.hasSystemFeature(PackageManager.FEATURE_AUTOMOTIVE)
                        result.success(isAuto)
                    }
                    else -> result.notImplemented()
                }
            }

        // Canal de alarmas (permisos + scheduling nativo)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canScheduleExactAlarms" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                            result.success(am.canScheduleExactAlarms())
                        } else {
                            result.success(true)
                        }
                    }
                    "requestExactAlarmPermission" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                        }
                        result.success(null)
                    }
                    "openBatterySettings" -> {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                        result.success(null)
                    }
                    "scheduleLaunchAlarm" -> {
                        val alarmTimeMs = call.argument<Long>("alarmTimeMs")
                        val id = (call.argument<Any>("id") as? Number)?.toInt()
                        if (alarmTimeMs == null || id == null) {
                            result.error("INVALID_ARGS", "alarmTimeMs and id are required", null)
                            return@setMethodCallHandler
                        }
                        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        // getActivity() es CRÍTICO: setAlarmClock() con PendingIntent de Activity
                        // es la única forma legítima de abrir la app desde background en Android 10+.
                        // Con getBroadcast(), Android bloquea el startActivity() del receiver.
                        val activityIntent = Intent(this, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                            putExtra("from_alarm", true)
                        }
                        val piFlags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        val pendingIntent = PendingIntent.getActivity(this, id, activityIntent, piFlags)
                        val clockInfo = AlarmManager.AlarmClockInfo(alarmTimeMs, pendingIntent)
                        am.setAlarmClock(clockInfo, pendingIntent)
                        result.success(null)
                    }
                    "cancelLaunchAlarm" -> {
                        val id = (call.argument<Any>("id") as? Number)?.toInt()
                        if (id == null) {
                            result.error("INVALID_ARGS", "id is required", null)
                            return@setMethodCallHandler
                        }
                        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        val activityIntent = Intent(this, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                            putExtra("from_alarm", true)
                        }
                        val piFlags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        val pendingIntent = PendingIntent.getActivity(this, id, activityIntent, piFlags)
                        am.cancel(pendingIntent)
                        result.success(null)
                    }
                    "canUseFullScreenIntent" -> {
                        if (Build.VERSION.SDK_INT >= 34) {
                            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                            result.success(nm.canUseFullScreenIntent())
                        } else {
                            result.success(true)
                        }
                    }
                    "requestFullScreenIntent" -> {
                        if (Build.VERSION.SDK_INT >= 34) {
                            val intent = Intent("android.settings.MANAGE_APP_USE_FULL_SCREEN_INTENTS").apply {
                                setData(Uri.parse("package:$packageName"))
                            }
                            startActivity(intent)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        pendingAction = if (intent.getBooleanExtra("from_alarm", false)) {
            "alarm"
        } else {
            intent.getStringExtra("action")
        }
    }
}
