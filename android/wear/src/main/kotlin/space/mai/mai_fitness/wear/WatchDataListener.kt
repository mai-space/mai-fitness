package space.mai.mai_fitness.wear

import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.WearableListenerService

/** Empfängt den Stand vom Telefon (Wearable-Datenschicht). */
class WatchDataListener : WearableListenerService() {
    override fun onDataChanged(events: DataEventBuffer) {
        for (event in events) {
            if (event.dataItem.uri.path != WatchStore.PATH_NEXT) continue
            when (event.type) {
                DataEvent.TYPE_CHANGED -> WatchStore.save(this, WatchStore.jsonOf(event.dataItem))
                DataEvent.TYPE_DELETED -> WatchStore.save(this, null)
            }
        }
        // Puffer gibt der Dienst nach der Rückkehr selbst frei.
    }
}
