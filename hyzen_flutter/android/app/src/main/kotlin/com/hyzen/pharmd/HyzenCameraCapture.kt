package com.hyzen.pharmd

import android.app.Activity
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Matrix
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import java.io.File
import java.util.concurrent.Executors

/** Durable, bounded page draft. Never depends on a live Dart MethodChannel.Result
 * while Android's camera owns the foreground (the OS may kill our process). */
class ScanDraftStore(private val context: Context) {
    private val prefs = context.getSharedPreferences("hyzen_scan_draft", Context.MODE_PRIVATE)
    val folder = File(context.filesDir, "scan_draft").apply { mkdirs() }
    fun pages(): List<String> {
        val raw = JSONArray(prefs.getString("pages", "[]"))
        return (0 until raw.length()).map { raw.getString(it) }.filter { valid(it) }
    }
    private fun valid(path: String): Boolean = File(path).let { it.canonicalFile.parentFile == folder.canonicalFile && it.isFile && it.length() > 0 }
    fun newCapture(): File {
        require(pages().size < 30) { "Save these 30 pages before scanning more." }
        val output = File.createTempFile("camera_", ".jpg", folder)
        check(prefs.edit().putString("cameraPath", output.path).putBoolean("recover", true).commit())
        return output
    }
    fun finishCapture(ok: Boolean): List<String> {
        val source = prefs.getString("cameraPath", null)?.let { File(it) }
        if (ok && source != null && valid(source.path)) {
            try { add(listOf(source.path)) } finally { source.delete() }
        } else source?.takeIf { it.canonicalFile.parentFile == folder.canonicalFile }?.delete()
        prefs.edit().remove("cameraPath").commit()
        return pages()
    }
    fun add(paths: List<String>): List<String> {
        val current = pages().toMutableList()
        require(current.size + paths.size <= 30) { "Choose up to 30 pages per PDF." }
        val created = mutableListOf<File>()
        try {
            for (path in paths) {
                val file = File(path).canonicalFile
                require(file.path.startsWith(context.filesDir.canonicalPath + "/") || file.path.startsWith(context.cacheDir.canonicalPath + "/")) { "Choose a local image." }
                require(file.length() in 1..(40L * 1024 * 1024)) { "Choose an image under 40 MB." }
                val bitmap = StudioImages.load(file.path, 1800)
                try {
                    val output = File.createTempFile("page_", ".jpg", folder)
                    created.add(output)
                    output.outputStream().use { check(bitmap.compress(Bitmap.CompressFormat.JPEG, 88, it)) }
                    current.add(output.path)
                } finally { bitmap.recycle() }
            }
            save(current)
            return current
        } catch (e: Throwable) { created.forEach { it.delete() }; throw e }
    }
    fun replace(paths: List<String>): List<String> {
        val current = pages()
        require(paths.size <= 30 && paths.distinct().size == paths.size && paths.all { it in current })
        save(paths)
        current.filter { it !in paths }.forEach { File(it).delete() }
        return paths
    }
    fun rotate(path: String): List<String> {
        val current = pages(); require(path in current)
        val source = StudioImages.load(path, 1800)
        val turned = Bitmap.createBitmap(source, 0, 0, source.width, source.height, Matrix().apply { postRotate(90f) }, true)
        val output = File.createTempFile("page_", ".jpg", folder)
        try {
            output.outputStream().use { check(turned.compress(Bitmap.CompressFormat.JPEG, 88, it)) }
            save(current.map { if (it == path) output.path else it }); File(path).delete()
        } catch (e: Exception) { output.delete(); throw e }
        finally { if (turned !== source) turned.recycle(); source.recycle() }
        return pages()
    }
    private fun save(paths: List<String>) { check(prefs.edit().putString("pages", JSONArray(paths).toString()).commit()) }
    fun beginScan() { check(prefs.edit().putBoolean("recover", true).commit()) }
    /** Transactional edits touch only app-owned draft copies. Processing is
     * bounded to one page at a time and commits the new order only on success. */
    fun edit(paths: List<String>, filter: String, crop: List<Double>?): List<String> {
        val current = pages()
        require(paths.isNotEmpty() && paths.distinct().size == paths.size && paths.all { it in current })
        require(filter in setOf("original", "gray", "contrast", "bw"))
        val replacements = mutableMapOf<String, String>()
        val created = mutableListOf<File>()
        try {
            for (path in paths) {
                val source = StudioImages.load(path, 1800)
                var region = source
                var outputBitmap: Bitmap? = null
                try {
                    if (crop != null) {
                        require(crop.size == 4 && crop.all { it.isFinite() && it in 0.0..1.0 })
                        val left = (crop[0] * source.width).toInt().coerceIn(0, source.width - 1)
                        val top = (crop[1] * source.height).toInt().coerceIn(0, source.height - 1)
                        val right = (crop[2] * source.width).toInt().coerceIn(left + 1, source.width)
                        val bottom = (crop[3] * source.height).toInt().coerceIn(top + 1, source.height)
                        region = Bitmap.createBitmap(source, left, top, right-left, bottom-top)
                    }
                    val output = Bitmap.createBitmap(region.width, region.height, Bitmap.Config.ARGB_8888)
                    outputBitmap = output
                    val color = ColorMatrix()
                    if (filter == "gray" || filter == "bw") color.setSaturation(0f)
                    if (filter == "contrast" || filter == "bw") {
                        val factor = if (filter == "bw") 3.5f else 1.35f
                        val offset = 128f * (1f - factor)
                        color.postConcat(ColorMatrix(floatArrayOf(factor,0f,0f,0f,offset,0f,factor,0f,0f,offset,0f,0f,factor,0f,offset,0f,0f,0f,1f,0f)))
                    }
                    Canvas(output).drawBitmap(region, 0f, 0f, Paint(Paint.ANTI_ALIAS_FLAG).apply { colorFilter = ColorMatrixColorFilter(color) })
                    val file = File.createTempFile("edited_", ".jpg", folder); created.add(file)
                    file.outputStream().use { check(output.compress(Bitmap.CompressFormat.JPEG, 90, it)) }
                    replacements[path] = file.path
                } finally { outputBitmap?.recycle(); if (region !== source) region.recycle(); source.recycle() }
            }
            val next = current.map { replacements[it] ?: it }
            save(next)
            paths.forEach { File(it).delete() }
            return next
        } catch (e: Throwable) { created.forEach { it.delete() }; throw e }
    }
    fun needsRecovery(): Boolean = prefs.getBoolean("recover", false)
    fun acknowledge() { prefs.edit().putBoolean("recover", false).commit() }
    fun recover(): List<String> {
        if (prefs.contains("cameraPath")) finishCapture(true)
        return pages()
    }
    fun clear() {
        pages().forEach { File(it).delete() }
        prefs.getString("cameraPath", null)?.let { File(it).takeIf { f -> f.parentFile == folder }?.delete() }
        prefs.edit().clear().commit()
    }
}

/** Uses the installed camera app, without an app camera permission or a heavy
 * Play-services scanning Activity. Each confirmed capture appends one page. */
class HyzenCameraCapture(private val activity: MainActivity, messenger: BinaryMessenger) {
    private val store = ScanDraftStore(activity)
    private val worker = Executors.newSingleThreadExecutor()
    private val channel = MethodChannel(messenger, "com.hyzen.pharmd/camera_pages")
    private var pending: MethodChannel.Result? = null
    private var busy = false
    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method == "capture") {
                if (pending != null || busy) { result.error("busy", "Finish this page first.", null); return@setMethodCallHandler }
                try {
                    val file = store.newCapture()
                    val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.updates", file)
                    val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
                        putExtra(MediaStore.EXTRA_OUTPUT, uri)
                        clipData = ClipData.newRawUri("Scan page", uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                    }
                    pending = result
                    activity.startActivityForResult(intent, REQUEST)
                } catch (_: Exception) {
                    store.finishCapture(false); store.acknowledge(); pending = null
                    result.error("camera", "Camera unavailable. Choose gallery images instead.", null)
                }
                return@setMethodCallHandler
            }
            if (busy) { result.error("busy", "Preparing your page…", null); return@setMethodCallHandler }
            busy = true
            worker.execute {
                try {
                    val answer: Any = when (call.method) {
                        "needsRecovery" -> store.needsRecovery() && pending == null
                        "recover" -> store.recover().also { store.acknowledge() }
                        "addImages" -> store.add(call.argument<List<String>>("paths") ?: emptyList())
                        "replace" -> store.replace(call.argument<List<String>>("paths") ?: emptyList())
                        "rotate" -> store.rotate(call.argument<String>("path") ?: "")
                        "edit" -> store.edit(call.argument<List<String>>("paths") ?: emptyList(), call.argument<String>("filter") ?: "original", call.argument<List<Double>>("crop"))
                        "clear" -> { store.clear(); true }
                        else -> { activity.runOnUiThread { busy = false; result.notImplemented() }; return@execute }
                    }
                    activity.runOnUiThread { busy = false; result.success(answer) }
                } catch (e: Throwable) {
                    activity.runOnUiThread { busy = false; result.error("scan_page", "Could not prepare this page. Try a smaller image.", null) }
                }
            }
        }
    }
    fun receive(code: Int, resultCode: Int): Boolean {
        if (code != REQUEST) return false
        val result = pending; pending = null; busy = true
        worker.execute {
            try {
                val pages = store.finishCapture(resultCode == Activity.RESULT_OK)
                if (result != null) store.acknowledge()
                activity.runOnUiThread { busy = false; result?.success(pages); channel.invokeMethod("draftReady", null) }
            } catch (_: Throwable) {
                activity.runOnUiThread { busy = false; result?.error("capture", "Could not add this page. Your earlier pages are safe.", null) }
            }
        }
        return true
    }
    fun close() { pending = null; worker.shutdown() }
    companion object { const val REQUEST = 8892 }
}
