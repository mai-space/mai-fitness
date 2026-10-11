package space.mai.mai_fitness.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import space.mai.mai_fitness.MainActivity
import space.mai.mai_fitness.R
import java.time.LocalDate
import java.time.ZoneId

/**
 * Widget „Nächstes Training“. Größe frei wählbar; ab Android 12 liefert das
 * Widget mehrere Layouts, der Launcher wählt beim Skalieren selbst das
 * passende. Darunter wird bei jeder Größenänderung neu gezeichnet.
 */
class NextWorkoutWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) NextWorkoutWidget.draw(context, manager, id)
        NextWorkoutWidget.scheduleMidnight(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        id: Int,
        newOptions: Bundle,
    ) {
        NextWorkoutWidget.draw(context, manager, id)
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == NextWorkoutWidget.ACTION_REFRESH) {
            NextWorkoutWidget.refreshAll(context)
        } else {
            super.onReceive(context, intent)
        }
    }
}

/** Anzeigedaten, aus dem Stand der App aufbereitet. */
private class Model(
    val title: String,
    val name: String?,
    val day: String?,
    val button: String?,
    val week: String?,
    val rows: List<Row>,
    val more: String?,
    val empty: String,
)

private class Row(val name: String, val detail: String, val up: Boolean)

object NextWorkoutWidget {
    const val SCHEME = "maifit-widget"
    const val ACTION_REFRESH = "space.mai.mai_fitness.widget.REFRESH"
    private const val LINK_START = "$SCHEME://start"
    private const val LINK_OPEN = "$SCHEME://open"

    /** Feste Zeilen statt Liste: höchstens so viele Übungen (wie die App). */
    private const val MAX_ROWS = 8

    /** Größenstufen (dp). Gewählt wird die größte, die passt. */
    private enum class Size(val width: Float, val height: Float) {
        /** Eine Zeile hoch oder eine Spalte breit: Plan und Tag. */
        TINY(40f, 40f),

        /** Breite Zeile: dazu „Starten“. */
        STRIP(180f, 40f),

        /** Ab etwa 2×2: Übungen. */
        LIST(110f, 100f),

        /** Breit: Satz-/Gewichtsangaben rechts neben der Übung. */
        LIST_WIDE(250f, 100f),
    }

    fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, NextWorkoutWidgetProvider::class.java))
        for (id in ids) draw(context, manager, id)
        scheduleMidnight(context)
    }

    fun draw(context: Context, manager: AppWidgetManager, id: Int) {
        val model = model(context)
        val views = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            RemoteViews(Size.entries.associate { size -> SizeF(size.width, size.height) to views(context, model, size) })
        } else {
            val options = manager.getAppWidgetOptions(id)
            // Hochformat: kleinste Breite, größte Höhe.
            val w = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH).toFloat()
            val h = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT).toFloat()
            views(context, model, pick(w, h))
        }
        manager.updateAppWidget(id, views)
    }

    /** Wie das System ab Android 12: größte Stufe, die passt, sonst die kleinste. */
    private fun pick(width: Float, height: Float): Size {
        if (width <= 0f || height <= 0f) return Size.LIST
        return Size.entries
            .filter { it.width <= width && it.height <= height }
            .maxByOrNull { it.width * it.height }
            ?: Size.TINY
    }

    private fun model(context: Context): Model {
        val setup = context.getString(R.string.widget_setup)
        val title = context.getString(R.string.widget_next_label)
        val snap = WidgetStore.snapshot(context)
            ?: return Model(title, null, null, null, null, emptyList(), null, setup)
        val labels = snap.optJSONObject("labels") ?: JSONObject()
        fun label(key: String, fallback: String) = labels.optString(key, fallback).ifEmpty { fallback }

        val week = label("week", "").ifEmpty { null }
        val empty = label("empty", setup)
        val active = snap.optJSONObject("active")
        val next = snap.optJSONObject("next")
        val rows = ArrayList<Row>()
        val exercises = next?.optJSONArray("exercises")
        if (exercises != null) {
            for (i in 0 until minOf(exercises.length(), MAX_ROWS)) {
                val e = exercises.optJSONObject(i) ?: continue
                rows.add(Row(e.optString("name"), e.optString("detail"), e.optBoolean("up")))
            }
        }
        val moreCount = next?.optInt("more") ?: 0
        // „+3 weitere“ kommt fertig formuliert aus der App.
        val more = if (moreCount > 0) label("more", "+$moreCount") else null

        if (active != null) {
            // Laufendes Training: fortsetzen.
            return Model(
                title = label("title", title),
                name = active.optString("name"),
                day = label("today", ""),
                button = label("resume", ""),
                week = week,
                rows = rows,
                more = more,
                empty = empty,
            )
        }
        if (next == null) {
            return Model(label("title", title), null, null, null, week, emptyList(), null, empty)
        }
        return Model(
            title = label("title", title),
            name = next.optString("name"),
            day = dayLabel(next.optString("day", ""), labels),
            button = label("start", ""),
            week = week,
            rows = rows,
            more = more,
            empty = empty,
        )
    }

    /**
     * „Heute“, „Morgen“ oder Wochentag. Selbst berechnet, damit es nach
     * Mitternacht ohne App stimmt; ein verpasster Tag gilt als heute fällig.
     */
    private fun dayLabel(day: String, labels: JSONObject): String {
        val date = try {
            if (day.isEmpty() || day == "null") null else LocalDate.parse(day)
        } catch (_: Exception) {
            null
        } ?: return labels.optString("anyDay")
        val today = LocalDate.now()
        return when {
            !date.isAfter(today) -> labels.optString("today")
            date == today.plusDays(1) -> labels.optString("tomorrow")
            else -> labels.optJSONArray("weekdays")?.optString(date.dayOfWeek.value - 1)
                ?: labels.optString("anyDay")
        }
    }

    private fun views(context: Context, model: Model, size: Size): RemoteViews =
        when (size) {
            Size.TINY -> strip(context, model, compact = true)
            Size.STRIP -> strip(context, model, compact = false)
            Size.LIST -> list(context, model, wide = false)
            Size.LIST_WIDE -> list(context, model, wide = true)
        }

    private fun strip(context: Context, model: Model, compact: Boolean): RemoteViews {
        val v = RemoteViews(context.packageName, R.layout.widget_strip)
        val day = model.day?.takeIf { it.isNotEmpty() }
        v.setTextViewText(R.id.widget_title, if (day == null) model.title else "${model.title} · $day")
        v.setTextViewText(R.id.widget_line, model.name ?: model.empty)
        v.setOnClickPendingIntent(android.R.id.background, open(context, LINK_OPEN))
        v.setOnClickPendingIntent(R.id.widget_header, open(context, LINK_OPEN))
        if (!compact && model.button != null && model.name != null) {
            v.setViewVisibility(R.id.widget_start, View.VISIBLE)
            v.setContentDescription(R.id.widget_start, model.button)
            v.setOnClickPendingIntent(R.id.widget_start, open(context, LINK_START))
        }
        return v
    }

    private fun list(context: Context, model: Model, wide: Boolean): RemoteViews {
        val v = RemoteViews(context.packageName, R.layout.widget_list)
        v.setTextViewText(R.id.widget_title, model.name ?: model.title)
        val day = model.day?.takeIf { it.isNotEmpty() && model.name != null }
        v.setViewVisibility(R.id.widget_day, if (day == null) View.GONE else View.VISIBLE)
        v.setTextViewText(R.id.widget_day, day ?: "")
        v.setOnClickPendingIntent(android.R.id.background, open(context, LINK_OPEN))
        v.setOnClickPendingIntent(R.id.widget_header, open(context, LINK_OPEN))
        if (model.button != null && model.name != null) {
            v.setViewVisibility(R.id.widget_start, View.VISIBLE)
            v.setTextViewText(R.id.widget_start, model.button)
            v.setOnClickPendingIntent(R.id.widget_start, open(context, LINK_START))
        } else {
            v.setViewVisibility(R.id.widget_start, View.GONE)
        }
        v.setViewVisibility(R.id.widget_week, if (model.week == null) View.GONE else View.VISIBLE)
        v.setTextViewText(R.id.widget_week, model.week ?: "")

        v.removeAllViews(R.id.widget_rows)
        if (model.rows.isEmpty()) {
            v.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            v.setTextViewText(R.id.widget_empty, if (model.name == null) model.empty else "")
        } else {
            v.setViewVisibility(R.id.widget_empty, View.GONE)
            for (row in model.rows) v.addView(R.id.widget_rows, row(context, row, wide))
        }
        v.setViewVisibility(R.id.widget_more, if (model.more == null) View.GONE else View.VISIBLE)
        v.setTextViewText(R.id.widget_more, model.more ?: "")
        return v
    }

    private fun row(context: Context, row: Row, wide: Boolean): RemoteViews {
        val v = RemoteViews(
            context.packageName,
            if (wide) R.layout.widget_row_wide else R.layout.widget_row,
        )
        v.setTextViewText(R.id.row_name, row.name)
        v.setTextViewText(R.id.row_detail, row.detail)
        v.setViewVisibility(R.id.row_up, if (row.up) View.VISIBLE else View.GONE)
        return v
    }

    /** Öffnet die App (bzw. startet das Training) über den Kanal mai/widgets. */
    private fun open(context: Context, link: String): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_VIEW)
            .setData(Uri.parse(link))
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        return PendingIntent.getActivity(
            context,
            link.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /**
     * Kurz nach Mitternacht neu zeichnen („heute“ wechselt). Ungenauer
     * Wecker: braucht keine Berechtigung und weckt das Gerät nicht.
     */
    fun scheduleMidnight(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val any = manager
            .getAppWidgetIds(ComponentName(context, NextWorkoutWidgetProvider::class.java))
            .isNotEmpty()
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, NextWorkoutWidgetProvider::class.java).setAction(ACTION_REFRESH)
        val pending = PendingIntent.getBroadcast(
            context,
            1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        if (!any) {
            alarms.cancel(pending)
            return
        }
        val next = LocalDate.now().plusDays(1)
            .atStartOfDay(ZoneId.systemDefault())
            .toInstant()
            .toEpochMilli() + 60_000L
        alarms.set(AlarmManager.RTC, next, pending)
    }
}
