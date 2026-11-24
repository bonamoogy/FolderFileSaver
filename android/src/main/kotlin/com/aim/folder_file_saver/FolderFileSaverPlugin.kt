package com.aim.folder_file_saver

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import com.aim.folder_file_saver.utils.Constant
import com.aim.folder_file_saver.utils.ErrorCode
import com.aim.folder_file_saver.utils.SaverException
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.File
import java.util.UUID
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Connects the Dart API to [FileSaver], [ImageResizer] and [Downloader].
 *
 * File work runs on a background thread and replies on the main thread. On
 * Android 9 and lower, the storage permission is requested before saving.
 */
class FolderFileSaverPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private var channel: MethodChannel? = null
    private var context: Context? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var executor: ExecutorService? = null
    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }

    /** Callbacks waiting for the answer to the storage permission dialog. */
    private val permissionCallbacks = mutableListOf<(Boolean) -> Unit>()

    // region Lifecycle

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        executor = Executors.newCachedThreadPool()
        channel = MethodChannel(binding.binaryMessenger, Constant.CHANNEL).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        executor?.shutdown()
        executor = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
    }

    // endregion

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            Constant.GET_PLATFORM_VERSION -> result.success("Android ${Build.VERSION.RELEASE}")
            Constant.OPEN_APP_SETTINGS -> result.success(openAppSettings())

            Constant.SAVE_FILE -> {
                val filePath = call.requireString("filePath", result) ?: return
                val folderName = call.argument<String>("folderName")
                val deleteOriginal = call.argument<Boolean>("deleteOriginal") ?: false
                saveInBackground(result) { saver, _ ->
                    val source = File(filePath)
                    saver.save(source, folderName).also { if (deleteOriginal) source.delete() }
                }
            }

            Constant.SAVE_RESIZED_IMAGE -> {
                val imagePath = call.requireString("imagePath", result) ?: return
                val width = call.argument<Int>("width") ?: 0
                val height = call.argument<Int>("height") ?: 0
                val folderName = call.argument<String>("folderName")
                val deleteOriginal = call.argument<Boolean>("deleteOriginal") ?: false
                if (width <= 0 && height <= 0) {
                    result.error(ErrorCode.INVALID_ARGUMENT, "Give a width or a height greater than 0", null)
                    return
                }
                saveInBackground(result) { saver, tempDir ->
                    val source = File(imagePath)
                    val resized = ImageResizer.resize(source, width, height, tempDir)
                    saver.save(resized, folderName).also { if (deleteOriginal) source.delete() }
                }
            }

            Constant.SAVE_FROM_URL -> {
                val url = call.requireString("url", result) ?: return
                val fileName = call.argument<String>("fileName")
                val folderName = call.argument<String>("folderName")
                val headers = call.argument<Map<String, String>>("headers").orEmpty()
                saveInBackground(result) { saver, tempDir ->
                    val downloaded = Downloader.download(url, tempDir, fileName, headers)
                    saver.save(downloaded, folderName)
                }
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Gets the storage permission if needed, then runs [save] on a background
     * thread with a fresh temp folder that is deleted afterwards.
     */
    private fun saveInBackground(result: Result, save: (FileSaver, tempDir: File) -> SavedFile) {
        val context = context
        val executor = executor
        if (context == null || executor == null || executor.isShutdown) {
            result.error(ErrorCode.SAVE_FAILED, "The plugin is not attached to a Flutter engine", null)
            return
        }

        withStoragePermission { granted ->
            if (!granted) {
                result.error(
                    ErrorCode.PERMISSION_DENIED,
                    "Storage permission is needed to save files on Android 9 and lower",
                    null,
                )
                return@withStoragePermission
            }

            executor.execute {
                val tempDir = File(context.cacheDir, "folder_file_saver/${UUID.randomUUID()}")
                try {
                    tempDir.mkdirs()
                    val saved = save(FileSaver(context), tempDir)
                    mainHandler.post { result.success(saved.toMap()) }
                } catch (e: SaverException) {
                    Log.w(TAG, e.message, e)
                    mainHandler.post { result.error(e.code, e.message, null) }
                } catch (e: Throwable) {
                    Log.e(TAG, "Unexpected error", e)
                    mainHandler.post { result.error(ErrorCode.SAVE_FAILED, e.message ?: e.toString(), null) }
                } finally {
                    tempDir.deleteRecursively()
                }
            }
        }
    }

    // region Storage permission (Android 9 and lower only)

    private fun withStoragePermission(callback: (Boolean) -> Unit) {
        val needsPermission = Build.VERSION.SDK_INT in Build.VERSION_CODES.M until Build.VERSION_CODES.Q
        if (!needsPermission ||
            context?.checkSelfPermission(STORAGE_PERMISSION) == PackageManager.PERMISSION_GRANTED
        ) {
            callback(true)
            return
        }

        val activity = activityBinding?.activity
        if (activity == null) {
            callback(false)
            return
        }

        permissionCallbacks += callback
        // Only one dialog at a time; later calls wait for the same answer.
        if (permissionCallbacks.size == 1) {
            activity.requestPermissions(arrayOf(STORAGE_PERMISSION), PERMISSION_REQUEST_CODE)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false

        val granted = grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        val callbacks = permissionCallbacks.toList()
        permissionCallbacks.clear()
        callbacks.forEach { it(granted) }
        return true
    }

    // endregion

    private fun openAppSettings(): Boolean {
        val context: Context = activityBinding?.activity ?: context ?: return false
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", context.packageName, null),
        )
        if (context !is Activity) intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        return try {
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Could not open the app settings", e)
            false
        }
    }

    /** Reads a required string argument, or replies with an error and returns null. */
    private fun MethodCall.requireString(key: String, result: Result): String? {
        val value = argument<String>(key)
        if (value.isNullOrEmpty()) {
            result.error(ErrorCode.INVALID_ARGUMENT, "'$key' is required", null)
            return null
        }
        return value
    }

    private companion object {
        const val TAG = "FolderFileSaver"
        const val STORAGE_PERMISSION = Manifest.permission.WRITE_EXTERNAL_STORAGE
        const val PERMISSION_REQUEST_CODE = 0x4653 // "FS"
    }
}
