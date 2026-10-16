package com.hyzen.pharmd

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.ByteArrayOutputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import java.util.concurrent.Executors

/** Local PDF operations. Pages are rasterized so input documents are never modified. */
class StudioPdfEngine(private val activity: MainActivity, engine: FlutterEngine) {
    private val worker = Executors.newSingleThreadExecutor()

    init {
        MethodChannel(engine.dartExecutor.binaryMessenger, "com.hyzen.pharmd/pdf_studio")
            .setMethodCallHandler { call, result ->
                worker.execute {
                    try {
                        val answer: Any = when (call.method) {
                            "pageCount" -> {
                                val path = call.argument<String>("path") ?: error("Missing PDF path")
                                ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY).use { fd ->
                                    PdfRenderer(fd).use { it.pageCount }
                                }
                            }
                            "compose" -> {
                                val pages = call.argument<List<Map<String, Any?>>>("pages") ?: error("No pages selected")
                                compose(pages)
                            }
                            "imagesToPdf" -> {
                                val paths = call.argument<List<String>>("paths") ?: error("No images selected")
                                imagesToPdf(paths)
                            }
                            "textToPdf" -> textToPdf(call.argument<String>("text") ?: "")
                            "textToDocx" -> textToDocx(call.argument<String>("text") ?: "")
                            "textFile" -> {
                                File.createTempFile("studio_note_", ".txt", activity.cacheDir).apply {
                                    writeText(call.argument<String>("text") ?: "")
                                }.absolutePath
                            }
                            "readText" -> {
                                val source = File(call.argument<String>("path") ?: error("Missing document"))
                                require(source.length() <= 2_000_000L) { "Text file is too large." }
                                source.readText(Charsets.UTF_8)
                            }
                            "pagesToImages" -> pagesToImages(
                                call.argument<String>("path") ?: error("Missing PDF"),
                                call.argument<String>("format") ?: "png"
                            )
                            "renderPage" -> renderPage(
                                call.argument<String>("path") ?: error("Missing PDF"),
                                call.argument<Int>("index") ?: 0
                            )
                            "getEditState" -> stateFile(call.argument<String>("path") ?: error("Missing state")).readText()
                            "setEditState" -> {
                                val content = call.argument<String>("json") ?: error("Missing annotation state")
                                require(content.length <= 500_000) { "Too many annotations" }
                                val target = stateFile(call.argument<String>("path") ?: error("Missing state"))
                                val partial = File(target.parentFile, "${target.name}.part")
                                try {
                                    partial.writeText(content)
                                    require(partial.renameTo(target)) { "Could not save annotations" }
                                } finally { if (partial.exists()) partial.delete() }
                                true
                            }
                            else -> {
                                activity.runOnUiThread { result.notImplemented() }
                                return@execute
                            }
                        }
                        activity.runOnUiThread { result.success(answer) }
                    } catch (e: Exception) {
                        activity.runOnUiThread {
                            result.error("pdf_studio", e.message ?: "PDF operation failed", null)
                        }
                    }
                }
            }
    }

    private fun output(): File = File.createTempFile("studio_", ".pdf", activity.cacheDir)

    private fun compose(pages: List<Map<String, Any?>>): String {
        require(pages.isNotEmpty() && pages.size <= 150) { "Select 1–150 pages." }
        val destination = output()
        val document = PdfDocument()
        val inputs = mutableMapOf<String, Pair<ParcelFileDescriptor, PdfRenderer>>()
        try {
            pages.forEachIndexed { position, spec ->
                if (spec["blank"] == true) {
                    val blank = document.startPage(PdfDocument.PageInfo.Builder(595, 842, position + 1).create())
                    blank.canvas.drawColor(Color.WHITE)
                    document.finishPage(blank)
                    return@forEachIndexed
                }
                val source = File(spec["path"] as? String ?: error("Missing source"))
                val index = (spec["page"] as? Number)?.toInt() ?: error("Missing page index")
                val rotation = ((spec["rotation"] as? Number)?.toInt() ?: 0).rem(360)
                require(rotation == 0 || rotation == 90 || rotation == 180 || rotation == 270) { "Invalid rotation" }
                val renderer = inputs.getOrPut(source.canonicalPath) {
                    val fd = ParcelFileDescriptor.open(source, ParcelFileDescriptor.MODE_READ_ONLY)
                    try { fd to PdfRenderer(fd) }
                    catch (e: Exception) { fd.close(); throw e }
                }.second
                        require(index in 0 until renderer.pageCount) { "Page out of range" }
                        renderer.openPage(index).use { page ->
                            val sideways = rotation == 90 || rotation == 270
                            val width = if (sideways) page.height else page.width
                            val height = if (sideways) page.width else page.height
                            val scale = minOf(2f, 2000f / maxOf(page.width, page.height))
                            val bitmap = Bitmap.createBitmap(
                                maxOf(1, (page.width * scale).toInt()),
                                maxOf(1, (page.height * scale).toInt()), Bitmap.Config.ARGB_8888
                            )
                            try {
                                bitmap.eraseColor(Color.WHITE)
                                page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                                val info = PdfDocument.PageInfo.Builder(width, height, position + 1).create()
                                val target = document.startPage(info)
                                val canvas = target.canvas
                                canvas.drawColor(Color.WHITE)
                                canvas.save()
                                when (rotation) {
                                    90 -> { canvas.translate(width.toFloat(), 0f); canvas.rotate(90f) }
                                    180 -> { canvas.translate(width.toFloat(), height.toFloat()); canvas.rotate(180f) }
                                    270 -> { canvas.translate(0f, height.toFloat()); canvas.rotate(270f) }
                                }
                                canvas.drawBitmap(bitmap, null, RectF(0f, 0f, page.width.toFloat(), page.height.toFloat()), Paint(Paint.FILTER_BITMAP_FLAG))
                                canvas.restore()
                                @Suppress("UNCHECKED_CAST")
                                val marks = spec["annotations"] as? List<Map<String, Any?>> ?: emptyList()
                                paintAnnotations(canvas, marks, width.toFloat(), height.toFloat())
                                document.finishPage(target)
                            } finally { bitmap.recycle() }
                        }
            }
            destination.outputStream().use { document.writeTo(it) }
            return destination.absolutePath
        } catch (e: Exception) {
            destination.delete()
            throw e
        } finally {
            document.close()
            inputs.values.forEach { (fd, renderer) ->
                try { renderer.close() } finally { fd.close() }
            }
        }
    }

    private fun imagesToPdf(paths: List<String>): String {
        require(paths.isNotEmpty() && paths.size <= 50) { "Choose 1–50 images." }
        val destination = output()
        val document = PdfDocument()
        try {
            paths.forEachIndexed { index, path ->
                val options = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(path, options)
                require(options.outWidth > 0 && options.outHeight > 0) { "Invalid image" }
                options.inSampleSize = 1
                while (maxOf(options.outWidth, options.outHeight) / options.inSampleSize > 2000) options.inSampleSize *= 2
                options.inJustDecodeBounds = false
                val bitmap = BitmapFactory.decodeFile(path, options) ?: error("Image could not be read")
                try {
                    val portrait = bitmap.height >= bitmap.width
                    val width = if (portrait) 595 else 842
                    val height = if (portrait) 842 else 595
                    val page = document.startPage(PdfDocument.PageInfo.Builder(width, height, index + 1).create())
                    page.canvas.drawColor(Color.WHITE)
                    val factor = minOf((width - 40f) / bitmap.width, (height - 40f) / bitmap.height)
                    val w = bitmap.width * factor
                    val h = bitmap.height * factor
                    page.canvas.drawBitmap(bitmap, null, RectF((width - w) / 2, (height - h) / 2, (width + w) / 2, (height + h) / 2), Paint(Paint.FILTER_BITMAP_FLAG))
                    document.finishPage(page)
                } finally { bitmap.recycle() }
            }
            destination.outputStream().use { document.writeTo(it) }
            return destination.absolutePath
        } catch (e: Exception) { destination.delete(); throw e }
        finally { document.close() }
    }

    private fun textToPdf(text: String): String {
        require(text.length <= 200_000) { "Document is too long." }
        val destination = output()
        val document = PdfDocument()
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.BLACK; textSize = 12f }
        try {
            val lines = mutableListOf<String>()
            text.replace("\r\n", "\n").split('\n').forEach { paragraph ->
                var line = ""
                paragraph.split(' ').forEach { word ->
                    val next = if (line.isEmpty()) word else "$line $word"
                    if (paint.measureText(next) > 510f && line.isNotEmpty()) { lines.add(line); line = word }
                    else line = next
                }
                lines.add(line)
            }
            require(lines.size <= 5000) { "Document is too long." }
            lines.chunked(48).forEachIndexed { i, chunk ->
                val page = document.startPage(PdfDocument.PageInfo.Builder(595, 842, i + 1).create())
                page.canvas.drawColor(Color.WHITE)
                chunk.forEachIndexed { row, line -> page.canvas.drawText(line.take(400), 42f, 48f + row * 16f, paint) }
                document.finishPage(page)
            }
            destination.outputStream().use { document.writeTo(it) }
            return destination.absolutePath
        } catch (e: Exception) { destination.delete(); throw e }
        finally { document.close() }
    }

    private fun textToDocx(text: String): String {
        require(text.length <= 200_000) { "Document is too long." }
        val destination = File.createTempFile("studio_document_", ".docx", activity.cacheDir)
        fun escape(value: String): String = value.replace("&", "&amp;")
            .replace("<", "&lt;").replace(">", "&gt;")
            .replace("\"", "&quot;").replace("'", "&apos;")
        val paragraphs = text.replace("\r\n", "\n").split('\n').joinToString("") { line ->
            "<w:p><w:r><w:t xml:space=\"preserve\">${escape(line.filter { it == '\t' || it >= ' ' })}</w:t></w:r></w:p>"
        }
        try {
            ZipOutputStream(destination.outputStream().buffered()).use { zip ->
                fun entry(name: String, xml: String) {
                    zip.putNextEntry(ZipEntry(name))
                    zip.write(xml.toByteArray(Charsets.UTF_8))
                    zip.closeEntry()
                }
                entry("[Content_Types].xml", """<?xml version="1.0" encoding="UTF-8"?>
                    <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
                    <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
                    <Default Extension="xml" ContentType="application/xml"/>
                    <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
                    </Types>""".trimIndent())
                entry("_rels/.rels", """<?xml version="1.0" encoding="UTF-8"?>
                    <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
                    <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
                    </Relationships>""".trimIndent())
                entry("word/document.xml", """<?xml version="1.0" encoding="UTF-8"?>
                    <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
                    <w:body>$paragraphs<w:sectPr/></w:body></w:document>""".trimIndent())
            }
            return destination.absolutePath
        } catch (e: Exception) { destination.delete(); throw e }
    }

    private fun pagesToImages(path: String, format: String): String {
        require(format == "png" || format == "jpg") { "Choose PNG or JPG." }
        val archive = File.createTempFile("studio_pages_", ".zip", activity.cacheDir)
        try {
            ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY).use { fd ->
                PdfRenderer(fd).use { renderer ->
                    require(renderer.pageCount <= 150) { "Export up to 150 pages." }
                    ZipOutputStream(archive.outputStream().buffered()).use { zip ->
                        for (index in 0 until renderer.pageCount) {
                            renderer.openPage(index).use { page ->
                                val factor = minOf(2f, 2000f / maxOf(page.width, page.height))
                                val bitmap = Bitmap.createBitmap(
                                    maxOf(1, (page.width * factor).toInt()),
                                    maxOf(1, (page.height * factor).toInt()), Bitmap.Config.ARGB_8888
                                )
                                try {
                                    bitmap.eraseColor(Color.WHITE)
                                    page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                                    zip.putNextEntry(ZipEntry("page_${(index + 1).toString().padStart(3, '0')}.$format"))
                                    bitmap.compress(if (format == "png") Bitmap.CompressFormat.PNG else Bitmap.CompressFormat.JPEG, 85, zip)
                                    zip.closeEntry()
                                } finally { bitmap.recycle() }
                            }
                        }
                    }
                }
            }
            return archive.absolutePath
        } catch (e: Exception) { archive.delete(); throw e }
    }

    private fun stateFile(path: String): File {
        val root = File(activity.filesDir, "pdf_studio/state").canonicalFile
        val target = File(path).canonicalFile
        require(target.parentFile == root && target.name.endsWith("_state.json") && target.isFile) {
            "Annotation state is unavailable"
        }
        return target
    }

    private fun renderPage(path: String, index: Int): Map<String, Any> {
        ParcelFileDescriptor.open(File(path), ParcelFileDescriptor.MODE_READ_ONLY).use { fd ->
            PdfRenderer(fd).use { renderer ->
                require(index in 0 until renderer.pageCount) { "Page out of range" }
                renderer.openPage(index).use { page ->
                    val factor = minOf(2f, 1800f / maxOf(page.width, page.height))
                    val bitmap = Bitmap.createBitmap(maxOf(1, (page.width * factor).toInt()),
                        maxOf(1, (page.height * factor).toInt()), Bitmap.Config.ARGB_8888)
                    try {
                        bitmap.eraseColor(Color.WHITE)
                        page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                        val output = ByteArrayOutputStream()
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, output)
                        return mapOf("bytes" to output.toByteArray(), "width" to bitmap.width, "height" to bitmap.height)
                    } finally { bitmap.recycle() }
                }
            }
        }
    }

    private fun paintAnnotations(canvas: Canvas, marks: List<Map<String, Any?>>, width: Float, height: Float) {
        for (mark in marks.take(200)) {
            val type = mark["tool"] as? String ?: continue
            val raw = mark["points"] as? List<*> ?: continue
            val points = raw.mapNotNull { pair ->
                val values = pair as? List<*> ?: return@mapNotNull null
                if (values.size != 2) return@mapNotNull null
                val x = (values[0] as? Number)?.toFloat() ?: return@mapNotNull null
                val y = (values[1] as? Number)?.toFloat() ?: return@mapNotNull null
                if (!x.isFinite() || !y.isFinite()) return@mapNotNull null
                (x.coerceIn(0f, 1f) * width) to (y.coerceIn(0f, 1f) * height)
            }
            if (points.isEmpty()) continue
            val color = (mark["color"] as? Number)?.toInt() ?: Color.rgb(103, 49, 210)
            val stroke = ((mark["stroke"] as? Number)?.toFloat() ?: 3f).coerceIn(1f, 32f)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                this.color = if (type == "highlight") (color and 0x00FFFFFF) or 0x66000000 else color
                style = Paint.Style.STROKE
                strokeWidth = if (type == "highlight") stroke * 5f else stroke
                strokeCap = Paint.Cap.ROUND
                strokeJoin = Paint.Join.ROUND
            }
            val first = points.first()
            val last = points.last()
            when (type) {
                "ink", "highlight", "underline", "strike" -> {
                    val line = Path().apply {
                        moveTo(first.first, first.second)
                        points.drop(1).forEach { lineTo(it.first, it.second) }
                    }
                    canvas.drawPath(line, paint)
                }
                "rectangle" -> canvas.drawRect(minOf(first.first, last.first), minOf(first.second, last.second),
                    maxOf(first.first, last.first), maxOf(first.second, last.second), paint)
                "circle" -> canvas.drawOval(RectF(minOf(first.first, last.first), minOf(first.second, last.second),
                    maxOf(first.first, last.first), maxOf(first.second, last.second)), paint)
                "text", "signature" -> {
                    val label = (mark["text"] as? String ?: "").take(90)
                    paint.style = Paint.Style.FILL
                    paint.textSize = if (type == "signature") 24f else 14f
                    if (type == "signature") paint.typeface = Typeface.create(Typeface.SERIF, Typeface.ITALIC)
                    canvas.drawText(label, first.first, first.second + paint.textSize, paint)
                }
            }
        }
    }

    fun close() { worker.shutdown() }
}
