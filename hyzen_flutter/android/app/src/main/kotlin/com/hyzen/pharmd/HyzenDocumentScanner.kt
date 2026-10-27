package com.hyzen.pharmd

import android.app.Activity
import android.content.Intent
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/** Google's native document viewfinder supplies auto/manual capture, page-edge
 * correction, cleanup and multi-page review. Only JPEG output is requested:
 * Hyzen composes the final PDF once, after its durable page review. */
class HyzenDocumentScanner(private val activity: MainActivity, messenger: BinaryMessenger) {
    private val store = ScanDraftStore(activity)
    private var pending: MethodChannel.Result? = null
    private var active = false
    private val worker = Executors.newSingleThreadExecutor()
    private val channel = MethodChannel(messenger, "com.hyzen.pharmd/document_scanner")
    private val cameraChannel = MethodChannel(messenger, "com.hyzen.pharmd/camera_pages")
    private val requestCode = 8891
    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method != "scan") { result.notImplemented(); return@setMethodCallHandler }
            if (active) { result.error("busy", "Finish the current scan first.", null); return@setMethodCallHandler }
            val available = 30 - store.pages().size
            if (available <= 0) { result.error("limit", "Save these 30 pages before scanning more.", null); return@setMethodCallHandler }
            pending = result
            active = true
            store.beginScan()
            val options = GmsDocumentScannerOptions.Builder()
                .setGalleryImportAllowed(true).setPageLimit(available)
                .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG)
                .setScannerMode(GmsDocumentScannerOptions.SCANNER_MODE_FULL).build()
            GmsDocumentScanning.getClient(options).getStartScanIntent(activity)
                .addOnSuccessListener { sender ->
                    if (active && !activity.isFinishing) {
                        try { activity.startIntentSenderForResult(sender, requestCode, null, 0, 0, 0) }
                        catch (_: Exception) { fail() }
                    }
                }.addOnFailureListener { fail() }
        }
    }
    private fun fail() {
        store.acknowledge()
        pending?.error("scanner_unavailable", "Document scanner is unavailable. Update Google Play services, or choose the basic camera / gallery.", null)
        pending = null; active = false
    }
    fun receive(code: Int, resultCode: Int, intent: Intent?): Boolean {
        if (code != requestCode) return false
        // Process results even when Android recreated this Activity and there
        // is no live MethodChannel callback to the previous Flutter isolate.
        val result = pending; pending = null
        if (resultCode != Activity.RESULT_OK) {
            active = false; store.acknowledge(); result?.success(store.pages()); return true
        }
        worker.execute {
            val staged = mutableListOf<File>()
            try {
                val pages = GmsDocumentScanningResult.fromActivityResultIntent(intent)?.pages
                    ?: error("No scanned pages returned")
                require(pages.isNotEmpty() && pages.size + store.pages().size <= 30)
                for (page in pages) {
                    val file = File.createTempFile("scan_result_", ".jpg", activity.cacheDir)
                    staged.add(file)
                    activity.contentResolver.openInputStream(page.imageUri)?.use { input ->
                        file.outputStream().use { output ->
                            val buffer = ByteArray(65536); var total = 0L
                            while (true) {
                                val n = input.read(buffer); if (n < 0) break
                                total += n; require(total <= 40L * 1024 * 1024)
                                output.write(buffer, 0, n)
                            }
                        }
                    } ?: error("Scan unavailable")
                }
                val saved = store.add(staged.map { it.path })
                // Keep recovery flag until the new Flutter screen reads it.
                activity.runOnUiThread {
                    active = false
                    result?.success(saved)
                    cameraChannel.invokeMethod("draftReady", null)
                }
            } catch (_: Throwable) {
                activity.runOnUiThread {
                    active = false
                    result?.error("scan", "Could not add scanned pages. Your earlier pages are safe.", null)
                    cameraChannel.invokeMethod("draftReady", null)
                }
            } finally { staged.forEach { it.delete() } }
        }
        return true
    }
    fun close() { pending = null; worker.shutdown() }
}
