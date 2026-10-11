package space.mai.mai_fitness

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import space.mai.mai_fitness.widgets.NextWorkoutWidget
import space.mai.mai_fitness.widgets.WearSync
import space.mai.mai_fitness.widgets.WidgetStore
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private var widgetChannel: MethodChannel? = null
    private var initialLinkTaken = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, DatabaseKeyChannel.NAME)
            .setMethodCallHandler(DatabaseKeyChannel(applicationContext))
        // IANA-Zeitzone des Geräts (z. B. „Europe/Berlin“) für Erinnerungen.
        MethodChannel(messenger, "mai/device").setMethodCallHandler { call, result ->
            when (call.method) {
                "timeZone" -> result.success(TimeZone.getDefault().id)
                else -> result.notImplemented()
            }
        }
        // Homescreen-Widget: Stand aus der App, Link beim Öffnen über das Widget.
        widgetChannel = MethodChannel(messenger, "mai/widgets").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "update" -> {
                        val json = call.arguments as? String
                        if (json != null) {
                            WidgetStore.saveSnapshot(applicationContext, json)
                            NextWorkoutWidget.refreshAll(applicationContext)
                            // Wear-OS-Kachel/-Komplikation (nur mit Uhr-App).
                            WearSync.publish(applicationContext, WidgetStore.snapshot(applicationContext))
                        }
                        result.success(null)
                    }
                    "initialLink" -> {
                        val link = if (initialLinkTaken) null else widgetLink(intent)
                        initialLinkTaken = true
                        result.success(link)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        widgetLink(intent)?.let { widgetChannel?.invokeMethod("open", it) }
    }

    private fun widgetLink(intent: Intent?): String? =
        intent?.data?.takeIf { it.scheme == NextWorkoutWidget.SCHEME }?.toString()
}
