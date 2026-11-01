# PDFBox detects this optional legacy JPEG-2000 codec at runtime. PDFium/Android
# renders PDFs; we do not use the retired JCenter-only JP2Android dependency.
-dontwarn com.gemalto.jp2.**

# Keep the native document API and PDFBox's runtime-accessed model API stable.
# Release instrumentation invokes these same entry points; R8 must not inline
# away the classes while leaving references in the separate test APK.
-keep class com.hyzen.pharmd.StudioDocumentOps { *; }
-keep class com.hyzen.pharmd.StudioRichWriter { *; }
-keep class com.hyzen.pharmd.StudioImages { *; }
-keep class com.hyzen.pharmd.ScanDraftStore { *; }
-keep class com.tom_roush.pdfbox.** { *; }

# The separate test APK shares these runtime libraries with the release APK.
# Preserve facade implementation classes too: Kotlin static methods can live
# in a facade's parent class rather than on the named public facade itself.
-keep class androidx.tracing.** { *; }
-keep class androidx.concurrent.futures.** { *; }
-keep class com.google.common.util.concurrent.ListenableFuture { *; }
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.BuildersKt** { *; }
-keep class kotlinx.coroutines.CancellableContinuation** { *; }
-keep class kotlinx.coroutines.ExecutorsKt** { *; }
-keep class kotlinx.coroutines.Job** { *; }
-keep class kotlinx.coroutines.MainCoroutineDispatcher { *; }
-keep class kotlinx.coroutines.TimeoutKt** { *; }

-keep class com.hyzen.pharmd.ScanVision { *; }
-keep class com.hyzen.pharmd.ScanBitmaps { *; }
-keep class com.hyzen.pharmd.HyzenScannerActivity { *; }
-keep class androidx.camera.** { *; }
