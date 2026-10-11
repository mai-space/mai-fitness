package space.mai.mai_fitness

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.security.KeyStore
import java.security.SecureRandom
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * Schlüssel der verschlüsselten Datenbank.
 *
 * Ein zufälliger 256-Bit-Schlüssel wird mit einem AES-Schlüssel aus dem
 * Android Keystore verpackt und in `noBackupFilesDir` abgelegt. Der
 * Keystore-Schlüssel verlässt das Gerät nie — auch nicht über Google-Backups
 * oder Gerätewechsel. Ohne ihn ist die Datenbank nicht lesbar.
 */
class DatabaseKeyChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val NAME = "mai/db_key"
        private const val ALIAS = "mai_fitness_db_wrap"
        private const val FILE = "db.key"

        /** Schlüssel endgültig verloren — Datenbank ist nicht mehr lesbar. */
        const val KEY_LOST = "KEY_LOST"

        /** Vorübergehender Fehler (I/O, Keystore belegt) — nichts verwerfen. */
        const val KEY_UNAVAILABLE = "KEY_UNAVAILABLE"
    }

    /** Endgültiger Verlust; alles andere gilt als vorübergehend. */
    private class KeyLostException(message: String, cause: Throwable? = null) :
        Exception(message, cause)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getOrCreate" -> try {
                result.success(getOrCreate())
            } catch (e: KeyLostException) {
                result.error(KEY_LOST, e.message, null)
            } catch (e: Exception) {
                result.error(KEY_UNAVAILABLE, e.message, null)
            }
            // Nur wenn die Datenbank ohnehin unlesbar ist (Keystore verloren).
            // Die alte Schlüsseldatei wird nicht gelöscht, sondern umbenannt —
            // falls der Verlust doch nicht endgültig war, bleibt die
            // beiseitegelegte Datenbank so später wiederherstellbar.
            "reset" -> try {
                reset()
                result.success(null)
            } catch (e: Exception) {
                result.error(KEY_UNAVAILABLE, e.message, null)
            }
            else -> result.notImplemented()
        }
    }

    @Synchronized
    private fun reset() {
        val dir = context.noBackupFilesDir
        File(dir, "$FILE.tmp").delete()
        val file = File(dir, FILE)
        if (!file.exists()) return
        val backup = File(dir, "$FILE.${System.currentTimeMillis()}.bak")
        if (!file.renameTo(backup)) {
            throw IllegalStateException("Schlüssel nicht gesichert")
        }
    }

    @Synchronized
    private fun getOrCreate(): String {
        val file = File(context.noBackupFilesDir, FILE)
        if (file.exists()) {
            val stored = file.readBytes()
            // IV (12) + Schlüssel (32) + Tag (16). Andere Länge = abgeschnittene
            // Datei, der Schlüssel ist nicht mehr rekonstruierbar.
            if (stored.size != 12 + 32 + 16) {
                throw KeyLostException("Schlüsseldatei beschädigt (${stored.size} Bytes)")
            }
            val wrap = wrappingKey(create = false)
                ?: throw KeyLostException("Keystore-Schlüssel fehlt")
            val cipher = Cipher.getInstance("AES/GCM/NoPadding")
            try {
                cipher.init(Cipher.DECRYPT_MODE, wrap, GCMParameterSpec(128, stored, 0, 12))
                return cipher.doFinal(stored, 12, stored.size - 12).toHex()
            } catch (e: KeyPermanentlyInvalidatedException) {
                throw KeyLostException("Keystore-Schlüssel ungültig", e)
            } catch (e: AEADBadTagException) {
                throw KeyLostException("Schlüsseldatei passt nicht zum Keystore", e)
            }
        }
        val key = ByteArray(32).also { SecureRandom().nextBytes(it) }
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, wrappingKey(create = true)!!)
        val sealed = cipher.iv + cipher.doFinal(key)
        // Erst vollständig auf den Datenträger, dann atomar umbenennen — sonst
        // kann ein Absturz eine leere oder halbe db.key hinterlassen.
        val tmp = File(context.noBackupFilesDir, "$FILE.tmp")
        FileOutputStream(tmp).use { out ->
            out.write(sealed)
            out.flush()
            out.fd.sync()
        }
        if (!tmp.renameTo(file)) throw IllegalStateException("Schlüssel nicht gespeichert")
        return key.toHex()
    }

    /** `null` nur, wenn der Alias im Keystore tatsächlich fehlt (`create = false`). */
    private fun wrappingKey(create: Boolean): SecretKey? {
        val store = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (store.getKey(ALIAS, null) as? SecretKey)?.let { return it }
        // Alias vorhanden, aber kein SecretKey lesbar → nicht als Verlust werten.
        if (store.containsAlias(ALIAS)) throw IllegalStateException("Keystore-Schlüssel nicht lesbar")
        if (!create) return null
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    private fun ByteArray.toHex() = joinToString("") { "%02x".format(it) }
}
