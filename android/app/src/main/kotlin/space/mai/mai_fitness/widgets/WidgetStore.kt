package space.mai.mai_fitness.widgets

import android.content.Context
import org.json.JSONObject

/**
 * Speicher des Homescreen-Widgets (nur lokal, SharedPreferences): letzter
 * Stand aus der App (JSON, siehe `lib/home_widgets/widget_snapshot.dart`).
 */
object WidgetStore {
    private const val PREFS = "mai_fitness_widgets"
    private const val KEY_SNAPSHOT = "snapshot"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun saveSnapshot(context: Context, json: String) {
        prefs(context).edit().putString(KEY_SNAPSHOT, json).apply()
    }

    /** Letzter Stand der App oder `null` (App noch nie geöffnet/eingerichtet). */
    fun snapshot(context: Context): JSONObject? {
        val raw = prefs(context).getString(KEY_SNAPSHOT, null) ?: return null
        return try {
            JSONObject(raw)
        } catch (_: Exception) {
            null
        }
    }
}
