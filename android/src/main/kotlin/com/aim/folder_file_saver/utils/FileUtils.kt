package com.aim.folder_file_saver.utils

import java.io.File
import java.net.URI
import java.net.URLDecoder

/** The kind of folder a file is saved into, picked from its extension. */
enum class FileCategory(val folderName: String) {
    PICTURES("Pictures"),
    VIDEOS("Videos"),
    MUSIC("Audios"),
    AUDIOBOOKS("Audios"),
    DOCUMENTS("Documents");

    companion object {
        fun fromExtension(extension: String): FileCategory =
            when (extension.lowercase()) {
                "jpg", "jpeg", "png" -> PICTURES
                "mp4" -> VIDEOS
                "mp3" -> MUSIC
                "m4a" -> AUDIOBOOKS
                else -> DOCUMENTS
            }
    }
}

/** Pure helpers kept free of Android APIs so they can be unit tested on the JVM. */
object FileUtils {

    private val invalidFileNameChars = Regex("""[\\/:*?"<>|\u0000-\u001F]""")

    /** Replaces characters that are not allowed in a file or folder name. */
    fun sanitizeFileName(name: String): String =
        name.replace(invalidFileNameChars, "_").trim().trim('.')

    /** Reads the file name from a `Content-Disposition` header, if it has one. */
    fun fileNameFromContentDisposition(header: String?): String? {
        if (header.isNullOrBlank()) return null

        // RFC 5987: filename*=UTF-8''encoded%20name.png
        Regex("""filename\*\s*=\s*([^']*)'[^']*'([^;]+)""", RegexOption.IGNORE_CASE)
            .find(header)?.let { match ->
                val charset = match.groupValues[1].ifBlank { "UTF-8" }
                val decoded = runCatching {
                    URLDecoder.decode(match.groupValues[2].trim(), charset)
                }.getOrNull()
                if (!decoded.isNullOrBlank()) return decoded
            }

        return Regex("""filename\s*=\s*"?([^";]+)"?""", RegexOption.IGNORE_CASE)
            .find(header)
            ?.groupValues?.get(1)
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
    }

    /** Returns the last path segment of [url] without its query or fragment. */
    fun fileNameFromUrl(url: String): String? {
        val path = runCatching { URI(url).path }.getOrNull()
            ?: url.substringBefore('?').substringBefore('#')
        return path.trimEnd('/').substringAfterLast('/').takeIf { it.isNotBlank() }
    }

    /**
     * Picks a safe file name for a download.
     *
     * The name comes from the `Content-Disposition` header, then the URL path. When
     * that name has no extension, [extensionForMimeType] supplies one from the
     * response's `Content-Type`.
     */
    fun resolveDownloadFileName(
        url: String,
        contentDisposition: String?,
        contentType: String?,
        extensionForMimeType: (String) -> String?,
        fallbackBaseName: String,
    ): String {
        val rawName = fileNameFromContentDisposition(contentDisposition)
            ?: fileNameFromUrl(url)
        var name = rawName?.let(::sanitizeFileName)?.takeIf { it.isNotEmpty() }
            ?: fallbackBaseName

        if (File(name).extension.isEmpty()) {
            val mimeType = contentType?.substringBefore(';')?.trim()?.lowercase()
            val extension = mimeType?.let(extensionForMimeType)
            if (!extension.isNullOrEmpty()) name = "$name.$extension"
        }
        return name
    }

    /** Returns a file in [dir] named [fileName], adding " (1)", " (2)"… if it already exists. */
    fun uniqueFile(dir: File, fileName: String): File {
        var candidate = File(dir, fileName)
        if (!candidate.exists()) return candidate

        val base = candidate.nameWithoutExtension
        val extension = candidate.extension.let { if (it.isEmpty()) "" else ".$it" }
        var index = 1
        while (candidate.exists()) {
            candidate = File(dir, "$base ($index)$extension")
            index++
        }
        return candidate
    }

    /**
     * Works out the size to resize an image to. When only one of [width] or
     * [height] is given (the other is 0), the original aspect ratio is kept.
     * Returns null when no resize is needed.
     */
    fun targetSize(originalWidth: Int, originalHeight: Int, width: Int, height: Int): Pair<Int, Int>? {
        if (width <= 0 && height <= 0) return null
        if (originalWidth <= 0 || originalHeight <= 0) return null

        val targetWidth = if (width > 0) width else
            (originalWidth.toLong() * height / originalHeight).toInt().coerceAtLeast(1)
        val targetHeight = if (height > 0) height else
            (originalHeight.toLong() * width / originalWidth).toInt().coerceAtLeast(1)
        return targetWidth to targetHeight
    }
}
