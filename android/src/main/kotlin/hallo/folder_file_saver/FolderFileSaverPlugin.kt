package hallo.folder_file_saver

import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Environment
import android.provider.Settings
import androidx.core.content.ContextCompat

import android.app.Activity
import androidx.annotation.NonNull
import android.content.Context          

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
//import io.flutter.plugin.common.PluginRegistry.Registrar
//import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener

import java.io.File
import java.io.FileOutputStream
import java.io.IOException

const val CHANNEL_NAME = "folder_file_saver"

class FolderFileSaverPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    
    private lateinit var channel : MethodChannel
    private lateinit var context: Context
    private lateinit var activity: Activity

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        try {
            when (call.method) {
                "saveFileToFolderExt" -> {
                    val filePath = call.argument<String>("filePath")!!
                    val removeOriginFile: Boolean = call.argument<Boolean>("removeOriginFile")!!
                    result.success(saveFileToFolderExt(filePath,removeOriginFile))
                }
                "saveImage" -> {
                    val imagePath = call.argument<String>("pathImage")!!
                    val width: Int = call.argument<Int>("width")!!
                    val height: Int = call.argument<Int>("height")!!
                    val removeOriginFile: Boolean = call.argument<Boolean>("removeOriginFile")!!
                    if (width == 0 && height == 0) {
                        result.success(saveFileToFolderExt(imagePath,removeOriginFile))
                    } else {
                        val resultPath = saveFileToFolderExt(resizeTo(imagePath, width, height),removeOriginFile)
                        result.success(resultPath)
                    }
                }
                "openSetting" -> {
                    openSettingsPermission()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        } catch (e: IOException) {
            e.printStackTrace()
        }
        
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // Implements Activity Aware
    
    override fun onDetachedFromActivity() {
        // TODO("Not yet implemented")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        // TODO("Not yet implemented")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity;
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // TODO("Not yet implemented")
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

    private fun saveFileToFolderExt(filePath: String = "", removeOriginFile:Boolean = true): String {
        return try {
            val originalFile = File(filePath)
            val file = createFolderOfFile(originalFile.extension)
            originalFile.copyTo(file)
            if(removeOriginFile){
                originalFile.delete();
            }
            val uri = Uri.fromFile(file)
            context.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, uri))
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
        val file = ContextCompat.getExternalFilesDirs(context, null)
        val isNull = file == null
        val pathDir = File.separator + appNamed() + "/" + appNamed() + " " + folderExtNamed
        val storePath = Environment.getExternalStorageDirectory().absolutePath + pathDir
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
        var aI: ApplicationInfo? = null
        try {
            aI = context.packageManager.getApplicationInfo(context.packageName, 0)
        } catch (err: PackageManager.NameNotFoundException) {
            err.printStackTrace()
        }
        val appName: String
        appName = if (aI != null) {
            val cS = context.packageManager.getApplicationLabel(aI)
            StringBuilder(cS.length).append(cS).toString()
        } else {
            "Folder File Saver"
        }
        return appName
    }

    private fun openSettingsPermission() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${activity.packageName}"))
        intent.addCategory(Intent.CATEGORY_DEFAULT)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        activity.startActivity(intent)
    }
}