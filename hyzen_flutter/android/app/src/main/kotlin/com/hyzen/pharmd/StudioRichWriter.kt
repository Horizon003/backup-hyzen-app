package com.hyzen.pharmd

import android.content.Context
import android.graphics.*
import android.graphics.pdf.PdfDocument
import java.io.File
import java.io.ByteArrayOutputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

/** Structured new documents: paragraphs, headings, lists, tables and images. */
class StudioRichWriter(private val context: Context) {
    fun write(blocks: List<Map<String,Any?>>, format: String): String {
        require(blocks.isNotEmpty() && blocks.size<=100)
        require(blocks.sumOf{(it["text"] as? String ?: "").length}<=200_000)
        return if(format=="docx") docx(blocks) else pdf(blocks)
    }
    private fun image(path:String):Bitmap = StudioImages.load(path,1600)
    private fun pdf(blocks:List<Map<String,Any?>>):String {
        val output=File.createTempFile("hyzen_rich_",".pdf",context.cacheDir)
        val doc=PdfDocument();var number=1
        var page=doc.startPage(PdfDocument.PageInfo.Builder(595,842,number).create())
        var y=48f
        fun space(height:Float) {if(y+height>800){doc.finishPage(page);number++;page=doc.startPage(PdfDocument.PageInfo.Builder(595,842,number).create());y=48f;require(number<=150)}}
        try {
            for(block in blocks) {
                val type=block["type"] as? String ?: "paragraph"
                if(type=="image") {
                    val bitmap=image(block["path"] as String)
                    try {val scale=minOf(500f/bitmap.width,330f/bitmap.height);val w=bitmap.width*scale;val h=bitmap.height*scale
                        space(h+16);page.canvas.drawBitmap(bitmap,null,RectF(48f,y,48f+w,y+h),Paint(Paint.FILTER_BITMAP_FLAG));y+=h+16
                    }finally{bitmap.recycle()};continue
                }
                val text=(block["text"] as? String ?: "").replace("\r","")
                val bold=block["bold"]==true || type=="heading"
                val italic=block["italic"]==true
                val paint=Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color=Color.rgb(25,22,40);textSize=if(type=="heading")22f else 12f
                    typeface=Typeface.create(Typeface.SANS_SERIF,(if(bold)Typeface.BOLD else 0) or (if(italic)Typeface.ITALIC else 0))
                    isUnderlineText=block["underline"]==true
                }
                if(type=="table") {
                    val rows=text.lines().filter{it.isNotBlank()}.take(50).map{it.split('|').take(6)}
                    val columns=rows.maxOfOrNull{it.size} ?: 1
                    val width=500f/columns
                    val border=Paint().apply{color=Color.LTGRAY;style=Paint.Style.STROKE;strokeWidth=1f}
                    for(row in rows){space(30f);for(col in 0 until columns){val x=48+col*width
                        page.canvas.drawRect(x,y,x+width,y+27,border)
                        var label=row.getOrNull(col) ?: "";while(paint.measureText(label)>width-8 && label.isNotEmpty())label=label.dropLast(1)
                        page.canvas.drawText(label,x+4,y+18,paint)};y+=27f};y+=12;continue
                }
                for(raw in text.lines()) {
                    val paragraph=if(type=="list") "• $raw" else raw
                    val lines=mutableListOf<String>();var line=""
                    for(word in paragraph.split(' ')) {
                        var token=word
                        if(paint.measureText(if(line.isEmpty())token else "$line $token")>500 && line.isNotEmpty()){lines.add(line);line=""}
                        while(paint.measureText(token)>500 && token.length>1){var end=token.length-1;while(end>1 && paint.measureText(token.take(end))>500)end--;lines.add(token.take(end));token=token.drop(end)}
                        line=if(line.isEmpty())token else "$line $token"
                    };lines.add(line)
                    for(value in lines){val height=paint.textSize*1.5f;space(height)
                        val x=when(block["align"]){"center"->48+(500-paint.measureText(value))/2;"right"->548-paint.measureText(value);else->48f}
                        page.canvas.drawText(value,x,y+paint.textSize,paint);y+=height
                    }
                };y+=10
            }
            doc.finishPage(page);output.outputStream().use{doc.writeTo(it)};return output.absolutePath
        }catch(e:Exception){output.delete();throw e}finally{doc.close()}
    }
    private fun xml(s:String)=s.filter{it=='\n'||it=='\t'||it>=' '}.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;")
    private fun docx(blocks:List<Map<String,Any?>>):String {
        val output=File.createTempFile("hyzen_rich_",".docx",context.cacheDir)
        val relationships=StringBuilder();val body=StringBuilder();var imageNumber=0
        try {ZipOutputStream(output.outputStream().buffered()).use { zip ->
            fun bytes(name:String,data:ByteArray){zip.putNextEntry(ZipEntry(name));zip.write(data);zip.closeEntry()}
            fun entry(name:String,text:String)=bytes(name,text.toByteArray(Charsets.UTF_8))
            fun paragraph(text:String,block:Map<String,Any?>):String {
                val style=buildString {if(block["bold"]==true || block["type"]=="heading")append("<w:b/>");if(block["italic"]==true)append("<w:i/>");if(block["underline"]==true)append("<w:u w:val=\"single\"/>");append("<w:sz w:val=\"${if(block["type"]=="heading")36 else 24}\"/>")}
                val align=if(block["align"] in listOf("center","right"))block["align"] else "left"
                return "<w:p><w:pPr><w:jc w:val=\"$align\"/></w:pPr><w:r><w:rPr>$style</w:rPr><w:t xml:space=\"preserve\">${xml(text)}</w:t></w:r></w:p>"
            }
            for(block in blocks) {
                val type=block["type"] ?: "paragraph";val text=block["text"] as? String ?: ""
                when(type) {
                    "image"->{imageNumber++;val bitmap=image(block["path"] as String)
                        try {val buffer=ByteArrayOutputStream();bitmap.compress(Bitmap.CompressFormat.PNG,100,buffer);bytes("word/media/image$imageNumber.png",buffer.toByteArray())
                            val cx=4572000L;val cy=cx*bitmap.height/bitmap.width
                            relationships.append("<Relationship Id=\"rId$imageNumber\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/image\" Target=\"media/image$imageNumber.png\"/>")
                            body.append("""<w:p><w:r><w:drawing><wp:inline><wp:extent cx="$cx" cy="$cy"/><wp:docPr id="$imageNumber" name="Image $imageNumber"/><a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:pic><pic:nvPicPr><pic:cNvPr id="$imageNumber" name="Image"/><pic:cNvPicPr/></pic:nvPicPr><pic:blipFill><a:blip r:embed="rId$imageNumber"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill><pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>""")
                        }finally{bitmap.recycle()}}
                    "table"->{body.append("<w:tbl><w:tblPr><w:tblBorders><w:top w:val=\"single\"/><w:left w:val=\"single\"/><w:bottom w:val=\"single\"/><w:right w:val=\"single\"/><w:insideH w:val=\"single\"/><w:insideV w:val=\"single\"/></w:tblBorders></w:tblPr>")
                        for(row in text.lines().filter{it.isNotBlank()}.take(50)){body.append("<w:tr>");for(cell in row.split('|').take(6))body.append("<w:tc>${paragraph(cell,block)}</w:tc>");body.append("</w:tr>")};body.append("</w:tbl>")}
                    else->for(line in text.lines())body.append(paragraph(if(type=="list")"• $line" else line,block))
                }
            }
            entry("[Content_Types].xml","""<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Default Extension="png" ContentType="image/png"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>""")
            entry("_rels/.rels","""<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rIdDoc" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>""")
            entry("word/_rels/document.xml.rels","""<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">$relationships</Relationships>""")
            entry("word/document.xml","""<?xml version="1.0" encoding="UTF-8"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"><w:body>$body<w:sectPr><w:pgSz w:w="11906" w:h="16838"/></w:sectPr></w:body></w:document>""")
        };return output.absolutePath}catch(e:Exception){output.delete();throw e}
    }
}
