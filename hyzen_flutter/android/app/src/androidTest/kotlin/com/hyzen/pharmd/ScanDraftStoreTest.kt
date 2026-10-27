package com.hyzen.pharmd

import android.graphics.Bitmap
import android.graphics.Color
import android.content.pm.PackageManager
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Before
import org.junit.After
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class ScanDraftStoreTest {
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext
    @Before fun reset() { ScanDraftStore(context).clear() }
    @After fun clear() { ScanDraftStore(context).clear() }
    private fun image(file: File, color: Int = Color.WHITE) {
        val bitmap = Bitmap.createBitmap(500, 700, Bitmap.Config.ARGB_8888)
        bitmap.eraseColor(color)
        file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.JPEG, 88, it) }
        bitmap.recycle()
    }
    @Test fun processRecreationRecoversFullSizeCaptureAndPreviousPages() {
        val original = ScanDraftStore(context)
        val first = original.newCapture(); image(first); original.finishCapture(true)
        val second = original.newCapture(); image(second, Color.BLUE)
        // New instance simulates losing all pending MethodChannel results.
        val recreated = ScanDraftStore(context)
        assertTrue(recreated.needsRecovery())
        assertEquals(2, recreated.recover().size)
        assertEquals(2, ScanDraftStore(context).recover().size)
        recreated.acknowledge(); assertFalse(recreated.needsRecovery())
    }
    @Test fun cancelledCameraKeepsPreviouslyCapturedPages() {
        val store = ScanDraftStore(context)
        image(store.newCapture()); store.finishCapture(true)
        val pending = store.newCapture()
        assertEquals(1, store.finishCapture(false).size)
        assertFalse(pending.exists())
        assertEquals(1, ScanDraftStore(context).pages().size)
    }
    @Test fun croppedFilteredPagesPersistWithoutChangingOtherPagesOrGalleryOriginals() {
        val gallery = File.createTempFile("original_scan_", ".jpg", context.cacheDir)
        try {
            image(gallery, Color.BLUE)
            val original = gallery.readBytes()
            val store = ScanDraftStore(context)
            val draft = store.add(listOf(gallery.path, gallery.path))
            val untouched = File(draft[1]).readBytes()
            val edited = store.edit(listOf(draft[0]), "gray", listOf(.1, .1, .9, .9))
            assertEquals(2, edited.size)
            assertFalse(File(draft[0]).exists())
            val bitmap = android.graphics.BitmapFactory.decodeFile(edited[0])
            assertEquals(400, bitmap.width); assertEquals(560, bitmap.height)
            val pixel = bitmap.getPixel(100,100)
            assertTrue(kotlin.math.abs(Color.red(pixel)-Color.green(pixel)) <= 2)
            bitmap.recycle()
            assertArrayEquals(untouched, File(edited[1]).readBytes())
            assertArrayEquals(original, gallery.readBytes())
            assertEquals(edited, ScanDraftStore(context).recover())
        } finally { gallery.delete() }
    }
    @Test fun rejectedBatchEditKeepsEveryEarlierPage() {
        val store = ScanDraftStore(context)
        image(store.newCapture()); val before = store.finishCapture(true)
        try { store.edit(before + "/not/a/draft.jpg", "gray", null); fail("Must reject outside path") }
        catch (_: IllegalArgumentException) { }
        assertEquals(before, store.pages()); assertTrue(File(before[0]).isFile)
    }
    @Test fun reorderRotateAndDeleteOnlyTouchDraftCopies() {
        val store = ScanDraftStore(context)
        val source = File.createTempFile("source_", ".jpg", context.cacheDir)
        try {
            image(source); val checksum = source.readBytes().contentHashCode()
            val pages = store.add(listOf(source.path, source.path))
            assertEquals(pages.reversed(), store.replace(pages.reversed()))
            val rotated = store.rotate(pages[1]); assertEquals(2, rotated.size)
            val bitmap = StudioImages.load(rotated[0]); assertTrue(bitmap.width > bitmap.height); bitmap.recycle()
            store.replace(listOf(rotated[0])); assertFalse(File(rotated[1]).exists())
            store.clear(); assertTrue(source.exists()); assertEquals(checksum, source.readBytes().contentHashCode())
        } finally { source.delete() }
    }
    @Test fun brokenNewCaptureDoesNotEraseEarlierDraft() {
        val store = ScanDraftStore(context)
        image(store.newCapture()); store.finishCapture(true)
        val broken = store.newCapture(); broken.writeText("Not an image")
        try { store.finishCapture(true); fail("Invalid image accepted") } catch (_: IllegalArgumentException) {}
        assertEquals(1, ScanDraftStore(context).recover().size)
    }
    @Test fun multipageScanSavesAReadablePdfWithoutChangingImages() {
        val source = File.createTempFile("pages_", ".jpg", context.cacheDir)
        var output: String? = null
        try {
            image(source)
            val checksum = source.readBytes().contentHashCode()
            output = StudioDocumentOps(context).imagesToPdf(List(20) { source.path })
            android.os.ParcelFileDescriptor.open(File(output), android.os.ParcelFileDescriptor.MODE_READ_ONLY).use { fd ->
                android.graphics.pdf.PdfRenderer(fd).use { renderer -> assertEquals(20, renderer.pageCount) }
            }
            assertEquals(checksum, source.readBytes().contentHashCode())
        } finally { source.delete(); output?.let { File(it).delete() } }
    }
    @Suppress("DEPRECATION")
    @Test fun contentIntentsDoNotBecomeFlutterDeepLinkRoutes() {
        val activity = context.packageManager.getActivityInfo(android.content.ComponentName(context, MainActivity::class.java), PackageManager.GET_META_DATA)
        assertTrue(activity.metaData.containsKey("flutter_deeplinking_enabled"))
        assertFalse(activity.metaData.getBoolean("flutter_deeplinking_enabled", true))
        // Prepare one real file for the signed release's cold/warm intent smoke test.
        val folder = File(context.cacheDir, "hyzen_shares").apply { mkdirs() }
        val pdf = android.graphics.pdf.PdfDocument()
        val page = pdf.startPage(android.graphics.pdf.PdfDocument.PageInfo.Builder(400, 600, 1).create())
        page.canvas.drawColor(Color.WHITE)
        pdf.finishPage(page)
        File(folder, "external_fixture.pdf").outputStream().use { pdf.writeTo(it) }; pdf.close()
    }
}
