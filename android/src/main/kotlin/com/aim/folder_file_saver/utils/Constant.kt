package com.aim.folder_file_saver.utils

/** Method channel names. Must match `lib/src/method_names.dart`. */
object Constant {
    const val CHANNEL = "folder_file_saver"

    const val SAVE_FILE = "saveFile"
    const val SAVE_RESIZED_IMAGE = "saveResizedImage"
    const val SAVE_FROM_URL = "saveFromUrl"
    const val OPEN_APP_SETTINGS = "openAppSettings"
    const val GET_PLATFORM_VERSION = "getPlatformVersion"
}

/** Error codes. Must match `FolderFileSaverException` in Dart. */
object ErrorCode {
    const val FILE_NOT_FOUND = "FILE_NOT_FOUND"
    const val PERMISSION_DENIED = "PERMISSION_DENIED"
    const val DOWNLOAD_FAILED = "DOWNLOAD_FAILED"
    const val INVALID_IMAGE = "INVALID_IMAGE"
    const val INVALID_ARGUMENT = "INVALID_ARGUMENT"
    const val SAVE_FAILED = "SAVE_FAILED"
}

/** A failure with an [ErrorCode] that is sent to Dart as-is. */
class SaverException(val code: String, message: String, cause: Throwable? = null) :
    Exception(message, cause)
