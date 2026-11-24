package com.aim.folder_file_saver

import android.webkit.MimeTypeMap
import com.aim.folder_file_saver.utils.ErrorCode
import com.aim.folder_file_saver.utils.FileUtils
import com.aim.folder_file_saver.utils.SaverException
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.MalformedURLException
import java.net.URL

/** Downloads a URL to a local file. */
object Downloader {
    private const val MAX_REDIRECTS = 5
    private const val TIMEOUT_MS = 30_000

    /**
     * Downloads [url] into [outputDir] and returns the file. The name is [fileName]
     * if given, otherwise it comes from the server or the URL.
     */
    fun download(url: String, outputDir: File, fileName: String?, headers: Map<String, String>): File {
        val connection = try {
            openFollowingRedirects(url, headers)
        } catch (e: SaverException) {
            throw e
        } catch (e: MalformedURLException) {
            throw SaverException(ErrorCode.INVALID_ARGUMENT, "Invalid URL: $url", e)
        } catch (e: IOException) {
            throw SaverException(ErrorCode.DOWNLOAD_FAILED, "Could not download $url: ${e.message}", e)
        }

        try {
            val name = FileUtils.resolveDownloadFileName(
                url = connection.url.toString(),
                contentDisposition = connection.getHeaderField("Content-Disposition"),
                contentType = connection.contentType,
                extensionForMimeType = { MimeTypeMap.getSingleton().getExtensionFromMimeType(it) },
                fallbackBaseName = "download_${System.currentTimeMillis()}",
                preferredName = fileName,
            )
            val file = File(outputDir, name)
            connection.inputStream.use { input -> file.outputStream().use { input.copyTo(it) } }
            return file
        } catch (e: IOException) {
            throw SaverException(ErrorCode.DOWNLOAD_FAILED, "Download of $url was interrupted: ${e.message}", e)
        } finally {
            connection.disconnect()
        }
    }

    /**
     * Opens [url], following up to [MAX_REDIRECTS] redirects, including the
     * http ↔ https ones that HttpURLConnection does not follow on its own.
     */
    private fun openFollowingRedirects(url: String, headers: Map<String, String>): HttpURLConnection {
        var current = URL(url)
        repeat(MAX_REDIRECTS + 1) {
            if (current.protocol != "http" && current.protocol != "https") {
                throw SaverException(ErrorCode.INVALID_ARGUMENT, "Only http and https URLs are supported: $current")
            }
            val connection = (current.openConnection() as HttpURLConnection).apply {
                connectTimeout = TIMEOUT_MS
                readTimeout = TIMEOUT_MS
                headers.forEach { (key, value) -> setRequestProperty(key, value) }
            }
            val status = connection.responseCode
            when (status) {
                in 200..299 -> return connection
                in 300..399 -> {
                    val location = connection.getHeaderField("Location")
                    connection.disconnect()
                    if (location.isNullOrEmpty()) {
                        throw SaverException(ErrorCode.DOWNLOAD_FAILED, "Redirect without a Location header from $current")
                    }
                    current = URL(current, location)
                }
                else -> {
                    connection.disconnect()
                    throw SaverException(ErrorCode.DOWNLOAD_FAILED, "HTTP $status from $current")
                }
            }
        }
        throw SaverException(ErrorCode.DOWNLOAD_FAILED, "Too many redirects from $url")
    }
}
