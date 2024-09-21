package com.aim.folder_file_saver.extension


fun String.getLastPathAfterDot(): String {
    return this.substring(this.lastIndexOf("."))
}