package com.juventud.palabramiel

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.juventud.palabramiel/widget"
    private var pendingAction: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Capturar la acción del intent al iniciar
        pendingAction = intent?.getStringExtra("action")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getIntentAction" -> {
                    val action = pendingAction
                    pendingAction = null // Limpiar después de leer
                    result.success(action)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        // Capturar la acción cuando la app ya está abierta
        pendingAction = intent.getStringExtra("action")
    }
}
