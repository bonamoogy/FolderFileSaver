package com.aim.folder_file_saver.utils

import java.io.File
import java.nio.file.Files
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class FileUtilsTest {

    private val mimeToExtension: (String) -> String? = {
        mapOf("image/png" to "png", "image/jpeg" to "jpg", "video/mp4" to "mp4")[it]
    }

    @Test
    fun categoryIsPickedFromExtensionIgnoringCase() {
        assertEquals(FileCategory.PICTURES, FileCategory.fromExtension("JPG"))
        assertEquals(FileCategory.PICTURES, FileCategory.fromExtension("png"))
        assertEquals(FileCategory.VIDEOS, FileCategory.fromExtension("mp4"))
        assertEquals(FileCategory.MUSIC, FileCategory.fromExtension("mp3"))
        assertEquals(FileCategory.AUDIOBOOKS, FileCategory.fromExtension("m4a"))
        assertEquals(FileCategory.DOCUMENTS, FileCategory.fromExtension("pdf"))
        assertEquals(FileCategory.DOCUMENTS, FileCategory.fromExtension(""))
        assertEquals(FileCategory.PICTURES, FileCategory.fromExtension("gif"))
        assertEquals(FileCategory.VIDEOS, FileCategory.fromExtension("MOV"))
        assertEquals(FileCategory.MUSIC, FileCategory.fromExtension("wav"))
    }

    @Test
    fun fileNameComesFromUrlPathWithoutQuery() {
        assertEquals(
            "fff.png",
            FileUtils.resolveDownloadFileName(
                "https://dummyimage.com/300/09f/fff.png?text=hi#top", null, "image/png",
                mimeToExtension, "fallback",
            ),
        )
    }

    @Test
    fun extensionIsAddedFromContentTypeWhenUrlHasNone() {
        assertEquals(
            "photo-1576039716094-066beef36943.jpg",
            FileUtils.resolveDownloadFileName(
                "https://images.unsplash.com/photo-1576039716094-066beef36943?ixlib=rb-1.2.1&q=80",
                null, "image/jpeg; charset=binary", mimeToExtension, "fallback",
            ),
        )
    }

    @Test
    fun contentDispositionWins() {
        assertEquals(
            "report 2024.pdf",
            FileUtils.resolveDownloadFileName(
                "https://example.com/download?id=1",
                "attachment; filename=\"report 2024.pdf\"", "application/pdf",
                mimeToExtension, "fallback",
            ),
        )
        assertEquals(
            "naïve file.txt",
            FileUtils.fileNameFromContentDisposition(
                "attachment; filename=\"fallback.txt\"; filename*=UTF-8''na%C3%AFve%20file.txt",
            ),
        )
    }

    @Test
    fun preferredNameWinsAndGetsAnExtension() {
        assertEquals(
            "my photo.png",
            FileUtils.resolveDownloadFileName(
                "https://example.com/a.jpg", "attachment; filename=\"b.jpg\"", "image/png",
                mimeToExtension, "fallback", preferredName = "my photo",
            ),
        )
    }

    @Test
    fun fallbackNameIsUsedForBareHost() {
        assertEquals(
            "fallback.png",
            FileUtils.resolveDownloadFileName(
                "https://example.com/", null, "image/png", mimeToExtension, "fallback",
            ),
        )
    }

    @Test
    fun sanitizeRemovesPathSeparators() {
        assertEquals("a_b_c.png", FileUtils.sanitizeFileName("a/b\\c.png"))
        assertEquals("My App", FileUtils.sanitizeFileName(" My App "))
    }

    @Test
    fun uniqueFileAddsCounter() {
        val dir = Files.createTempDirectory("ffs").toFile()
        try {
            assertEquals("a.png", FileUtils.uniqueFile(dir, "a.png").name)
            File(dir, "a.png").writeText("x")
            assertEquals("a (1).png", FileUtils.uniqueFile(dir, "a.png").name)
            File(dir, "a (1).png").writeText("x")
            assertEquals("a (2).png", FileUtils.uniqueFile(dir, "a.png").name)
        } finally {
            dir.deleteRecursively()
        }
    }

    @Test
    fun targetSizeKeepsAspectRatioWhenOneSideIsZero() {
        assertNull(FileUtils.targetSize(400, 200, 0, 0))
        assertEquals(100 to 100, FileUtils.targetSize(400, 200, 100, 100))
        assertEquals(100 to 50, FileUtils.targetSize(400, 200, 100, 0))
        assertEquals(200 to 100, FileUtils.targetSize(400, 200, 0, 100))
    }
}
