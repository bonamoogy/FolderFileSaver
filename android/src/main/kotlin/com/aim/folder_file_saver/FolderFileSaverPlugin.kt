package com.aim.folder_file_saver

import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import android.util.Log
import androidx.annotation.RequiresApi
import com.aim.folder_file_saver.extension.getLastPathAfterDot
import com.aim.folder_file_saver.utils.Constant
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlin.NullPointerException

/** FolderFileSaverPlugin */
class FolderFileSaverPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel

    private var applicationContext: Context? = null
    private var activity: Activity? = null

    private var dirNamed: String = ""
    private var removeOriginFile: Boolean = false
    private var originalFile: File? = null

    private fun launchInMain(block: suspend () -> Unit) {
        CoroutineScope(Dispatchers.Main).launch {
            block()
        }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, Constant.FOLDER_FILE_SAVER)
        channel.setMethodCallHandler(this)
        applicationContext = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        dirNamed = ""
        when (call.method) {
            Constant.GET_PLATFORM_VERSION -> result.success("Android ${Build.VERSION.RELEASE}")
            Constant.SAVE_IMAGE -> handleSaveImage(call, result)
            Constant.SAVE_FILE_TO_FOLDER_EXT -> handleSaveFileToFolderExt(call, result)
            Constant.SAVE_FILE_CUSTOM_DIR -> handleSaveCustomDir(call, result)
            Constant.SAVE_FILE_FROM_URL -> handleSaveFileFromUrl(call, result)
            Constant.OPEN_SETTING -> {
                openAppSettings()
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    private fun handleSaveImage(call: MethodCall, result: Result) {
        val pathImage = call.argument<String>("pathImage")!!
        val width = call.argument<Int>("width")!!
        val height = call.argument<Int>("height")!!
        removeOriginFile = call.argument<Boolean>("removeOriginFile")!!
        originalFile = File(pathImage)

        launchInMain {
            val resultPath = if (width == 0 && height == 0) {
                saveFileToFolderExt()
            } else {
                resizeTo(width, height)
                saveFileToFolderExt()
            }
            result.success(resultPath)
        }
    }

    private fun handleSaveCustomDir(call: MethodCall, result: Result) {
        dirNamed = call.argument<String>("dirNamed")!!
        val filePath = call.argument<String>("filePath")!!
        removeOriginFile = call.argument<Boolean>("removeOriginFile")!!
        originalFile = File(filePath)

        launchInMain {
            result.success(saveFileToFolderExt())
        }
    }

    private fun handleSaveFileToFolderExt(call: MethodCall, result: Result) {
        val filePath = call.argument<String>("filePath")!!
        removeOriginFile = call.argument<Boolean>("removeOriginFile")!!
        originalFile = File(filePath)

        launchInMain {
            result.success(saveFileToFolderExt())
        }
    }

    private fun handleSaveFileFromUrl(call: MethodCall, result: Result) {
        val url = call.argument<String>("url")!!
        launchInMain {
            result.success(saveFileFromUrl(url))
        }
    }

    private suspend fun saveFileToFolderExt(): String? {
        return try {
            val result = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                saveImageToByMediaStore()
            } else {
                val resultFile = createFolderOfFile()
                originalFile?.copyTo(resultFile)
                sendMediaScanBroadcast(resultFile)
                resultFile.absolutePath
            }

            if (removeOriginFile) originalFile?.delete()
            result
        } catch (e: IOException) {
            logError("[saveFileToFolderExt]", e)
            null
        }
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private suspend fun saveImageToByMediaStore(): String? = withContext(Dispatchers.IO) {
        try {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, originalFile?.name)
                put(MediaStore.MediaColumns.MIME_TYPE, originalFile?.extension)
                put(MediaStore.MediaColumns.RELATIVE_PATH, getMediaStoreDir())
            }

            val uri = applicationContext?.contentResolver?.insert(getMediaStoreUri(), values)
            uri?.let {
                applicationContext?.contentResolver?.openOutputStream(it)?.use { outputStream ->
                    outputStream.write(originalFile?.readBytes())
                }
                return@withContext getPathFromUri(it)
            }

            null
        } catch (e: Exception) {
            logError("[saveImageToByMediaStore]", e)
            null
        }
    }

    private fun createFolderOfFile(): File {
        val storePath =
            "${Environment.getExternalStorageDirectory().absolutePath}${getFolderFileAppNamed()}"
        val appDir = File(storePath)
        if (!appDir.exists()) appDir.mkdir()
        requireNotNull(originalFile?.name) { "File name is null" }
        return File(appDir, originalFile!!.name)
    }

    private fun getFolderFileAppNamed(): String {
        val folderExtNamed = buildFolderExtNamed()
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            File.separator + appNamed() + " " + folderExtNamed
        } else {
            File.separator + appNamed() + "/" + appNamed() + " " + folderExtNamed
        }
    }

    private fun buildFolderExtNamed(): String = dirNamed.ifEmpty {
        when (originalFile?.extension) {
            "jpg", "png", "jpeg" -> "Pictures"
            "mp4" -> "Videos"
            "mp3", "m4a" -> "Audios"
            else -> "Documents"
        }
    }

    private fun getPathFromUri(uri: Uri): String {
        val list = arrayOf("_data")
        val cursor = applicationContext?.contentResolver?.query(uri, list, null, null, null)
        var result = ""
        try {
            if (cursor?.moveToFirst() == true) {
                result = cursor.getString(0)
            } else {
                throw Exception("File uri not found! $uri")
            }
        } catch (e: Exception) {
            Log.e("getPathFromUri", e.toString())
            e.printStackTrace()
        } finally {
            cursor?.close()
        }
        return result
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun getMediaStoreUri(): Uri {
        return when (originalFile?.extension) {
            "jpg", "png", "jpeg" -> MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            "mp4" -> MediaStore.Video.Media.EXTERNAL_CONTENT_URI
            "mp3", "m4a" -> MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            else -> MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
        }
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun getMediaStoreDir(): String {
        val result = when (originalFile?.extension) {
            "jpg", "png", "jpeg" -> Environment.DIRECTORY_PICTURES
            "mp4" -> Environment.DIRECTORY_MOVIES
            "mp3" -> Environment.DIRECTORY_MUSIC
            "m4a" -> Environment.DIRECTORY_AUDIOBOOKS
            else -> Environment.DIRECTORY_DOCUMENTS
        }
        return result + getFolderFileAppNamed()
    }

    private fun appNamed(): String {
        try {
            var aI: ApplicationInfo? = null
            if (applicationContext?.packageName == null) {
                throw NullPointerException("Package name is null")
            }

            aI = applicationContext?.packageManager?.getApplicationInfo(
                applicationContext!!.packageName,
                0
            )

            if (aI == null) {
                throw NullPointerException("Application Info is null")
            }

            val cS = applicationContext?.packageManager?.getApplicationLabel(aI)

            if (cS == null) {
                throw NullPointerException("Application name is null")
            }

            return StringBuilder(cS.length).append(cS).toString()
        } catch (err: PackageManager.NameNotFoundException) {
            err.printStackTrace()
            logError("appNamed", err)
            return "Folder File Saver"
        }
    }

    private fun resizeTo(width: Int, height: Int): String {
        if (originalFile == null) throw NullPointerException("File is null")

        val file = File(originalFile!!.path)
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

    private suspend fun saveFileFromUrl(fileUrl: String): String? {
        return withContext(Dispatchers.IO) {
            try {

                val file =
                    File(
                        applicationContext!!.cacheDir,
                        "${System.currentTimeMillis()}-${fileUrl.getLastPathAfterDot()}"
                    )

                val url = URL(fileUrl)
                val connection: HttpURLConnection = url.openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.connect()

                if (connection.responseCode != HttpURLConnection.HTTP_OK) {
                    throw Exception("Failed to download image: ${connection.responseCode}")
                }

                val inputStream: InputStream = connection.inputStream

                FileOutputStream(file).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }

                connection.disconnect()

                originalFile = file
                removeOriginFile = true
                return@withContext saveFileToFolderExt()
            } catch (e: Exception) {
                println("Error: ${e.message}")
                return@withContext null
            }
        }
    }

    private fun openAppSettings() {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:${activity?.packageName}")
        )
        intent.addCategory(Intent.CATEGORY_DEFAULT)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        activity?.startActivity(intent)
    }

    private fun sendMediaScanBroadcast(file: File) {
        val uri = Uri.fromFile(file)
        applicationContext?.sendBroadcast(Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE, uri))
    }

    private fun logError(tag: String, e: Exception) {
        Log.e("[$tag]", e.message ?: "unknown error")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        TODO("Not yet implemented")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        TODO("Not yet implemented")
    }

    override fun onDetachedFromActivity() {
        TODO("Not yet implemented")
    }
}
