package space.mai.mai_fitness.wear

import android.app.Activity
import android.graphics.Typeface
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/**
 * Übersicht auf der Uhr (Ziel von Kachel und Komplikation): nächstes
 * Training, Woche, Serie. Gestartet wird das Training auf dem Telefon.
 */
class WatchActivity : Activity() {
    private lateinit var column: LinearLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Runde Displays: großzügiger Rand, Inhalt mittig.
        val pad = (resources.displayMetrics.widthPixels * 0.12f).toInt()
        column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(pad, pad, pad, pad)
        }
        setContentView(
            ScrollView(this).apply {
                isFillViewport = true
                addView(column)
            },
        )
    }

    override fun onResume() {
        super.onResume()
        WatchStore.ensure(this)
        render()
    }

    private fun render() {
        column.removeAllViews()
        val state = WatchStore.state(this)
        line(getString(R.string.watch_next_title), 14f, COLOR_PRIMARY)
        if (state == null || state.empty || state.name == null) {
            line(getString(if (state == null) R.string.watch_setup else R.string.watch_empty), 15f, COLOR_ON_SURFACE)
            return
        }
        line(state.name, 20f, COLOR_ON_SURFACE, bold = true)
        line(state.dayLabel(this), 15f, COLOR_PRIMARY)
        state.weekLabel(this)?.let { line(it, 14f, COLOR_VARIANT) }
        state.streakLabel(this)?.let { line(it, 14f, COLOR_VARIANT) }
        line(getString(R.string.watch_start_on_phone), 12f, COLOR_VARIANT)
    }

    private fun line(value: String, size: Float, color: Int, bold: Boolean = false) {
        column.addView(
            TextView(this).apply {
                text = value
                gravity = Gravity.CENTER_HORIZONTAL
                setTextColor(color)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, size)
                if (bold) setTypeface(typeface, Typeface.BOLD)
                setPadding(0, 4, 0, 4)
            },
        )
    }

    private companion object {
        const val COLOR_PRIMARY = 0xFFFFB59B.toInt()
        const val COLOR_ON_SURFACE = 0xFFF1DFDA.toInt()
        const val COLOR_VARIANT = 0xFFD8C2BC.toInt()
    }
}
