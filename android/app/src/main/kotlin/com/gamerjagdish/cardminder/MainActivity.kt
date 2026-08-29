package com.gamerjagdish.cardminder

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.gamerjagdish.cardminder/file_utils"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openFolder") {
                val path = call.argument<String>("path")
                if (path != null) {
                    val opened = openFolder(path)
                    result.success(opened)
                } else {
                    result.error("INVALID_PATH", "Path cannot be null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openFolder(path: String): Boolean {
        return try {
            val file = File(path)
            if (!file.exists()) {
                file.mkdirs()
            }

            // 1. Convert standard path to Android DocumentsContract directory URI
            val relativePath = path
                .replace("/storage/emulated/0/", "")
                .replace("/storage/emulated/0", "")
                .trim('/')

            val docUri = if (relativePath.isNotEmpty()) {
                val encodedPath = Uri.encode(relativePath)
                Uri.parse("content://com.android.externalstorage.documents/document/primary%3A$encodedPath")
            } else {
                Uri.parse("content://com.android.externalstorage.documents/root/primary")
            }

            // 2. Try ACTION_VIEW with MIME_TYPE_DIR (strictly matches File Managers only)
            val docIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(docUri, DocumentsContract.Document.MIME_TYPE_DIR)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
            }

            if (docIntent.resolveActivity(packageManager) != null) {
                startActivity(docIntent)
                return true
            }

            // 3. Try ACTION_OPEN_DOCUMENT_TREE with initial URI on Android 8+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val treeIntent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                    putExtra(DocumentsContract.EXTRA_INITIAL_URI, docUri)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
                }
                if (treeIntent.resolveActivity(packageManager) != null) {
                    startActivity(treeIntent)
                    return true
                }
            }

            // 4. Fallback to launching the default system File Manager app directly
            val knownFileManagerPackages = listOf(
                "com.google.android.documentsui",
                "com.android.documentsui",
                "com.google.android.apps.nfiles",
                "com.sec.android.app.myfiles",
                "com.mi.android.globalFileexplorer",
                "com.coloros.filemanager",
                "com.oneplus.filemanager",
                "com.huawei.hidisk"
            )

            for (pkg in knownFileManagerPackages) {
                val launchIntent = packageManager.getLaunchIntentForPackage(pkg)
                if (launchIntent != null) {
                    launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(launchIntent)
                    return true
                }
            }

            false
        } catch (e: Exception) {
            false
        }
    }
}
