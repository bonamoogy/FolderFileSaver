package com.aim.folder_file_saver

import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import android.util.Log
import android.webkit.MimeTypeMap
import androidx.annotation.RequiresApi
import com.aim.folder_file_saver.utils.Constant
import com.aim.folder_file_saver.utils.FileCategory
import com.aim.folder_file_saver.utils.FileUtils
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
import java.net.HttpURLConnection
import java.net.URL
import java.util.UUID
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/** FolderFileSaverPlugin */
class FolderFileSaverPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private var channel: MethodChannel? = null
    private var applicationContext: Context? = null
    private var activity: Activity? = null

    private var executor: ExecutorService? = null
    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }

    // region FlutterPlugin / ActivityAware

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        executor = Executors.newCachedThreadPool()
        channel = MethodChannel(binding.binaryMessenger, Constant.FOLDER_FILE_SAVER).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        executor?.shutdown()
        executor = null
        applicationContext = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // endregion

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            Constant.GET_PLATFORM_VERSION -> result.success("Android ${Build.VERSION.RELEASE}")

            Constant.SAVE_IMAGE -> {
                val pathImage = call.requireArgument<String>("pathImage", result) ?: return
                val width = call.argument<Int>("width") ?: 0
                val height = call.argument<Int>("height") ?: 0
                val removeOriginFile = call.argument<Boolean>("removeOriginFile") ?: false
                runInBackground(result, Constant.SAVE_IMAGE) {
                    saveImage(File(pathImage), width, height, removeOriginFile)
                }
            }

            Constant.SAVE_FILE_TO_FOLDER_EXT -> {
                val filePath = call.requireArgument<String>("filePath", result) ?: return
                val removeOriginFile = call.argument<Boolean>("removeOriginFile") ?: false
                runInBackground(result, Constant.SAVE_FILE_TO_FOLDER_EXT) {
                    saveFile(File(filePath), dirNamed = null, removeOriginFile)
                }
            }

            Constant.SAVE_FILE_CUSTOM_DIR -> {
                val filePath = call.requireArgument<String>("filePath", result) ?: return
                val dirNamed = call.requireArgument<String>("dirNamed", result) ?: return
                val removeOriginFile = call.argument<Boolean>("removeOriginFile") ?: false
                runInBackground(result, Constant.SAVE_FILE_CUSTOM_DIR) {
                    saveFile(File(filePath), dirNamed, removeOriginFile)
                }
            }

            Constant.SAVE_FILE_FROM_URL -> {
                val url = call.requireArgument<String>("url", result) ?: return
                runInBackground(result, Constant.SAVE_FILE_FROM_URL) {
                    saveFileFromUrl(url)
                }
            }

            Constant.OPEN_SETTING -> result.success(openAppSettings())

            else -> result.notImplemented()
        }
    }

    // region Saving

    /**
     * Copies [source] into the app's folder for its file type. Returns the absolute
     * path of the saved file.
     */
    private fun saveFile(source: File, dirNamed: String?, removeOriginFile: Boolean): String {
        if (!source.isFile) throw IOException("File not found: ${source.path}")

        val category = FileCategory.fromExtension(source.extension)
        val folderName = buildFolderName(category, dirNamed)
        val savedPath = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveWithMediaStore(source, category, folderName)
        } else {
            saveToExternalStorage(source, folderName)
        }

        if (removeOriginFile && !source.delete()) {
            Log.w(TAG, "Saved, but could not delete the original file: ${source.path}")
        }
        return savedPath
    }

    /** "<App name> Pictures", or "<App name> <dirNamed>" for a custom directory. */
    private fun buildFolderName(category: FileCategory, dirNamed: String?): String {
        val suffix = dirNamed?.let(FileUtils::sanitizeFileName)?.takeIf { it.isNotEmpty() }
            ?: category.folderName
        return "${appName()} $suffix"
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun saveWithMediaStore(source: File, category: FileCategory, folderName: String): String {
        val resolver = requireContext().contentResolver
        val (collection, baseDir) = when (category) {
            FileCategory.PICTURES ->
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI to Environment.DIRECTORY_PICTURES
            FileCategory.VIDEOS ->
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI to Environment.DIRECTORY_MOVIES
            FileCategory.MUSIC ->
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI to Environment.DIRECTORY_MUSIC
            FileCategory.AUDIOBOOKS ->
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI to Environment.DIRECTORY_AUDIOBOOKS
            FileCategory.DOCUMENTS ->
                MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY) to
                    Environment.DIRECTORY_DOCUMENTS
        }
        val relativePath = "$baseDir/$folderName"

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, source.name)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeTypeOf(source))
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        val uri = resolver.insert(collection, values)
            ?: throw IOException("MediaStore refused to create ${source.name} in $relativePath")

        try {
            resolver.openOutputStream(uri)?.use { output ->
                source.inputStream().use { input -> input.copyTo(output) }
            } ?: throw IOException("Could not open $uri for writing")

            resolver.update(
                uri,
                ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) },
                null,
                null,
            )
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }

        return pathFromMediaStoreUri(uri, relativePath, source.name)
    }

    /**
     * Resolves the real file path of a MediaStore item. MediaStore may rename the
     * file (e.g. "image (1).png") when one with the same name already exists.
     */
    @RequiresApi(Build.VERSION_CODES.Q)
    private fun pathFromMediaStoreUri(uri: Uri, relativePath: String, fallbackName: String): String {
        @Suppress("DEPRECATION")
        val dataColumn = MediaStore.MediaColumns.DATA
        val projection = arrayOf(dataColumn, MediaStore.MediaColumns.DISPLAY_NAME)

        var displayName = fallbackName
        requireContext().contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val data = cursor.getString(0)
                if (!data.isNullOrEmpty()) return data
                cursor.getString(1)?.let { displayName = it }
            }
        }

        @Suppress("DEPRECATION")
        val root = Environment.getExternalStorageDirectory().absolutePath
        return "$root/$relativePath/$displayName"
    }

    /** Android 9 and below: copy straight into /sdcard/<App name>/<folderName>/. */
    private fun saveToExternalStorage(source: File, folderName: String): String {
        @Suppress("DEPRECATION")
        val dir = File(Environment.getExternalStorageDirectory(), "${appName()}/$folderName")
        if (!dir.isDirectory && !dir.mkdirs()) {
            throw IOException("Could not create ${dir.path}. Is WRITE_EXTERNAL_STORAGE granted?")
        }

        val target = FileUtils.uniqueFile(dir, source.name)
        source.copyTo(target)
        MediaScannerConnection.scanFile(
            requireContext(),
            arrayOf(target.absolutePath),
            arrayOf(mimeTypeOf(target)),
            null,
        )
        return target.absolutePath
    }

    private fun saveImage(source: File, width: Int, height: Int, removeOriginFile: Boolean): String {
        if (width <= 0 && height <= 0) return saveFile(source, null, removeOriginFile)
        if (!source.isFile) throw IOException("File not found: ${source.path}")

        val tempDir = newCallTempDir()
        try {
            val resized = resizeImage(source, width, height, tempDir)
            val savedPath = saveFile(resized, dirNamed = null, removeOriginFile = false)
            if (removeOriginFile) source.delete()
            return savedPath
        } finally {
            tempDir.deleteRecursively()
        }
    }

    /**
     * Writes a resized copy of [source] into [outputDir], leaving the original
     * untouched. JPEG and WebP stay in their format, everything else becomes PNG.
     */
    private fun resizeImage(source: File, width: Int, height: Int, outputDir: File): File {
        val original = BitmapFactory.decodeFile(source.path)
            ?: throw IOException("Could not decode image: ${source.path}")

        try {
            val (targetWidth, targetHeight) =
                FileUtils.targetSize(original.width, original.height, width, height)
                    ?: (original.width to original.height)
            val scaled = Bitmap.createScaledBitmap(original, targetWidth, targetHeight, true)

            val extension = source.extension.lowercase()
            val (format, fileName) = when (extension) {
                "jpg", "jpeg" -> Bitmap.CompressFormat.JPEG to source.name
                "webp" -> webpFormat() to source.name
                "png" -> Bitmap.CompressFormat.PNG to source.name
                else -> Bitmap.CompressFormat.PNG to "${source.nameWithoutExtension}.png"
            }

            val output = File(outputDir, fileName)
            try {
                FileOutputStream(output).use { stream ->
                    if (!scaled.compress(format, 100, stream)) {
                        throw IOException("Could not encode resized image")
                    }
                }
            } finally {
                if (scaled !== original) scaled.recycle()
            }
            return output
        } finally {
            original.recycle()
        }
    }

    @Suppress("DEPRECATION")
    private fun webpFormat(): Bitmap.CompressFormat =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Bitmap.CompressFormat.WEBP_LOSSLESS
        } else {
            Bitmap.CompressFormat.WEBP
        }

    // endregion

    // region Download

    private fun saveFileFromUrl(fileUrl: String): String {
        val tempDir = newCallTempDir()
        try {
            val connection = openFollowingRedirects(fileUrl)
            val downloaded = try {
                val fileName = FileUtils.resolveDownloadFileName(
                    url = connection.url.toString(),
                    contentDisposition = connection.getHeaderField("Content-Disposition"),
                    contentType = connection.contentType,
                    extensionForMimeType = { MimeTypeMap.getSingleton().getExtensionFromMimeType(it) },
                    fallbackBaseName = "file_${System.currentTimeMillis()}",
                )
                File(tempDir, fileName).also { file ->
                    connection.inputStream.use { input ->
                        FileOutputStream(file).use { output -> input.copyTo(output) }
                    }
                }
            } finally {
                connection.disconnect()
            }
            return saveFile(downloaded, dirNamed = null, removeOriginFile = true)
        } finally {
            tempDir.deleteRecursively()
        }
    }

    /**
     * Opens [fileUrl] and follows up to [MAX_REDIRECTS] redirects, including
     * http ↔ https ones that HttpURLConnection does not follow on its own.
     */
    private fun openFollowingRedirects(fileUrl: String): HttpURLConnection {
        var url = URL(fileUrl)
        repeat(MAX_REDIRECTS + 1) {
            val connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                connectTimeout = TIMEOUT_MS
                readTimeout = TIMEOUT_MS
                instanceFollowRedirects = true
            }
            val code = connection.responseCode
            when {
                code in 200..299 -> return connection
                code in 300..399 -> {
                    val location = connection.getHeaderField("Location")
                    connection.disconnect()
                    if (location.isNullOrEmpty()) throw IOException("Redirect without Location from $url")
                    url = URL(url, location)
                }
                else -> {
                    connection.disconnect()
                    throw IOException("Download failed with HTTP $code: $url")
                }
            }
        }
        throw IOException("Too many redirects: $fileUrl")
    }

    // endregion

    // region Helpers

    private fun openAppSettings(): Boolean {
        val context: Context = activity ?: applicationContext ?: return false
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", context.packageName, null),
        ).apply {
            addCategory(Intent.CATEGORY_DEFAULT)
            if (context !is Activity) addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return try {
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Could not open app settings", e)
            false
        }
    }

    private fun appName(): String {
        val context = applicationContext ?: return DEFAULT_APP_NAME
        val label = runCatching {
            context.applicationInfo.loadLabel(context.packageManager).toString()
        }.getOrNull()
        return label?.let(FileUtils::sanitizeFileName)?.takeIf { it.isNotEmpty() }
            ?: DEFAULT_APP_NAME
    }

    private fun mimeTypeOf(file: File): String =
        MimeTypeMap.getSingleton().getMimeTypeFromExtension(file.extension.lowercase())
            ?: "application/octet-stream"

    /**
     * A fresh folder in the app cache for one call's downloads or resized images,
     * so concurrent calls with the same file name never collide.
     */
    private fun newCallTempDir(): File {
        val dir = File(requireContext().cacheDir, "folder_file_saver/${UUID.randomUUID()}")
        if (!dir.mkdirs()) throw IOException("Could not create temp folder ${dir.path}")
        return dir
    }

    private fun requireContext(): Context =
        applicationContext ?: throw IllegalStateException("Plugin is not attached to an engine")

    private fun <T> MethodCall.requireArgument(key: String, result: Result): T? {
        val value = argument<T>(key)
        if (value == null) result.error("INVALID_ARGUMENT", "'$key' is required", null)
        return value
    }

    /**
     * Runs [block] off the main thread and replies on the main thread. Failures are
     * logged and reported as `null`, which is what the Dart API has always returned.
     */
    private fun runInBackground(result: Result, tag: String, block: () -> String?) {
        val executor = executor
        if (executor == null || executor.isShutdown) {
            result.error("NOT_ATTACHED", "Plugin is not attached to an engine", null)
            return
        }
        executor.execute {
            val value = try {
                block()
            } catch (e: Throwable) {
                Log.e(TAG, "[$tag] ${e.message}", e)
                null
            }
            mainHandler.post { result.success(value) }
        }
    }

    // endregion

    private companion object {
        const val TAG = "FolderFileSaver"
        const val DEFAULT_APP_NAME = "Folder File Saver"
        const val MAX_REDIRECTS = 5
        const val TIMEOUT_MS = 30_000
    }
}
