package hallo.folder_file_saver

//import io.flutter.plugin.common.PluginRegistry.Registrar
//import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener

import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.OutputStream


const val CHANNEL_NAME = "folder_file_saver"

class FolderFileSaverPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var activity: Activity

    private var dirNamed: String = ""
    private var removeOriginFile: Boolean = false
    private lateinit var originalFile: File

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
                    removeOriginFile = call.argument<Boolean>("removeOriginFile")!!
                    originalFile = File(filePath)
                    result.success(saveFileToFolderExt())
                }
                "saveImage" -> {
                    val pathImage = call.argument<String>("pathImage")!!
                    val width: Int = call.argument<Int>("width")!!
                    val height: Int = call.argument<Int>("height")!!
                    removeOriginFile = call.argument<Boolean>("removeOriginFile")!!
                    originalFile = File(pathImage)
                    if (width == 0 && height == 0) {
                        result.success(saveFileToFolderExt())
                    } else {
                        resizeTo(width, height)
                        val resultPath = saveFileToFolderExt()
                        result.success(resultPath)
                    }
                }
                "saveFileCustomDir" -> {
                    dirNamed = call.argument<String>("dirNamed")!!
                    val filePath = call.argument<String>("filePath")!!
                    removeOriginFile = call.argument<Boolean>("removeOriginFile")!!
                    originalFile = File(filePath)
                    result.success(saveFileToFolderExt())
                }
                "openSetting" -> {
                    openSettingsPermission()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        } catch (e: IOException) {
            e.printStackTrace()
        } finally {
            dirNamed = ""
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

    private fun resizeTo(width: Int, height: Int): String {
        val file = File(originalFile.path)
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

    private fun saveFileToFolderExt(): String {
        return try {
            val result: String
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                result = saveImageToByMediaStore()
            } else {
                val resultFile = createFolderOfFile()
                result = resultFile.absolutePath
                originalFile.copyTo(resultFile)
                val uri = Uri.fromFile(resultFile)
                context.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, uri))
            }
            if (removeOriginFile) {
                originalFile.delete();
            }
            return result
        } catch (e: IOException) {
            e.printStackTrace()
            ""
        }
    }

    private fun getFolderFileAppNamed(): String {
        val folderExtNamed = buildFolderExtNamed()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            File.separator + appNamed() + " " + folderExtNamed
        } else {
            File.separator + appNamed() + "/" + appNamed() + " " + folderExtNamed
        }
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun saveImageToByMediaStore(): String {
        val values = ContentValues()
        values.put(MediaStore.MediaColumns.DISPLAY_NAME, originalFile.name)
        values.put(MediaStore.MediaColumns.MIME_TYPE, originalFile.extension)
        values.put(MediaStore.MediaColumns.RELATIVE_PATH, getMediaStoreDir())
        val uri = context.contentResolver.insert(getMediaStoreUri(), values)
        val outputStream: OutputStream = context.contentResolver.openOutputStream(uri!!)!!
        outputStream.write(originalFile.readBytes())
        outputStream.close()
        return getPathFromUri(uri)
    }

    private fun getPathFromUri(uri: Uri): String {
        val list = arrayOf("_data")
        val cursor = context.contentResolver.query(uri, list, null, null, null)
        var result = ""
        try {
            if (cursor?.moveToFirst() == true) {
                result = cursor.getString(0)
            }
            throw Exception("File uri not found! ${uri.toString()}")
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            cursor?.close()
        }
        return result
    }

    private fun createFolderOfFile(): File {
        val storePath = Environment.getExternalStorageDirectory().absolutePath + getFolderFileAppNamed()
        val appDir = File(storePath)
        if (!appDir.exists()) {
            appDir.mkdir()
        }
        val fileNamed = originalFile.name
        return File(appDir, fileNamed)
    }

    private fun buildFolderExtNamed(): String {
        if (!dirNamed.isNullOrEmpty()) {
            return dirNamed
        }
        return when (originalFile.extension) {
            "jpg", "png", "jpeg" -> "Pictures"
            "mp4" -> "Videos"
            "mp3" -> "Musics"
            "m4a" -> "Audios"
            else -> "Documents"
        }
    }


    private fun getMediaStoreDir(): String {
        val result = when (originalFile.extension) {
            "jpg", "png", "jpeg" -> Environment.DIRECTORY_PICTURES
            "mp4" -> Environment.DIRECTORY_MOVIES
            "mp3" -> Environment.DIRECTORY_MUSIC
            "m4a" -> Environment.DIRECTORY_AUDIOBOOKS
            else -> Environment.DIRECTORY_DOCUMENTS
        }
        return result + getFolderFileAppNamed()
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun getMediaStoreUri(): Uri {
        return when (originalFile.extension) {
            "jpg", "png", "jpeg" -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            "mp4" -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            "mp3", "m4a" -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            else -> MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        }
    }

    private fun appNamed(): String {
        var aI: ApplicationInfo? = null
        try {
            aI = context.packageManager.getApplicationInfo(context.packageName, 0)
        } catch (err: PackageManager.NameNotFoundException) {
            err.printStackTrace()
        }
        return if (aI != null) {
            val cS = context.packageManager.getApplicationLabel(aI)
            StringBuilder(cS.length).append(cS).toString()
        } else {
            "Folder File Saver"
        }
    }

    private fun openSettingsPermission() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${activity.packageName}"))
        intent.addCategory(Intent.CATEGORY_DEFAULT)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        activity.startActivity(intent)
    }
}