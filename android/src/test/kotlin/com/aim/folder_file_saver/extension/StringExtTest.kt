package com.aim.folder_file_saver.extension

import org.junit.jupiter.api.Test
import kotlin.test.assertEquals

class StringExtTest {

    @Test
    fun testGetLastPathAfterDot() {
        val url = "https://example.png"
        val result = ".png"
        assertEquals(result, url.getLastPathAfterDot())
    }
}