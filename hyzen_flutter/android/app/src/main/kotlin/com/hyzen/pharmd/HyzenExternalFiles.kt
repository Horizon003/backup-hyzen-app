package com.hyzen.pharmd

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID
import java.security.MessageDigest
import java.util.concurrent.Executors

/** Receives one user-chosen document from another app, with a temporary URI grant. */
class HyzenExternalFiles(private val activity: MainActivity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "com.hyzen.pharmd/external_files")
    private val worker = Executors.newSingleThreadExecutor()
    private val pending = mutableListOf<Map<String, String>>()
    @Volatile private var importing = false

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isImporting" -> result.success(importing)
                "fingerprint" -> worker.execute {
                    try {
                        val file = File(call.argument<String>("path") ?: "").canonicalFile
                        require(file.path.startsWith(File(activity.applicationInfo.dataDir).canonicalPath + "/"))
                        val digest = MessageDigest.getInstance("SHA-256")
                        file.inputStream().use { input -> val b = ByteArray(65536); while (true) {
                            val n = input.read(b); if (n < 0) break; digest.update(b, 0, n)
                        } }
                        val hash = digest.digest().joinToString("") { "%02x".format(it) }
                        activity.runOnUiThread { result.success(hash) }
                    } catch (_: Exception) { activity.runOnUiThread { result.error("fingerprint", "File unavailable", null) } }
                }
                "takePending" -> synchronized(pending) {
                    val items = pending.toList()
                    pending.clear()
                    result.success(items)
                }
                "deleteImport" -> {
                    val path = call.argument<String>("path") ?: ""
                    val directory = File(activity.filesDir, "reader_imports").canonicalFile
                    val file = File(path).canonicalFile
                    if (file.parentFile != directory) result.error("path", "Invalid document path", null)
                    else result.success(!file.exists() || file.delete())
                }
                else -> result.notImplemented()
            }
        }
    }

    fun receive(intent: Intent?) {
        if (intent == null || intent.action !in listOf(Intent.ACTION_VIEW, Intent.ACTION_SEND)) return
        @Suppress("DEPRECATION")
        val uri: Uri = (if (intent.action == Intent.ACTION_VIEW) intent.data
            else intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)) ?: return
        if (uri.scheme != "content") return
        importing = true
        activity.runOnUiThread { channel.invokeMethod("incomingStarted", null) }
        worker.execute {
            try {
                val title = activity.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                    ?.use { if (it.moveToFirst()) it.getString(0) else null }
                    ?.take(150)?.replace(Regex("[\\p{Cntrl}/\\\\]"), "_") ?: "Imported document"
                val mime = activity.contentResolver.getType(uri) ?: intent.type ?: ""
                val folder = File(activity.filesDir, "reader_imports").apply { mkdirs() }
                val part = File(folder, "${UUID.randomUUID()}.part")
                val head = ByteArray(16)
                var headSize = 0
                var bytes = 0L
                val digest = MessageDigest.getInstance("SHA-256")
                try {
                    activity.contentResolver.openInputStream(uri)?.use { source ->
                        part.outputStream().use { target ->
                            val buffer = ByteArray(8192)
                            while (true) {
                                val count = source.read(buffer)
                                if (count < 0) break
                                bytes += count
                                require(bytes <= 250L * 1024 * 1024) { "File must be under 250 MB." }
                                val first = minOf(count, head.size - headSize)
                                if (first > 0) { buffer.copyInto(head, headSize, 0, first); headSize += first }
                                target.write(buffer, 0, count)
                                digest.update(buffer, 0, count)
                            }
                        }
                    } ?: error("The other app did not provide a readable file.")
                    val ext = when {
                        headSize >= 5 && head.copyOfRange(0, 5).contentEquals("%PDF-".toByteArray()) -> "pdf"
                        headSize >= 4 && head[0] == 0x50.toByte() && head[1] == 0x4b.toByte() -> "office"
                        headSize >= 8 && head[0] == 0x89.toByte() && head[1] == 0x50.toByte() && head[2] == 0x4e.toByte() -> "png"
                        headSize >= 3 && head[0] == 0xff.toByte() && head[1] == 0xd8.toByte() -> "jpg"
                        headSize >= 12 && String(head, 0, 4) == "RIFF" && String(head, 8, 4) == "WEBP" -> "webp"
                        headSize >= 8 && head[0] == 0xd0.toByte() && head[1] == 0xcf.toByte() -> "legacy"
                        mime.startsWith("text/") && bytes <= 2L * 1024 * 1024 &&
                            head.take(headSize).none { it == 0.toByte() } -> "txt"
                        else -> error("Open a PDF, image, PPT, PPTX, DOCX or XLSX file.")
                    }
                    require(ext !in listOf("office", "legacy") || bytes <= 50L * 1024 * 1024) {
                        "Office files must be under 50 MB."
                    }
                    val hash = digest.digest().joinToString("") { "%02x".format(it) }
                    val destination = File(folder, "$hash.$ext")
                    if (destination.exists()) part.delete()
                    else check(part.renameTo(destination)) { "Could not save the imported document." }
                    val item = mapOf("path" to destination.absolutePath, "title" to title,
                        "id" to destination.nameWithoutExtension)
                    synchronized(pending) { pending.add(item) }
                    importing = false
                    activity.runOnUiThread { channel.invokeMethod("incomingAvailable", null) }
                } finally { part.delete() }
            } catch (e: Exception) {
                importing = false
                val error = mapOf("error" to (e.message ?: "Could not open this document."))
                synchronized(pending) { pending.add(error) }
                activity.runOnUiThread { channel.invokeMethod("incomingAvailable", null) }
            }
        }
    }

    fun close() { worker.shutdown() }
}
