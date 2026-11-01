package com.hyzen.pharmd

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.PDPage
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream
import com.tom_roush.pdfbox.pdmodel.font.PDType1Font
import com.tom_roush.pdfbox.text.PDFTextStripper
import com.tom_roush.pdfbox.pdmodel.encryption.InvalidPasswordException
import org.junit.Assert.*
import org.junit.Test
import org.junit.Before
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class StudioDocumentOpsTest {
    private val context get() = InstrumentationRegistry.getInstrumentation().targetContext
    @Before fun initializePdfResourcesBeforeAnyReaderOrFontClassLoads() {
        PDFBoxResourceLoader.init(context)
    }
    private fun input(): File {
        PDFBoxResourceLoader.init(context)
        val file = File.createTempFile("hyzen_fixture_", ".pdf", context.cacheDir)
        PDDocument().use { doc ->
            repeat(2) { index ->
                val page = PDPage(); doc.addPage(page)
                PDPageContentStream(doc,page).use { stream ->
                    stream.beginText();stream.setFont(PDType1Font.HELVETICA,18f);stream.newLineAtOffset(50f,700f)
                    stream.showText("HYZEN pharmacy page ${index+1}");stream.endText()
                }
            }
            doc.save(file)
        }
        return file
    }
    @Test fun reorderExtractAndRotatePreserveSelectableText() {
        val original=input(); val checksum=original.readBytes().contentHashCode()
        val path=StudioDocumentOps(context).compose(listOf(
            mapOf("path" to original.path,"page" to 1,"rotation" to 90),
            mapOf("path" to original.path,"page" to 0,"rotation" to 0)))
        try {
            PDDocument.load(File(path)).use { doc ->
                assertEquals(2,doc.numberOfPages);assertEquals(90,doc.getPage(0).rotation)
                val text=PDFTextStripper().getText(doc)
                assertTrue(text.indexOf("page 2") < text.indexOf("page 1"))
            }
            assertEquals(checksum,original.readBytes().contentHashCode())
        } finally { original.delete();File(path).delete() }
    }
    @Test fun annotationsRemainSeparateFromPageText() {
        val original=input()
        val path=StudioDocumentOps(context).compose(listOf(mapOf("path" to original.path,"page" to 0,"annotations" to listOf(
            mapOf("tool" to "highlight","points" to listOf(listOf(.1,.2),listOf(.5,.2)),"color" to 0xFFFFFF00L,"stroke" to 3),
            mapOf("tool" to "ink","points" to listOf(listOf(.2,.3),listOf(.4,.5)),"stroke" to 2)))))
        try {
            PDDocument.load(File(path)).use { doc ->
                assertTrue(PDFTextStripper().getText(doc).contains("HYZEN"))
                val marks=doc.getPage(0).annotations
                assertEquals(2,marks.size);assertEquals("Highlight",marks[0].subtype);assertEquals("Ink",marks[1].subtype)
                assertNotNull(marks[0].appearance);assertNotNull(marks[1].appearance)
            }
        } finally { original.delete();File(path).delete() }
    }
    @Test fun aesProtectedCopyRequiresPasswordAndLeavesOriginalReadable() {
        val original=input();val path=StudioDocumentOps(context).protect(original.path,"Fixture-Password-8")
        try {
            var rejected=false
            try { PDDocument.load(File(path)).close() } catch(_:InvalidPasswordException) { rejected=true }
            assertTrue(rejected)
            PDDocument.load(File(path),"Fixture-Password-8").use { doc ->
                assertEquals(2,doc.numberOfPages);assertTrue(doc.isEncrypted)
                assertTrue(PDFTextStripper().getText(doc).contains("pharmacy"))
            }
            PDDocument.load(original).use { assertFalse(it.isEncrypted) }
        } finally { original.delete();File(path).delete() }
    }
    @Test fun compressionPreservesTextAndDoesNotGrowTheCopy() {
        val original=input();val path=StudioDocumentOps(context).compress(original.path,"small")
        try {
            assertTrue(File(path).length()<=original.length())
            PDDocument.load(File(path)).use { assertTrue(PDFTextStripper().getText(it).contains("HYZEN")) }
        } finally { if(path!=original.path)File(path).delete();original.delete() }
    }
    @Test fun scannedImageBecomesSearchableOnDevice() {
        PDFBoxResourceLoader.init(context)
        val file=File.createTempFile("hyzen_scan_fixture_", ".pdf", context.cacheDir)
        val bitmap=android.graphics.Bitmap.createBitmap(1000,1400,android.graphics.Bitmap.Config.ARGB_8888)
        bitmap.eraseColor(android.graphics.Color.WHITE)
        val paint=android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG).apply {color=android.graphics.Color.BLACK;textSize=65f}
        android.graphics.Canvas(bitmap).drawText("HYZEN PHARMACY",80f,250f,paint)
        PDDocument().use { doc ->
            val page=PDPage();doc.addPage(page)
            PDPageContentStream(doc,page).use { it.drawImage(com.tom_roush.pdfbox.pdmodel.graphics.image.JPEGFactory.createFromImage(doc,bitmap),0f,0f,page.mediaBox.width,page.mediaBox.height) }
            doc.save(file)
        };bitmap.recycle()
        var output:String?=null
        try {
            val result=StudioDocumentOps(context).ocr(file.path);output=result["path"] as String
            assertTrue((result["text"] as String).uppercase().contains("PHARMACY"))
            PDDocument.load(File(output)).use { assertTrue(PDFTextStripper().getText(it).uppercase().contains("PHARMACY")) }
        } finally { file.delete();output?.let{File(it).delete()} }
    }
    @Test fun structuredWriterExportsFormattingTablesAndPdfText() {
        val blocks=listOf(mapOf("type" to "heading","text" to "Pharmacy notes","bold" to true),
            mapOf("type" to "paragraph","text" to "HYZEN study notes","italic" to true),
            mapOf("type" to "table","text" to "Medicine|Dose\nAspirin|75 mg"))
        val pdf=StudioRichWriter(context).write(blocks,"pdf")
        val word=StudioRichWriter(context).write(blocks,"docx")
        try {
            PDDocument.load(File(pdf)).use{assertTrue(PDFTextStripper().getText(it).contains("Pharmacy notes"))}
            java.util.zip.ZipFile(word).use{zip->
                val xml=zip.getInputStream(zip.getEntry("word/document.xml")).bufferedReader().readText()
                assertTrue(xml.contains("<w:tbl>"));assertTrue(xml.contains("<w:b/>"));assertTrue(xml.contains("<w:i/>"))
                val parser=javax.xml.parsers.DocumentBuilderFactory.newInstance().newDocumentBuilder()
                parser.parse(java.io.ByteArrayInputStream(xml.toByteArray()))
            }
        }finally{File(pdf).delete();File(word).delete()}
    }
    @Test fun galleryImageRespectsPhoneExifRotation() {
        val file=File.createTempFile("hyzen_photo_fixture_",".jpg",context.cacheDir)
        val bitmap=android.graphics.Bitmap.createBitmap(120,240,android.graphics.Bitmap.Config.ARGB_8888)
        file.outputStream().use{bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG,90,it)};bitmap.recycle()
        val exif=android.media.ExifInterface(file.path);exif.setAttribute(android.media.ExifInterface.TAG_ORIENTATION,"6");exif.saveAttributes()
        try {val oriented=StudioImages.load(file.path);try{assertEquals(240,oriented.width);assertEquals(120,oriented.height)}finally{oriented.recycle()}}
        finally{file.delete()}
    }
}
