package hallo.folder_file_saver

import android.Manifest
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Environment
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class FolderFileSaverPlugin(private val registrar: Registrar) : MethodCallHandler {

    private val permission = Manifest.permission.WRITE_EXTERNAL_STORAGE

    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "folder_file_saver")
            channel.setMethodCallHandler(FolderFileSaverPlugin(registrar))
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "saveFileToFolderExt" -> {
                val filePath = call.argument<String>("filePath")!!
                result.success(saveFileToFolderExt(filePath))
            }
            "saveImage" -> {
                val imagePath = call.argument<String>("pathImage")!!
                val width: Int = call.argument<Int>("width")!!
                val height: Int = call.argument<Int>("height")!!
                if (width == 0 && height == 0) {
                    result.success(saveFileToFolderExt(imagePath))
                } else {
                    try {
                        result.success(saveFileToFolderExt(resizeTo(imagePath, width, height)))
                    } catch (e: IOException) {
                        e.printStackTrace()
                    }
                }
            }
            "getPermission" -> result.success(getPermission())
            "openSetting" -> {
                openSettingsPermission()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun resizeTo(pathImage: String, width: Int, height: Int): String {
        val file = File(pathImage)
        val b = BitmapFactory.decodeFile(file.path)
        val out = Bitmap.createScaledBitmap(b, width, height, false)

        try {
            val fOut = FileOutputStream(file)
            out.compress(Bitmap.CompressFormat.PNG, 100, fOut)
            fOut.flush()
            fOut.close()
            b.recycle()
            out.recycle()
        } catch (e: IOException) {
            e.printStackTrace()
        }
        return file.path
    }

    private fun saveFileToFolderExt(filePath: String = ""): String {
        val ctx = registrar.activeContext().applicationContext
        return try {
            val originalFile = File(filePath)
            val file = createFolderOfFile(originalFile.extension)
            originalFile.copyTo(file)

            val uri = Uri.fromFile(file)

            ctx.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, uri))
            return uri.toString()
        } catch (e: IOException) {
            e.printStackTrace()
            ""
        }
    }

    private fun createFolderOfFile(extension: String = ""): File {
        val folderExtNamed: String = when (extension) {
            "jpg", "png", "jpeg" -> "Pictures"
            "mp4" -> "Videos"
            "mp3" -> "Musics"
            "m4a" -> "Audios"
            else -> "Documents"
        }
        val storePath = Environment.getExternalStorageDirectory().absolutePath + File.separator + appNamed() + "/" + appNamed() + " " + folderExtNamed
        val appDir = File(storePath)
        if (!appDir.exists()) {
            appDir.mkdir()
        }
        var fileNamed = System.currentTimeMillis().toString()
        if (extension.isNotEmpty()) {
            fileNamed += (".$extension")
        }
        return File(appDir, fileNamed)
    }

    private fun appNamed(): String {
        val ctx = registrar.activeContext().applicationContext
        var aI: ApplicationInfo? = null
        try {
            aI = ctx.packageManager.getApplicationInfo(ctx.packageName, 0)
        } catch (err: PackageManager.NameNotFoundException) {
            err.printStackTrace()
        }
        val appName: String
        appName = if (aI != null) {
            val cS = ctx.packageManager.getApplicationLabel(aI)
            StringBuilder(cS.length).append(cS).toString()
        } else {
            "Folder File Saver"
        }
        return appName
    }

    private fun getPermission(): Int {
        val cp: Int = checkPermission()
        if (cp == 1) {
            requirePermission()
        } else if (cp == 2) {
            openSettingsPermission()
        }
        return cp
    }

    private fun requirePermission() {
        ActivityCompat.requestPermissions(registrar.activity(), arrayOf(permission), 0)
    }

    private fun checkPermission(): Int {
        var stat = 0
        val ctx = registrar.context()
        val ac = registrar.activity()
        val pW = ContextCompat.checkSelfPermission(ctx, permission)
        if (pW == PackageManager.PERMISSION_DENIED) {
            val askAgain = ActivityCompat.shouldShowRequestPermissionRationale(ac, permission)
            stat = if (askAgain) {
                1
            } else {
                2
            }
        }
        return stat
    }

    private fun openSettingsPermission() {
        val activity = registrar.activity()
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${activity.packageName}"))
        intent.addCategory(Intent.CATEGORY_DEFAULT)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        activity.startActivity(intent)
    }
}
