package space.mai.mai_fitness.wear

import android.content.Context
import androidx.concurrent.futures.CallbackToFutureAdapter
import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.DimensionBuilders.expand
import androidx.wear.protolayout.DimensionBuilders.sp
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.ListenableFuture
import java.time.LocalDate
import java.time.ZoneId

/**
 * Kachel „Nächstes Training“: Plan, Tag, Woche und Serie. Tippen öffnet die
 * Übersicht auf der Uhr. Neu gezeichnet bei jedem Stand vom Telefon und kurz
 * nach Mitternacht („Heute“ wechselt).
 */
class NextWorkoutTileService : TileService() {
    override fun onTileRequest(
        requestParams: RequestBuilders.TileRequest,
    ): ListenableFuture<TileBuilders.Tile> {
        WatchStore.ensure(this)
        val tile = TileBuilders.Tile.Builder()
            .setResourcesVersion(RESOURCES_VERSION)
            .setFreshnessIntervalMillis(untilMidnight())
            .setTileTimeline(TimelineBuilders.Timeline.fromLayoutElement(layout(this)))
            .build()
        return done(tile)
    }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> =
        done(ResourceBuilders.Resources.Builder().setVersion(RESOURCES_VERSION).build())

    private fun layout(context: Context): LayoutElementBuilders.LayoutElement {
        val state = WatchStore.state(context)
        val column = LayoutElementBuilders.Column.Builder()
            .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
        column.addContent(text(context.getString(R.string.watch_next_title), 13f, COLOR_PRIMARY, bold = false))
        column.addContent(gap(4f))
        if (state == null || state.empty || state.name == null) {
            val hint = if (state == null) R.string.watch_setup else R.string.watch_empty
            column.addContent(text(context.getString(hint), 14f, COLOR_ON_SURFACE, bold = false, lines = 3))
        } else {
            column.addContent(text(state.name, 18f, COLOR_ON_SURFACE, bold = true, lines = 2))
            column.addContent(gap(2f))
            column.addContent(text(state.dayLabel(context), 14f, COLOR_PRIMARY, bold = false))
            val footer = listOfNotNull(state.weekLabel(context), state.streakLabel(context))
            if (footer.isNotEmpty()) {
                column.addContent(gap(6f))
                for (line in footer) column.addContent(text(line, 12f, COLOR_VARIANT, bold = false))
            }
        }
        return LayoutElementBuilders.Box.Builder()
            .setWidth(expand())
            .setHeight(expand())
            .setModifiers(
                ModifiersBuilders.Modifiers.Builder()
                    .setClickable(
                        ModifiersBuilders.Clickable.Builder()
                            .setId("open")
                            .setOnClick(
                                ActionBuilders.LaunchAction.Builder()
                                    .setAndroidActivity(
                                        ActionBuilders.AndroidActivity.Builder()
                                            .setPackageName(context.packageName)
                                            .setClassName(WatchActivity::class.java.name)
                                            .build(),
                                    )
                                    .build(),
                            )
                            .build(),
                    )
                    .build(),
            )
            .addContent(column.build())
            .build()
    }

    private fun text(
        value: String,
        size: Float,
        color: Int,
        bold: Boolean,
        lines: Int = 1,
    ): LayoutElementBuilders.LayoutElement =
        LayoutElementBuilders.Text.Builder()
            .setText(value)
            .setMaxLines(lines)
            .setMultilineAlignment(LayoutElementBuilders.TEXT_ALIGN_CENTER)
            .setOverflow(LayoutElementBuilders.TEXT_OVERFLOW_ELLIPSIZE_END)
            .setFontStyle(
                LayoutElementBuilders.FontStyle.Builder()
                    .setSize(sp(size))
                    .setColor(argb(color))
                    .setWeight(
                        if (bold) {
                            LayoutElementBuilders.FONT_WEIGHT_BOLD
                        } else {
                            LayoutElementBuilders.FONT_WEIGHT_NORMAL
                        },
                    )
                    .build(),
            )
            .build()

    private fun gap(height: Float): LayoutElementBuilders.LayoutElement =
        LayoutElementBuilders.Spacer.Builder().setHeight(dp(height)).build()

    /** Bis kurz nach Mitternacht (ms), damit „Heute/Morgen“ stimmt. */
    private fun untilMidnight(): Long {
        val next = LocalDate.now().plusDays(1)
            .atStartOfDay(ZoneId.systemDefault())
            .toInstant()
            .toEpochMilli() + 60_000L
        return (next - System.currentTimeMillis()).coerceAtLeast(60_000L)
    }

    private fun <T : Any> done(value: T): ListenableFuture<T> =
        CallbackToFutureAdapter.getFuture { it.set(value) }

    private companion object {
        const val RESOURCES_VERSION = "1"

        // App-Orange auf dunklem Uhr-Hintergrund (wie das Telefon-Widget, Nacht).
        const val COLOR_PRIMARY = 0xFFFFB59B.toInt()
        const val COLOR_ON_SURFACE = 0xFFF1DFDA.toInt()
        const val COLOR_VARIANT = 0xFFD8C2BC.toInt()
    }
}
