package com.osedhelu.dtsdriver

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.app.FlutterApplication

/**
 * Application de DTS Driver.
 *
 * Crea el canal de notificaciones del FGS de tracking aquí, en `onCreate()`,
 * porque Android garantiza que este método corre ANTES que cualquier Service
 * del proceso (incluido el que reactiva el sistema por watchdogs/alarmas).
 *
 * Si el canal `dts_tracking` no existe cuando el servicio de segundo plano
 * llama a `startForeground()`, Android 13+ mata la app con
 * `CannotPostForegroundServiceNotificationException: Bad notification for
 * startForeground`.
 */
class DtsApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel =
                NotificationChannel(
                    TRACKING_CHANNEL_ID,
                    "Ubicación en entrega",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "Notificación del seguimiento de ubicación en segundo plano"
                }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    companion object {
        const val TRACKING_CHANNEL_ID = "dts_tracking"
    }
}
