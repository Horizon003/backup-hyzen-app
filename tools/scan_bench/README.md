Scanner accuracy bench (JVM, no Android needed):
  python3 make_synth.py /tmp/bench 40
  kotlinc ../../hyzen_flutter/android/app/src/main/kotlin/com/hyzen/pharmd/ScanVision.kt Bench.kt -include-runtime -d bench.jar
  java -cp bench.jar BenchKt /tmp/bench
Result at commit: 24/24 synthetic photos within 1.5% diag (median 0.00%, <0.3px), ~30ms each on desktop JVM.
