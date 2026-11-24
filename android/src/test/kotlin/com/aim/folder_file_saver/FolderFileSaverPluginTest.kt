package com.aim.folder_file_saver

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import org.mockito.ArgumentMatchers.any
import org.mockito.ArgumentMatchers.anyString
import org.mockito.ArgumentMatchers.eq
import org.mockito.Mockito

/*
 * Unit tests for the Kotlin side of the plugin. Run them from `example/android/` with
 * `./gradlew :folder_file_saver:testDebugUnitTest` after building the example app once.
 */
internal class FolderFileSaverPluginTest {
    @Test
    fun onMethodCall_getPlatformVersion_returnsExpectedValue() {
        val plugin = FolderFileSaverPlugin()

        val call = MethodCall("getPlatformVersion", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
    }

    @Test
    fun onMethodCall_unknownMethod_isNotImplemented() {
        val plugin = FolderFileSaverPlugin()
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(MethodCall("doesNotExist", null), mockResult)

        Mockito.verify(mockResult).notImplemented()
    }

    @Test
    fun onMethodCall_missingArgument_returnsError() {
        val plugin = FolderFileSaverPlugin()
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)

        plugin.onMethodCall(MethodCall("saveFileFromUrl", emptyMap<String, Any>()), mockResult)

        Mockito.verify(mockResult).error(eq("INVALID_ARGUMENT"), anyString(), any())
    }
}
