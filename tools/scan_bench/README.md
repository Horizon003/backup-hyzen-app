# Scanner regression checks

Run from this directory with Kotlin/JDK, Python, NumPy and Pillow installed:

```sh
mkdir -p /tmp/scan-synth
python3 make_synth.py /tmp/scan-synth 40
python3 make_regression.py /tmp/scan-hard
kotlinc ../../hyzen_flutter/android/app/src/main/kotlin/com/hyzen/pharmd/ScanVision.kt Bench.kt Invariants.kt -include-runtime -d /tmp/scan-bench.jar
java -cp /tmp/scan-bench.jar InvariantsKt
java -cp /tmp/scan-bench.jar BenchKt /tmp/scan-synth
java -cp /tmp/scan-bench.jar BenchKt /tmp/scan-synth --live
java -cp /tmp/scan-bench.jar BenchKt /tmp/scan-hard
java -cp /tmp/scan-bench.jar BenchKt /tmp/scan-hard --live
```

The general generator rejects pages outside the photo and produces 24 valid
photos from 40 attempts. Four regression fixtures add pale paper on a light
table, an off-centre document, dense text, and uneven illumination.

November 2026 results: all 28 synthetic photos within 1.5% of the image diagonal
in both still and live mode. Median error: general set 0.00% still / 0.27% live;
hard set 0.00% still / 0.29% live. Invariants also check empty scenes, padded
camera luma buffers at four rotations, text/background contrast and perspective
corner mapping. These are reproducible synthetic checks, not a claim of phone
camera accuracy or latency. Real devices still need camera/lighting checks.
