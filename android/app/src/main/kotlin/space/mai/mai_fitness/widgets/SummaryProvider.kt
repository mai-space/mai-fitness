package space.mai.mai_fitness.widgets

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.database.MatrixCursor
import android.net.Uri

/**
 * Gibt den Stand des Widget „Nächstes Training“ (`widget_snapshot.dart`, v1) an andere Mai-Apps weiter – für die
 * Prognose-Übersicht im Mai Launcher. Nur lesen, nur dieser eine Stand, den
 * das Homescreen-Widget ohnehin zeigt; keine Datenbank, kein Netz.
 *
 * Zugriff nur für Apps mit Paket `space.mai.*` UND derselben Signatur
 * (gleicher Upload-Schlüssel). Alle anderen bekommen nichts. Bewusst keine
 * eigene `<permission>`: deren Name müsste in allen Apps gleich sein, und
 * verschieden signierte Builds ließen sich dann nicht nebeneinander installieren.
 */
class SummaryProvider : ContentProvider() {
    override fun onCreate(): Boolean = true

    override fun query(
        uri: Uri,
        projection: Array<out String>?,
        selection: String?,
        selectionArgs: Array<out String>?,
        sortOrder: String?,
    ): Cursor? {
        val ctx = context ?: return null
        if (!trusted(ctx)) throw SecurityException("Nur für Mai-Apps mit gleicher Signatur")
        val json = WidgetStore.snapshotJson(ctx) ?: return null
        return MatrixCursor(arrayOf(COLUMN)).apply { addRow(arrayOf<Any>(json)) }
    }

    private fun trusted(ctx: Context): Boolean {
        val caller = callingPackage ?: return false
        if (caller == ctx.packageName) return true
        if (!caller.startsWith("space.mai.")) return false
        return runCatching {
            ctx.packageManager.checkSignatures(caller, ctx.packageName) == PackageManager.SIGNATURE_MATCH
        }.getOrDefault(false)
    }

    override fun getType(uri: Uri): String = "application/json"
    override fun insert(uri: Uri, values: ContentValues?): Uri? = null
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int = 0

    companion object {
        /** Spalte mit dem JSON-Stand. Name nie ändern (Mai Launcher liest ihn). */
        const val COLUMN = "json"
    }
}
