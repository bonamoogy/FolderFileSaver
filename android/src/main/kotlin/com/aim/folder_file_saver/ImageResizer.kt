package com.aim.folder_file_saver

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import com.aim.folder_file_saver.utils.ErrorCode
import com.aim.folder_file_saver.utils.FileUtils
import com.aim.folder_file_saver.utils.SaverException
import java.io.File
import java.io.FileOutputStream

/** Writes resized copies of images. The original file is never changed. */
object ImageResizer {

    /**
     * Resizes [source] to [width] x [height] and writes it into [outputDir].
     * When one side is 0, it is calculated from the aspect ratio.
     * JPEG stays JPEG; every other format is written as PNG.
     */
    fun resize(source: File, width: Int, height: Int, outputDir: File): File {
        if (!source.isFile) {
            throw SaverException(ErrorCode.FILE_NOT_FOUND, "File not found: ${source.path}")
        }
        val original = BitmapFactory.decodeFile(source.path)
            ?: throw SaverException(ErrorCode.INVALID_IMAGE, "Not a readable image: ${source.name}")

        try {
            val (targetWidth, targetHeight) =
                FileUtils.targetSize(original.width, original.height, width, height)
                    ?: (original.width to original.height)
            val resized = Bitmap.createScaledBitmap(original, targetWidth, targetHeight, true)

            val isJpeg = source.extension.lowercase() in setOf("jpg", "jpeg")
            val format = if (isJpeg) Bitmap.CompressFormat.JPEG else Bitmap.CompressFormat.PNG
            val fileName = if (isJpeg) source.name else "${source.nameWithoutExtension}.png"
            val output = File(outputDir, fileName)

            try {
                FileOutputStream(output).use { stream ->
                    if (!resized.compress(format, 100, stream)) {
                        throw SaverException(ErrorCode.SAVE_FAILED, "Could not encode the resized image")
                    }
                }
            } finally {
                if (resized !== original) resized.recycle()
            }
            return output
        } finally {
            original.recycle()
        }
    }
}
