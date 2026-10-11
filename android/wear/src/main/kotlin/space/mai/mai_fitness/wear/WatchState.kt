package space.mai.mai_fitness.wear

import android.content.ComponentName
import android.content.Context
import android.net.Uri
import androidx.wear.tiles.TileService
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceUpdateRequester
import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.DataItem
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import org.json.JSONObject
import java.time.LocalDate
import java.time.format.TextStyle
import java.util.Locale

/**
 * Stand vom Telefon (siehe `WearSync` in der Telefon-App), nur lokal in
 * SharedPreferences. Format `v` 1; Unbekanntes wird ignoriert.
 */
class WatchState(
    val name: String?,
    val day: LocalDate?,
    val active: Boolean,
    val empty: Boolean,
    val weekDone: Int,
    val weekGoal: Int,
    val streak: Int,
) {
    /** „Heute“, „Morgen“, Wochentag — selbst berechnet, stimmt auch nach Mitternacht. */
    fun dayLabel(context: Context, today: LocalDate = LocalDate.now()): String {
        if (active) return context.getString(R.string.watch_running)
        val d = day ?: return context.getString(R.string.watch_any_day)
        return when {
            // Verpasster Tag gilt als heute fällig (wie das Telefon-Widget).
            !d.isAfter(today) -> context.getString(R.string.watch_today)
            d == today.plusDays(1) -> context.getString(R.string.watch_tomorrow)
            else -> d.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.getDefault())
        }
    }

    fun weekLabel(context: Context): String? =
        if (weekGoal <= 0) null else context.getString(R.string.watch_week, weekDone, weekGoal)

    fun streakLabel(context: Context): String? =
        if (streak <= 0) {
            null
        } else {
            context.resources.getQuantityString(R.plurals.watch_streak, streak, streak)
        }

    companion object {
        fun parse(raw: String?): WatchState? {
            if (raw == null) return null
            return try {
                val j = JSONObject(raw)
                val week = j.optJSONObject("week")
                val dayRaw = j.optString("day", "")
                WatchState(
                    name = j.optString("name", "").takeIf { it.isNotEmpty() && !j.isNull("name") },
                    day = try {
                        if (dayRaw.isEmpty() || j.isNull("day")) null else LocalDate.parse(dayRaw)
                    } catch (_: Exception) {
                        null
                    },
                    active = j.optBoolean("active"),
                    empty = j.optBoolean("empty"),
                    weekDone = week?.optInt("done") ?: 0,
                    weekGoal = week?.optInt("goal") ?: 0,
                    streak = j.optInt("streak"),
                )
            } catch (_: Exception) {
                null
            }
        }
    }
}

object WatchStore {
    const val PATH_NEXT = "/mai-fitness/next"
    const val PATH_REQUEST = "/mai-fitness/request"
    private const val KEY_JSON = "json"
    private const val CAPABILITY_PHONE = "mai_fitness_phone"

    private const val PREFS = "mai_fitness_watch"
    private const val KEY_STATE = "state"
    private const val KEY_ASKED = "asked"

    /** Höchstens so oft beim Telefon nachfragen (ms). */
    private const val ASK_INTERVAL = 15 * 60 * 1000L

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun state(context: Context): WatchState? = WatchState.parse(prefs(context).getString(KEY_STATE, null))

    /** Neuer Stand vom Telefon (`null`: gelöscht). Zeichnet Kachel und Komplikation neu. */
    fun save(context: Context, json: String?) {
        prefs(context).edit().apply {
            if (json == null) remove(KEY_STATE) else putString(KEY_STATE, json)
        }.apply()
        refreshAll(context)
    }

    fun refreshAll(context: Context) {
        val app = context.applicationContext
        try {
            TileService.getUpdater(app).requestUpdate(NextWorkoutTileService::class.java)
        } catch (_: Exception) {
        }
        try {
            ComplicationDataSourceUpdateRequester
                .create(app, ComponentName(app, NextWorkoutComplicationService::class.java))
                .requestUpdateAll()
        } catch (_: Exception) {
        }
    }

    /**
     * Noch kein Stand (z. B. Uhr-App frisch installiert): zuerst die
     * vorhandenen Daten der Datenschicht lesen, sonst das Telefon fragen.
     */
    fun ensure(context: Context) {
        if (state(context) != null) return
        val app = context.applicationContext
        val prefs = prefs(app)
        val now = System.currentTimeMillis()
        if (now - prefs.getLong(KEY_ASKED, 0L) < ASK_INTERVAL) return
        prefs.edit().putLong(KEY_ASKED, now).apply()
        try {
            Wearable.getDataClient(app)
                .getDataItems(Uri.parse("wear://*$PATH_NEXT"))
                .addOnSuccessListener { items ->
                    var json: String? = null
                    for (item in items) {
                        json = jsonOf(item) ?: json
                    }
                    items.release()
                    if (json != null) save(app, json) else askPhone(app)
                }
                .addOnFailureListener { askPhone(app) }
        } catch (_: Exception) {
        }
    }

    private fun askPhone(context: Context) {
        try {
            Wearable.getCapabilityClient(context)
                .getCapability(CAPABILITY_PHONE, CapabilityClient.FILTER_REACHABLE)
                .addOnSuccessListener { info ->
                    val messages = Wearable.getMessageClient(context)
                    for (node in info.nodes) messages.sendMessage(node.id, PATH_REQUEST, ByteArray(0))
                }
        } catch (_: Exception) {
        }
    }

    fun jsonOf(item: DataItem): String? =
        DataMapItem.fromDataItem(item).dataMap.getString(KEY_JSON)
}
