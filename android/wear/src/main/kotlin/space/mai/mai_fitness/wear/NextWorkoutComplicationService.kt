package space.mai.mai_fitness.wear

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationText
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.LongTextComplicationData
import androidx.wear.watchface.complications.data.MonochromaticImage
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.RangedValueComplicationData
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceService
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import java.time.LocalDate

/**
 * Komplikation fürs Zifferblatt:
 * - kurz: Tag des nächsten Trainings („Heute“, „Mi“), Titel = Serie
 * - lang: Plan und Tag
 * - Fortschritt: Trainings dieser Woche gegen das Wochenziel
 */
class NextWorkoutComplicationService : ComplicationDataSourceService() {
    override fun onComplicationRequest(
        request: ComplicationRequest,
        listener: ComplicationDataSourceService.ComplicationRequestListener,
    ) {
        WatchStore.ensure(this)
        listener.onComplicationData(data(this, request.complicationType, WatchStore.state(this)))
    }

    override fun getPreviewData(type: ComplicationType): ComplicationData? =
        data(
            this,
            type,
            WatchState(
                name = getString(R.string.watch_preview_plan),
                day = LocalDate.now(),
                active = false,
                empty = false,
                weekDone = 2,
                weekGoal = 3,
                streak = 4,
            ),
            preview = true,
        )

    private fun data(
        context: Context,
        type: ComplicationType,
        state: WatchState?,
        preview: Boolean = false,
    ): ComplicationData? {
        val ready = state?.takeIf { !it.empty && it.name != null }
        val day = ready?.dayLabel(context) ?: context.getString(R.string.watch_none)
        val name = ready?.name ?: context.getString(R.string.watch_setup_short)
        val description = plain("${context.getString(R.string.watch_next_title)}: $name, $day")
        val icon = MonochromaticImage.Builder(Icon.createWithResource(context, R.drawable.ic_fitness)).build()
        val tap = if (preview) null else open(context)
        return when (type) {
            ComplicationType.SHORT_TEXT -> ShortTextComplicationData.Builder(plain(day), description)
                .setMonochromaticImage(icon)
                .apply { if (ready != null && ready.streak > 0) setTitle(plain("${ready.streak}×")) }
                .setTapAction(tap)
                .build()
            ComplicationType.LONG_TEXT -> LongTextComplicationData.Builder(plain(name), description)
                .setTitle(plain(day))
                .setMonochromaticImage(icon)
                .setTapAction(tap)
                .build()
            ComplicationType.RANGED_VALUE -> {
                val goal = (state?.weekGoal ?: 0).coerceAtLeast(1)
                val done = (state?.weekDone ?: 0).coerceIn(0, goal)
                val label = "${state?.weekDone ?: 0}/${state?.weekGoal ?: 0}"
                RangedValueComplicationData.Builder(
                    done.toFloat(),
                    0f,
                    goal.toFloat(),
                    plain(state?.weekLabel(context) ?: label),
                )
                    .setText(plain(label))
                    .setMonochromaticImage(icon)
                    .setTapAction(tap)
                    .build()
            }
            else -> null
        }
    }

    private fun plain(text: String): ComplicationText = PlainComplicationText.Builder(text).build()

    private fun open(context: Context): PendingIntent =
        PendingIntent.getActivity(
            context,
            0,
            Intent(context, WatchActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
}
