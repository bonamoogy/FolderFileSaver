package com.aim.folder_file_saver

import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import androidx.annotation.RequiresApi
import com.aim.folder_file_saver.utils.ErrorCode
import com.aim.folder_file_saver.utils.FileCategory
import com.aim.folder_file_saver.utils.FileUtils
import com.aim.folder_file_saver.utils.SaverException
import java.io.File

/** Where a file ended up. Sent to Dart as a map. */
data class SavedFile(val name: String, val path: String, val uri: String, val location: String) {
    fun toMap(): Map<String, String> =
        mapOf("name" to name, "path" to path, "uri" to uri, "location" to location)
}

/**
 * Copies files into shared storage, in a folder named after the app:
 *
 * - Android 10+ (API 29): through MediaStore, into e.g. `Pictures/<App name> Pictures/`.
 *   No permission needed.
 * - Android 9 and lower: straight to `/sdcard/<App name>/<App name> Pictures/`.
 *   Needs WRITE_EXTERNAL_STORAGE, which the plugin requests before calling this.
 */
class FileSaver(private val context: Context) {

    /**
     * Saves a copy of [source]. [folderName] replaces the type-based folder suffix,
     * e.g. "Wallpapers" gives "<App name> Wallpapers".
     */
    fun save(source: File, folderName: String?): SavedFile {
        if (!source.isFile) {
            throw SaverException(ErrorCode.FILE_NOT_FOUND, "File not found: ${source.path}")
        }

        val category = FileCategory.fromExtension(source.extension)
        val suffix = folderName?.let(FileUtils::sanitizeFileName)?.takeIf { it.isNotEmpty() }
            ?: category.folderName
        val folder = "${appName()} $suffix"

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                saveWithMediaStore(source, category, folder)
            } else {
                saveToExternalStorage(source, category, folder)
            }
        } catch (e: SaverException) {
            throw e
        } catch (e: Exception) {
            throw SaverException(ErrorCode.SAVE_FAILED, "Could not save ${source.name}: ${e.message}", e)
        }
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun saveWithMediaStore(source: File, category: FileCategory, folder: String): SavedFile {
        val resolver = context.contentResolver
        val (collection, baseDir) = mediaStoreTarget(category)
        val relativePath = "$baseDir/$folder"

        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, source.name)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeTypeOf(source))
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            // Hide the file from other apps until it is completely written.
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = resolver.insert(collection, values)
            ?: throw SaverException(ErrorCode.SAVE_FAILED, "MediaStore refused to create ${source.name} in $relativePath")

        try {
            val output = resolver.openOutputStream(uri)
                ?: throw SaverException(ErrorCode.SAVE_FAILED, "Could not open $uri for writing")
            output.use { out -> source.inputStream().use { it.copyTo(out) } }

            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw e
        }

        // MediaStore renames the file ("photo (1).jpg") when the name is taken.
        val savedName = queryString(uri, MediaStore.MediaColumns.DISPLAY_NAME) ?: source.name
        @Suppress("DEPRECATION")
        val path = queryString(uri, MediaStore.MediaColumns.DATA)
            ?: "${Environment.getExternalStorageDirectory().absolutePath}/$relativePath/$savedName"

        return SavedFile(savedName, path, uri.toString(), category.location)
    }

    @RequiresApi(Build.VERSION_CODES.Q)
    private fun mediaStoreTarget(category: FileCategory): Pair<Uri, String> = when (category) {
        FileCategory.PICTURES ->
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI to Environment.DIRECTORY_PICTURES
        FileCategory.VIDEOS ->
            MediaStore.Video.Media.EXTERNAL_CONTENT_URI to Environment.DIRECTORY_MOVIES
        FileCategory.MUSIC ->
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI to Environment.DIRECTORY_MUSIC
        FileCategory.AUDIOBOOKS ->
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI to Environment.DIRECTORY_AUDIOBOOKS
        FileCategory.DOCUMENTS ->
            MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY) to Environment.DIRECTORY_DOCUMENTS
    }

    private fun queryString(uri: Uri, column: String): String? =
        context.contentResolver.query(uri, arrayOf(column), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getString(0)?.takeIf { it.isNotEmpty() } else null
        }

    @Suppress("DEPRECATION")
    private fun saveToExternalStorage(source: File, category: FileCategory, folder: String): SavedFile {
        val dir = File(Environment.getExternalStorageDirectory(), "${appName()}/$folder")
        if (!dir.isDirectory && !dir.mkdirs()) {
            throw SaverException(ErrorCode.SAVE_FAILED, "Could not create ${dir.path}")
        }

        val target = FileUtils.uniqueFile(dir, source.name)
        source.copyTo(target)

        // Make the file show up in the gallery and media apps right away.
        MediaScannerConnection.scanFile(context, arrayOf(target.absolutePath), arrayOf(mimeTypeOf(target)), null)

        return SavedFile(target.name, target.absolutePath, Uri.fromFile(target).toString(), category.location)
    }

    private fun appName(): String {
        val label = runCatching {
            context.applicationInfo.loadLabel(context.packageManager).toString()
        }.getOrNull()
        return label?.let(FileUtils::sanitizeFileName)?.takeIf { it.isNotEmpty() } ?: "Folder File Saver"
    }

    private fun mimeTypeOf(file: File): String =
        MimeTypeMap.getSingleton().getMimeTypeFromExtension(file.extension.lowercase())
            ?: "application/octet-stream"
}
