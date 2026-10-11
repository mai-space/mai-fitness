package space.mai.mai_fitness.widgets

import android.content.Context
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService
import org.json.JSONObject

/**
 * Stand für die Uhr (Wear-OS-Kachel und -Komplikation), abgeleitet aus dem
 * Widget-Stand. Geht nur an gekoppelte Uhren, auf denen die Fitness-Uhr-App
 * installiert ist (Fähigkeit [CAPABILITY_WATCH]) — ohne Uhr verlässt nichts
 * das Telefon. Übertragung über die Wearable-Datenschicht der Google-Play-
 * Dienste, keine eigene Netzwerkverbindung.
 *
 * Format (`v` bleibt 1, nur erweitern; die Uhr ignoriert Unbekanntes):
 * `{"v":1,"name":…,"day":"2026-10-12"|null,"active":bool,
 *   "week":{"done":…,"goal":…},"streak":…,"empty":bool}`
 */
object WearSync {
    const val PATH_NEXT = "/mai-fitness/next"
    const val PATH_REQUEST = "/mai-fitness/request"
    const val KEY_JSON = "json"
    private const val CAPABILITY_WATCH = "mai_fitness_watch"

    private const val PREFS = "mai_fitness_wear"
    private const val KEY_SENT = "sent"

    /**
     * Schickt den aktuellen Stand an die Uhr, falls er sich geändert hat
     * ([force]: auch unverändert, z. B. auf Anfrage einer neu eingerichteten
     * Uhr). Fehler (keine Play-Dienste, keine Uhr) werden ignoriert.
     */
    fun publish(context: Context, snapshot: JSONObject?, force: Boolean = false) {
        val app = context.applicationContext
        val payload = payload(snapshot ?: return).toString()
        val prefs = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!force && prefs.getString(KEY_SENT, null) == payload) return
        try {
            Wearable.getCapabilityClient(app)
                .getCapability(CAPABILITY_WATCH, CapabilityClient.FILTER_ALL)
                .addOnSuccessListener { info ->
                    if (info.nodes.isEmpty()) return@addOnSuccessListener
                    val request = PutDataMapRequest.create(PATH_NEXT).apply {
                        dataMap.putString(KEY_JSON, payload)
                    }.asPutDataRequest().setUrgent()
                    Wearable.getDataClient(app).putDataItem(request)
                        .addOnSuccessListener {
                            prefs.edit().putString(KEY_SENT, payload).apply()
                        }
                }
        } catch (_: Exception) {
            // Uhr ist Beiwerk — Telefon-Widget und App laufen weiter.
        }
    }

    /** Nur das, was Kachel und Komplikation zeigen — keine Übungen/Gewichte. */
    fun payload(snap: JSONObject): JSONObject {
        val active = snap.optJSONObject("active")
        val next = snap.optJSONObject("next")
        val week = snap.optJSONObject("week")
        val out = JSONObject()
        out.put("v", 1)
        out.put("active", active != null)
        val name = (active ?: next)?.optString("name")?.takeIf { it.isNotEmpty() }
        out.put("name", name ?: JSONObject.NULL)
        val day = next?.optString("day", "")?.takeIf { active == null && it.isNotEmpty() && it != "null" }
        out.put("day", day ?: JSONObject.NULL)
        out.put("empty", active == null && next == null)
        out.put(
            "week",
            JSONObject()
                .put("done", week?.optInt("done") ?: 0)
                .put("goal", week?.optInt("goal") ?: 0),
        )
        out.put("streak", snap.optInt("streak"))
        return out
    }
}

/**
 * Anfrage einer Uhr (z. B. direkt nach der Installation der Uhr-App): letzten
 * gespeicherten Stand schicken — funktioniert auch, wenn die App nicht läuft.
 */
class WearRequestListener : WearableListenerService() {
    override fun onMessageReceived(event: MessageEvent) {
        if (event.path == WearSync.PATH_REQUEST) {
            WearSync.publish(this, WidgetStore.snapshot(this), force = true)
        }
    }
}
