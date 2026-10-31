package com.hyzen.pharmd

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.cos.COSName
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.pdmodel.PDPage
import com.tom_roush.pdfbox.pdmodel.PDPageContentStream
import com.tom_roush.pdfbox.pdmodel.common.PDRectangle
import com.tom_roush.pdfbox.io.MemoryUsageSetting
import com.tom_roush.pdfbox.pdmodel.graphics.image.JPEGFactory
import com.tom_roush.pdfbox.pdmodel.encryption.AccessPermission
import com.tom_roush.pdfbox.pdmodel.encryption.StandardProtectionPolicy
import com.tom_roush.pdfbox.pdmodel.font.PDType0Font
import com.tom_roush.pdfbox.pdmodel.graphics.color.PDColor
import com.tom_roush.pdfbox.pdmodel.graphics.color.PDDeviceRGB
import com.tom_roush.pdfbox.pdmodel.graphics.state.RenderingMode
import com.tom_roush.pdfbox.pdmodel.interactive.annotation.*
import java.io.File
import java.util.UUID
import java.util.concurrent.TimeUnit

/** Lossless page operations. Source files are read only; every result is new. */
class StudioDocumentOps(private val context: Context) {
    init { PDFBoxResourceLoader.init(context.applicationContext) }
    private fun output() = File.createTempFile("hyzen_document_", ".pdf", context.cacheDir)

    /** Compressed PDF streams spill to app cache; never retain thirty decoded
     * full-size camera bitmaps in an Android Canvas/PdfDocument display list. */
    fun imagesToPdf(paths: List<String>): String {
        require(paths.isNotEmpty() && paths.size <= 30) { "Choose 1–30 pages." }
        val target = output()
        try {
            PDDocument(MemoryUsageSetting.setupTempFileOnly().setTempDir(context.cacheDir)).use { document ->
                for (path in paths) {
                    val bitmap = StudioImages.load(path, 1800)
                    try {
                        val bounds = if (bitmap.height >= bitmap.width) PDRectangle.A4 else PDRectangle(PDRectangle.A4.height, PDRectangle.A4.width)
                        val page = PDPage(bounds); document.addPage(page)
                        val image = JPEGFactory.createFromImage(document, bitmap, .88f)
                        val factor = minOf((bounds.width - 32f) / bitmap.width, (bounds.height - 32f) / bitmap.height)
                        val width = bitmap.width * factor; val height = bitmap.height * factor
                        PDPageContentStream(document, page).use { stream ->
                            stream.drawImage(image, (bounds.width - width) / 2, (bounds.height - height) / 2, width, height)
                        }
                    } finally { bitmap.recycle() }
                }
                document.save(target)
            }
            return target.path
        } catch (e: Throwable) { target.delete(); throw e }
    }

    fun compose(pages: List<Map<String, Any?>>): String {
        require(pages.isNotEmpty() && pages.size <= 150) { "Select 1–150 pages." }
        val sources = mutableMapOf<String, PDDocument>()
        val target = output()
        try {
            PDDocument().use { document ->
                for (spec in pages) {
                    if (spec["blank"] == true) { document.addPage(PDPage(PDRectangle.A4)); continue }
                    val source = sources.getOrPut(spec["path"] as String) { PDDocument.load(File(spec["path"] as String)) }
                    require(source.currentAccessPermission.canAssembleDocument()) { "Page changes are not permitted for this PDF." }
                    val index = (spec["page"] as Number).toInt()
                    require(index in 0 until source.numberOfPages)
                    val original = source.getPage(index)
                    val page = document.importPage(original)
                    page.resources = original.resources
                    val rotation = (spec["rotation"] as? Number)?.toInt() ?: 0
                    require(rotation in listOf(0, 90, 180, 270))
                    page.rotation = (original.rotation + rotation) % 360
                    @Suppress("UNCHECKED_CAST")
                    val marks = spec["annotations"] as? List<Map<String, Any?>> ?: emptyList()
                    addAnnotations(document, page, marks)
                }
                document.save(target)
            }
            return target.absolutePath
        } catch (e: Exception) { target.delete(); throw e }
        finally { sources.values.forEach { it.close() } }
    }

    private fun point(page: PDPage, x: Float, y: Float): Pair<Float, Float> {
        val r = page.cropBox
        val u = x.coerceIn(0f, 1f); val v = y.coerceIn(0f, 1f)
        val p = when ((page.rotation % 360 + 360) % 360) {
            90 -> v * r.width to u * r.height
            180 -> (1-u) * r.width to v * r.height
            270 -> (1-v) * r.width to (1-u) * r.height
            else -> u * r.width to (1-v) * r.height
        }
        return p.first + r.lowerLeftX to p.second + r.lowerLeftY
    }

    private fun addAnnotations(doc: PDDocument, page: PDPage, marks: List<Map<String, Any?>>) {
        val annotations = page.annotations.toMutableList()
        for (mark in marks.take(200)) {
            val type = mark["tool"] as? String ?: continue
            val points = (mark["points"] as? List<*>)?.mapNotNull { raw ->
                val p = raw as? List<*> ?: return@mapNotNull null
                val x = (p.getOrNull(0) as? Number)?.toFloat() ?: return@mapNotNull null
                val y = (p.getOrNull(1) as? Number)?.toFloat() ?: return@mapNotNull null
                if (!x.isFinite() || !y.isFinite()) null else point(page, x, y)
            } ?: continue
            if (points.isEmpty()) continue
            val stroke = ((mark["stroke"] as? Number)?.toFloat() ?: 3f).coerceIn(1f, 32f)
            val first = points.first(); val last = points.last()
            val left = points.minOf { it.first }; val right = points.maxOf { it.first }
            val bottom = points.minOf { it.second }; val top = points.maxOf { it.second }
            val markBounds = PDRectangle(left-stroke, bottom-stroke, maxOf(2f, right-left)+stroke*2, maxOf(2f, top-bottom)+stroke*2)
            val annotation: PDAnnotationMarkup = when (type) {
                "highlight", "underline", "strike" -> PDAnnotationTextMarkup(when(type) {
                    "highlight" -> "Highlight"; "underline" -> "Underline"; else -> "StrikeOut"
                }).apply {
                    val h = if (type == "highlight") stroke*2.5f else stroke
                    markBounds.lowerLeftY = bottom-h; markBounds.upperRightY = top+h
                    quadPoints = floatArrayOf(left, top+h, right, top+h, left, bottom-h, right, bottom-h)
                }
                "rectangle", "circle" -> PDAnnotationSquareCircle(if(type=="circle") "Circle" else "Square")
                "note" -> PDAnnotationText().apply {
                    contents = (mark["text"] as? String ?: "").take(2000)
                    name = if (type == "note") "Comment" else "Note"
                }
                "text", "signature" -> PDAnnotationMarkup().apply {
                    cosObject.setName(COSName.SUBTYPE,"FreeText")
                    contents=(mark["text"] as? String ?: "").take(2000)
                    defaultAppearance="/Helv 14 Tf 0 0 0 rg"
                }
                "arrow" -> PDAnnotationLine().apply {
                    line = floatArrayOf(first.first,first.second,last.first,last.second)
                    endPointEndingStyle = "OpenArrow"
                }
                else -> PDAnnotationMarkup().apply {
                    cosObject.setName(COSName.SUBTYPE, "Ink")
                    inkList = arrayOf(points.flatMap { listOf(it.first, it.second) }.toFloatArray())
                }
            }
            val color = (mark["color"] as? Number)?.toInt() ?: Color.rgb(109,53,212)
            annotation.color = PDColor(floatArrayOf(Color.red(color)/255f, Color.green(color)/255f, Color.blue(color)/255f), PDDeviceRGB.INSTANCE)
            annotation.rectangle = markBounds
            annotation.borderStyle = PDBorderStyleDictionary().apply { width = stroke }
            annotation.constantOpacity = if(type=="highlight") .35f else 1f
            annotation.annotationName = "Hyzen-${UUID.randomUUID()}"
            annotation.setPrinted(true)
            annotation.page = page
            if(type=="text" || type=="signature") {
                val font = if(type=="signature") com.tom_roush.pdfbox.pdmodel.font.PDType1Font.TIMES_ITALIC else com.tom_roush.pdfbox.pdmodel.font.PDType1Font.HELVETICA
                val label=annotation.contents.filter { c -> try { font.encode(c.toString());true }catch(_:Exception){false} }.take(300)
                val size=if(type=="signature")24f else 14f
                val w=maxOf(20f,font.getStringWidth(label)/1000f*size+8f)
                annotation.rectangle=PDRectangle(first.first,first.second-size*1.5f,w,size*1.8f)
                val appearance=PDAppearanceStream(doc).apply { resources=com.tom_roush.pdfbox.pdmodel.PDResources();bBox=PDRectangle(w,size*1.8f) }
                PDPageContentStream(doc,appearance).use { stream ->
                    stream.beginText();stream.setFont(font,size);stream.setNonStrokingColor(annotation.color)
                    stream.newLineAtOffset(2f, size*.4f);stream.showText(label);stream.endText()
                }
                annotation.appearance=PDAppearanceDictionary().apply{setNormalAppearance(appearance)}
            } else annotation.constructAppearances(doc)
            annotations.add(annotation)
        }
        page.annotations = annotations
    }

    fun protect(path: String, password: String): String {
        require(password.length in 6..128) { "Use a password with 6–128 characters." }
        val target = output()
        try {
            PDDocument.load(File(path)).use { doc ->
                val policy = StandardProtectionPolicy(UUID.randomUUID().toString(), password, AccessPermission())
                policy.encryptionKeyLength = 128
                policy.isPreferAES = true
                doc.protect(policy)
                doc.save(target)
            }
            return target.absolutePath
        } catch(e: Exception) { target.delete(); throw e }
    }

    fun compress(path: String, preset: String): String {
        val target = output()
        val limit = when(preset) { "small" -> 1000; "balanced" -> 1600; else -> 2200 }
        val quality = when(preset) { "small" -> .60f; "balanced" -> .78f; else -> .9f }
        try {
            PDDocument.load(File(path)).use { doc ->
                val visited = java.util.Collections.newSetFromMap(java.util.IdentityHashMap<com.tom_roush.pdfbox.cos.COSDictionary, Boolean>())
                fun shrink(resources: com.tom_roush.pdfbox.pdmodel.PDResources?, depth: Int) {
                    if (resources == null || depth > 8 || !visited.add(resources.cosObject)) return
                    for (name in resources.xObjectNames.toList()) {
                        val obj = resources.getXObject(name)
                        if (obj is com.tom_roush.pdfbox.pdmodel.graphics.form.PDFormXObject) shrink(obj.resources, depth+1)
                        if (obj !is com.tom_roush.pdfbox.pdmodel.graphics.image.PDImageXObject || obj.width.toLong()*obj.height > 16_000_000 || obj.width*obj.height < 250_000) continue
                        // Preserve optional JPEG-2000 resources unchanged. The
                        // viewer renders them, but this legacy codec is absent
                        // from PDFBox; compression must never drop those images.
                        if (obj.cosObject.getDictionaryObject(com.tom_roush.pdfbox.cos.COSName.FILTER)?.toString()?.contains("JPXDecode") == true) continue
                        val image = obj.image ?: continue
                        var scaled: Bitmap? = null
                        try {
                            val ratio = minOf(1f, limit.toFloat()/maxOf(image.width,image.height))
                            scaled = if (ratio < 1f) Bitmap.createScaledBitmap(image,maxOf(1,(image.width*ratio).toInt()),maxOf(1,(image.height*ratio).toInt()),true) else image
                            resources.put(name,com.tom_roush.pdfbox.pdmodel.graphics.image.JPEGFactory.createFromImage(doc,scaled,quality))
                        } finally { if(scaled !== image) scaled?.recycle() }
                    }
                }
                for (page in doc.pages) shrink(page.resources,0)
                doc.save(target)
            }
            if (target.length() >= File(path).length()) { target.delete(); return path }
            return target.absolutePath
        } catch(e: Exception) { target.delete(); throw e }
    }

    /** Bundled Latin recognition runs on-device; no document upload. */
    fun ocr(path: String): Map<String, Any> {
        val target = output()
        val text = StringBuilder()
        val pages = mutableListOf<String>()
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        try {
            PDDocument.load(File(path)).use { document ->
                require(document.currentAccessPermission.canExtractContent()) { "Text extraction is not permitted." }
                val font = context.assets.open("flutter_assets/assets/fonts/Manrope-400.ttf").use { PDType0Font.load(document, it) }
                ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY).use { fd ->
                    PdfRenderer(fd).use { renderer ->
                        require(renderer.pageCount in 1..50) { "OCR supports up to 50 pages at once." }
                        for (index in 0 until renderer.pageCount) {
                            renderer.openPage(index).use { page ->
                                val scale = minOf(2f, 1600f/maxOf(page.width,page.height))
                                val bitmap = Bitmap.createBitmap(maxOf(1,(page.width*scale).toInt()),maxOf(1,(page.height*scale).toInt()),Bitmap.Config.ARGB_8888)
                                try {
                                    bitmap.eraseColor(Color.WHITE); page.render(bitmap,null,null,PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                                    val result = Tasks.await(recognizer.process(InputImage.fromBitmap(bitmap,0)),45,TimeUnit.SECONDS)
                                    pages.add(result.text)
                                    text.append(result.text).append("\n\n")
                                    val pdfPage = document.getPage(index)
                                    // Avoid duplicate invisible text on a page which already has text.
                                    val stripper = com.tom_roush.pdfbox.text.PDFTextStripper().apply { startPage=index+1; endPage=index+1 }
                                    if (stripper.getText(document).isBlank()) {
                                        PDPageContentStream(document,pdfPage,PDPageContentStream.AppendMode.APPEND,true,true).use { stream ->
                                            stream.setRenderingMode(RenderingMode.NEITHER)
                                            for (block in result.textBlocks) for (line in block.lines) {
                                                val bounds = line.boundingBox ?: continue
                                                val safe = line.text.filter { c -> try { font.encode(c.toString()); true } catch(_: Exception) { false } }
                                                if (safe.isBlank()) continue
                                                val origin = point(pdfPage,bounds.left.toFloat()/bitmap.width,bounds.bottom.toFloat()/bitmap.height)
                                                val displayHeight = if(pdfPage.rotation%180==0) pdfPage.cropBox.height else pdfPage.cropBox.width
                                                val size = maxOf(4f, bounds.height().toFloat()/bitmap.height*displayHeight*.8f)
                                                stream.beginText(); stream.setFont(font,size)
                                                stream.setTextMatrix(com.tom_roush.pdfbox.util.Matrix.getRotateInstance(Math.toRadians(pdfPage.rotation.toDouble()),origin.first,origin.second))
                                                stream.showText(safe); stream.endText()
                                            }
                                        }
                                    }
                                } finally { bitmap.recycle() }
                            }
                        }
                    }
                }
                document.save(target)
            }
            return mapOf("path" to target.absolutePath, "text" to text.toString(), "pages" to pages)
        } catch(e: Exception) { target.delete(); throw e }
        finally { recognizer.close() }
    }
}
