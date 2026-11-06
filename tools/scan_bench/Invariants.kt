import com.hyzen.pharmd.ScanVision
import kotlin.math.abs

fun main() {
    // Uniform scenes must never trigger automatic capture.
    for (tone in listOf(0f, 120f, 240f, 255f)) {
        val image = ScanVision.Gray(400, 300, FloatArray(400 * 300) { tone })
        check(ScanVision.detect(image) == null)
        check(ScanVision.detect(image, refine = false, fast = true) == null)
    }
    // Exercise real Y-plane padding/pixel stride and all camera orientations.
    val y = byteArrayOf(1, 0, 2, 0, 3, 0, 99, 99, 4, 0, 5, 0, 6)
    val expected = mapOf(
        0 to listOf(1f, 2f, 3f, 4f, 5f, 6f),
        90 to listOf(4f, 1f, 5f, 2f, 6f, 3f),
        180 to listOf(6f, 5f, 4f, 3f, 2f, 1f),
        270 to listOf(3f, 6f, 2f, 5f, 1f, 4f),
    )
    for ((rotation, pixels) in expected) {
        check(ScanVision.grayFromLuma(y, 3, 2, 8, 2, rotation, 640).px.toList() == pixels)
    }
    // Magic should lift uneven paper and retain dark ink. Original is reversible.
    val w = 160; val h = 200
    val page = IntArray(w * h) { i ->
        val x = i % w; val yy = i / w
        val tone = if (yy % 25 in 10..12 && x in 20..140) 25 else 150 + x / 2
        (0xff shl 24) or (tone shl 16) or (tone shl 8) or tone
    }
    val original = page.copyOf()
    ScanVision.enhance(original, w, h, "original")
    check(original.contentEquals(page))
    ScanVision.enhance(page, w, h, "magic")
    check((page[30 * w + 20] and 255) > 240)
    check((page[10 * w + 80] and 255) < 35)
    // Free corners map independently through the projective transform.
    val quad = doubleArrayOf(5.0, 12.0, 95.0, 3.0, 88.0, 130.0, 16.0, 118.0)
    val m = ScanVision.homography(100.0, 140.0, quad)
    for ((i, p) in listOf(0.0 to 0.0, 100.0 to 0.0, 100.0 to 140.0, 0.0 to 140.0).withIndex()) {
        val z = m[6] * p.first + m[7] * p.second + m[8]
        check(abs((m[0] * p.first + m[1] * p.second + m[2]) / z - quad[i * 2]) < 1e-6)
        check(abs((m[3] * p.first + m[4] * p.second + m[5]) / z - quad[i * 2 + 1]) < 1e-6)
    }
    println("PASS: blank scenes, strided luma rotations, text cleanup, independent perspective corners")
}
