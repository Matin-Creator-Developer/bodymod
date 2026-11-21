import os

manifest_path = "android/app/src/main/AndroidManifest.xml"
m = open(manifest_path, "r", encoding="utf-8").read()
for perm in [
    '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>',
    '<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>'
]:
    if perm not in m:
        m = m.replace("<application", perm + "\n    <application", 1)

receiver_xml = '<receiver android:name=".BmStreakReceiver" android:exported="false" />'
if "BmStreakReceiver" not in m:
    m = m.replace("</application>", "        " + receiver_xml + "\n    </application>", 1)
open(manifest_path, "w", encoding="utf-8").write(m)

kt_dir = "android/app/src/main/kotlin/ir/matinmohammadi/bodymod"
os.makedirs(kt_dir, exist_ok=True)

main_kt = """package ir.matinmohammadi.bodymod

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "ir.matinmohammadi.bodymod/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAndroidId" -> {
                    try {
                        val aid = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID) ?: ""
                        result.success(aid)
                    } catch (e: Exception) {
                        result.success("")
                    }
                }
                "scheduleStreakReminder" -> {
                    try {
                        val delayMillis = (call.argument<Number>("delayMillis")?.toLong()) ?: 43200000L
                        val title = call.argument<String>("title") ?: "بادی‌مود 💙"
                        val body = call.argument<String>("body") ?: ""
                        val intent = Intent(this, BmStreakReceiver::class.java).apply {
                            putExtra("title", title)
                            putExtra("body", body)
                        }
                        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        } else {
                            PendingIntent.FLAG_UPDATE_CURRENT
                        }
                        val pi = PendingIntent.getBroadcast(this, 8842, intent, flags)
                        val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        am.set(AlarmManager.RTC_WAKEUP, System.currentTimeMillis() + delayMillis, pi)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
"""
open(os.path.join(kt_dir, "MainActivity.kt"), "w", encoding="utf-8").write(main_kt)

recv_kt = """package ir.matinmohammadi.bodymod

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BmStreakReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val title = intent.getStringExtra("title") ?: "بادی‌مود 💙🔥"
        val body = intent.getStringExtra("body") ?: "امروز تعامل نکردی رفیق!"
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channelId = "bm_streak_blue_heart"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(channelId, "یادآور استریک بادی‌مود", NotificationManager.IMPORTANCE_DEFAULT)
            nm.createNotificationChannel(ch)
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        val notif = builder
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setSmallIcon(context.applicationInfo.icon)
            .setAutoCancel(true)
            .build()
        nm.notify(8842, notif)
    }
}
"""
open(os.path.join(kt_dir, "BmStreakReceiver.kt"), "w", encoding="utf-8").write(recv_kt)
print("✅ Native ANDROID_ID & Blue Heart Notification injected!")
