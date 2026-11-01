package tn.elhrissa.el_hrissa_front

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    /** Canal des notifications push : importance haute, pour qu'un message s'affiche en bandeau et fasse du bruit. */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            "elahrisa_default",
            "Messages et rencontres",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Messages, demandes, matchs et rappels de sorties"
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }
}
