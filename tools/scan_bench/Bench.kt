import com.hyzen.pharmd.ScanVision
import java.io.File
import javax.imageio.ImageIO
import kotlin.math.hypot

// Usage: kotlin Bench <dir-with-images-and-gt.json>
fun main(args: Array<String>) {
    val dir = File(args[0])
    val gtText = File(dir, "gt.json").takeIf { it.exists() }?.readText() ?: "{}"
    val gt = Regex("\"([^\"]+)\": \\[([^\\]]+)\\]").findAll(gtText).associate { m ->
        m.groupValues[1] to m.groupValues[2].split(",").map { it.trim().toDouble() }
    }
    var ok = 0; var miss = 0; var bad = 0; val errs = ArrayList<Double>()
    val out = StringBuilder()
    for (f in dir.listFiles()!!.filter { it.extension == "jpg" }.sortedBy { it.name }) {
        val img = ImageIO.read(f)
        val w = img.width; val h = img.height
        val argb = img.getRGB(0, 0, w, h, null, 0, w)
        val t0 = System.nanoTime()
        val q = ScanVision.detect(ScanVision.grayFromArgb(argb, w, h, 1400))
        val ms = (System.nanoTime() - t0) / 1e6
        val g = gt[f.name]
        if (q == null) { miss++; out.append("${f.name}: MISS  ${"%.0f".format(ms)}ms\n"); continue }
        out.append("${f.name}: ${q.pts.joinToString(",") { "%.4f".format(it) }} s=${"%.2f".format(q.score)} ${"%.0f".format(ms)}ms")
        if (g != null) {
            var e = 0.0
            for (i in 0..3) e = maxOf(e, hypot((q.pts[i*2]-g[i*2])*w, (q.pts[i*2+1]-g[i*2+1])*h))
            val rel = e / hypot(w.toDouble(), h.toDouble()) * 100
            errs.add(rel); if (rel < 1.5) ok++ else bad++
            out.append("  maxErr=${"%.1f".format(e)}px (${"%.2f".format(rel)}% diag)")
        }
        out.append("\n")
    }
    print(out)
    errs.sort()
    if (errs.isNotEmpty()) println("GT images: ${errs.size + miss}  accurate(<1.5%diag)=$ok  inaccurate=$bad  missed=$miss  median=${"%.2f".format(errs[errs.size/2])}%")
}
