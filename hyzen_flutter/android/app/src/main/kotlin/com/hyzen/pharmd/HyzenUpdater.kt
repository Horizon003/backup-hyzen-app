package com.hyzen.pharmd

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.net.Uri
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.BinaryMessenger
import java.io.File
import java.net.URL
import java.net.HttpURLConnection
import java.security.MessageDigest
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

class HyzenUpdater(private val activity: FlutterActivity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "com.hyzen.pharmd/updates")
    private val worker = Executors.newSingleThreadExecutor()
    private val busy = AtomicBoolean(false)
    private val cancelled = AtomicBoolean(false)
    private fun code(p: android.content.pm.PackageInfo): Long = if(Build.VERSION.SDK_INT >= 28) p.longVersionCode else p.versionCode.toLong()
    private val flags get() = if(Build.VERSION.SDK_INT >= 28) PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES
    @Suppress("DEPRECATION")
    private fun signatures(p: android.content.pm.PackageInfo): Set<String> {
        val sigs = if(Build.VERSION.SDK_INT >= 28) p.signingInfo?.apkContentsSigners else p.signatures
        return sigs?.map { MessageDigest.getInstance("SHA-256").digest(it.toByteArray()).joinToString("") { b -> "%02x".format(b) } }?.toSet() ?: emptySet()
    }
    private fun verify(file: File, expectedCode: Long) {
        val current = activity.packageManager.getPackageInfo(activity.packageName, flags)
        val candidate = activity.packageManager.getPackageArchiveInfo(file.path, flags) ?: error("Downloaded APK is invalid.")
        check(candidate.packageName == activity.packageName) { "This APK belongs to a different app." }
        check(code(candidate) == expectedCode && code(candidate) > code(current)) { "Update version is invalid or older than your app." }
        check(signatures(current).isNotEmpty() && signatures(current) == signatures(candidate)) { "Signing key mismatch. This update was not signed by the Hyzen release key." }
    }
    init {
        channel.setMethodCallHandler { call, result ->
            when(call.method) {
                "info" -> {
                    val p = activity.packageManager.getPackageInfo(activity.packageName, 0)
                    result.success(mapOf("code" to code(p), "name" to p.versionName))
                }
                "cancel" -> { cancelled.set(true); result.success(null) }
                "download" -> {
                    if(!busy.compareAndSet(false,true)) { result.error("busy","An update is already downloading.",null); return@setMethodCallHandler }
                    cancelled.set(false)
                    val url = call.argument<String>("url") ?: ""
                    val hash = call.argument<String>("sha256") ?: ""
                    val expected = call.argument<Number>("code")?.toLong() ?: 0L
                    worker.execute {
                        val dir = File(activity.cacheDir,"hyzen_updates").apply { mkdirs() }
                        val part = File(dir,"release.part")
                        val target = File(dir,"release.apk")
                        var connection: HttpURLConnection? = null
                        try {
                            check(Regex("[a-fA-F0-9]{64}").matches(hash)) { "Invalid update checksum." }
                            var next = URL(url)
                            for(i in 0..5) {
                                check(next.protocol == "https" && next.userInfo == null) { "Only secure HTTPS update downloads are supported." }
                                connection = next.openConnection() as HttpURLConnection
                                connection!!.apply { connectTimeout=20000;readTimeout=30000;instanceFollowRedirects=false }
                                val status = connection!!.responseCode
                                if(status in 300..399) {
                                    val location = connection!!.getHeaderField("Location") ?: error("Invalid update redirect.")
                                    next = URL(next,location);connection!!.disconnect();connection=null
                                } else break
                            }
                            val conn = connection ?: error("Too many update redirects.")
                            check(conn.responseCode == 200) { "Update server returned ${conn.responseCode}." }
                            val total = conn.contentLengthLong
                            val max = 300L*1024*1024
                            check(total <= max) { "Update is too large." }
                            check(dir.usableSpace > (if(total>0) total*2 else max)) { "Not enough free space for this update." }
                            val digest = MessageDigest.getInstance("SHA-256")
                            var received = 0L
                            var last = 0L
                            part.outputStream().use { output -> conn.inputStream.use { input ->
                                val buffer = ByteArray(65536)
                                while(true) {
                                    check(!cancelled.get()) { "Download cancelled." }
                                    val n=input.read(buffer);if(n<0)break
                                    received+=n;check(received<=max) { "Update is too large." }
                                    output.write(buffer,0,n);digest.update(buffer,0,n)
                                    if(System.currentTimeMillis()-last>200) {
                                        last=System.currentTimeMillis();val count=received
                                        activity.runOnUiThread { channel.invokeMethod("progress",mapOf("received" to count,"total" to total)) }
                                    }
                                }
                            }}
                            check(!cancelled.get()) { "Download cancelled." }
                            check(received>0 && (total<=0 || received==total)) { "Update download was incomplete." }
                            val actual=digest.digest().joinToString("") { "%02x".format(it) }
                            check(actual.equals(hash,true)) { "Update checksum mismatch. Please retry." }
                            verify(part,expected)
                            check(part.renameTo(target)) { "Could not save update." }
                            activity.runOnUiThread { result.success(target.path) }
                        } catch(e:Exception) {
                            part.delete()
                            activity.runOnUiThread { result.error("update",e.message ?: "Update failed.",null) }
                        } finally { connection?.disconnect();busy.set(false) }
                    }
                }
                "install" -> {
                    try {
                        val file=File(call.argument<String>("path") ?: "").canonicalFile
                        val expected=call.argument<Number>("code")?.toLong() ?: 0L
                        check(file.parentFile == File(activity.cacheDir,"hyzen_updates").canonicalFile && file.name=="release.apk") { "Invalid update path." }
                        verify(file,expected)
                        if(Build.VERSION.SDK_INT >= 26 && !activity.packageManager.canRequestPackageInstalls()) {
                            activity.startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,Uri.parse("package:${activity.packageName}")))
                            result.success(false)
                        } else {
                            val uri=FileProvider.getUriForFile(activity,"${activity.packageName}.updates",file)
                            activity.startActivity(Intent(Intent.ACTION_VIEW).setDataAndType(uri,"application/vnd.android.package-archive").addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION))
                            result.success(true)
                        }
                    } catch(e:Exception) { result.error("install",e.message,null) }
                }
                else -> result.notImplemented()
            }
        }
    }
}
