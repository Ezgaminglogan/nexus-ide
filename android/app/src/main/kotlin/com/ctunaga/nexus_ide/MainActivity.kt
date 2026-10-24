package com.ctunaga.nexus_ide

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.zip.ZipInputStream

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, "nexus/toolchains").setMethodCallHandler { call, result ->
            if (call.method != "install") return@setMethodCallHandler result.notImplemented()
            Thread {
                try {
                    val dir = installToolchains()
                    runOnUiThread { result.success(dir) }
                } catch (e: Exception) {
                    runOnUiThread { result.error("unpack", e.toString(), null) }
                }
            }.start()
        }
    }

    /** Unpacks assets/toolchains.zip (built by tool/build_android_toolchains.py) once per APK install/update. */
    private fun installToolchains(): String {
        val dir = File(filesDir, "toolchains")
        val stamp = File(dir, ".installed")
        @Suppress("DEPRECATION")
        val version = packageManager.getPackageInfo(packageName, 0).lastUpdateTime.toString()
        if (stamp.exists() && stamp.readText() == version) return dir.path

        dir.deleteRecursively()
        val root = dir.canonicalPath + File.separator
        ZipInputStream(assets.open("toolchains.zip")).use { zip ->
            generateSequence { zip.nextEntry }.forEach { e ->
                val out = File(dir, e.name)
                if (!out.canonicalPath.startsWith(root)) throw SecurityException("bad zip entry ${e.name}")
                if (e.isDirectory) {
                    out.mkdirs()
                } else {
                    out.parentFile?.mkdirs()
                    out.outputStream().use { zip.copyTo(it) }
                    if (e.name.startsWith("bin/") || e.name.startsWith("avr/")) out.setExecutable(true, false)
                    if (e.name.endsWith(".jar")) out.setReadOnly() // Android 14+ refuses writable dex (Java tile)
                }
            }
        }
        stamp.writeText(version)
        return dir.path
    }
}
