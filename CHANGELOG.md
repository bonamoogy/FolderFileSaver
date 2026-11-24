## 3.1.0 (24 Nov 2026)

* **iOS support.** Images and videos are saved to the Photos library (add-only permission); other files go to a folder named after the app in the Files app. Supports CocoaPods and Swift Package Manager.
* New API that returns a `SavedFile` (name, path, URI and location) and throws a `FolderFileSaverException` with an error code when saving fails:
  * `saveFile(path, folderName:, deleteOriginal:)`
  * `saveResizedImage(path, width:, height:, folderName:, deleteOriginal:)`
  * `saveFromUrl(url, fileName:, folderName:, headers:)`
  * `openAppSettings()`
* `saveFromUrl` can set the file name and send request headers.
* The plugin now asks for the storage permission on Android 9 and lower by itself.
* More file types are sorted into the right folder (gif, webp, heic, mov, wav, aac…).
* Deprecated: `saveImage`, `saveFileToFolderExt`, `saveFileIntoCustomDir`, `saveFileFromUrl`, `openSetting` and `getPlatformVersion`. They still work and will be removed in 4.0.0. See the README for the new names.
* Rewritten example app, with integration tests.

### Fixes and Android updates

* Update Android build to AGP 9.1, Kotlin 2.4, Gradle 9.3.1, Java 17 and compileSdk 36 (Gradle Kotlin DSL)
* Keep working in apps still on AGP 8 / older Flutter versions
* Fix crash when the screen rotates or the activity is detached
* Fix app crash when an image cannot be decoded or a save fails; failures now return `null` and are logged
* Fix concurrent calls overwriting each other's settings
* Fix MIME type sent to MediaStore (`image/png` instead of `png`)
* `saveImage` no longer overwrites the original file when resizing, keeps JPEG format, and keeps the aspect ratio when only width or height is given
* `saveFileFromUrl` uses the real file name (from the URL or server), handles URLs without an extension or with a query string, and follows http/https redirects
* Same file name saved twice is stored as `name (1).ext` instead of failing
* Fix saving on Android 9 and lower when the app folder did not exist yet
* File extensions are matched case-insensitively (`.JPG` goes to Pictures)
* `WRITE_EXTERNAL_STORAGE` is only requested up to Android 9; Android 10+ needs no permission
* Remove the undeclared kotlinx.coroutines dependency

## 3.0.1 (24 Sept 2024)

* Fix bug application name
* update gradle

## 3.0.0 (21 Sept 2024)

* migrate to Flutter 3.0
* update new method save file from url
* update Readme

## 2.0.5 (01 Feb 2023)

* Fix error

## 2.0.4 (11 May 2022)

* update pacakge from return uri after save to return path of file
* update README.md

## 2.0.3 (10 May 2022)

* Update package for Android 10 or higher
* update README.md

## 2.0.2 (02 May 2022)

* Add new method to save custom directory inside your app_named 
* change filenamed from <current_time_miliseconds> to <original_filenamed>
* update README.md
* uppdate main.dart example
* uppdate AndroidManifest.xml example/android/app/src/main
* update version

## 2.0.1 (02 May 2022)

* Fix incorrect `androidPackage" 

## 2.0.0 (01 May 2022)

* Migrate plugin
* Migrate to Null Safety
* remove permission on method, update doc
* added new params to removeOrigin file after save
* add package permission_handler to example plugin
* Update README.md
* Update CHANGELOG
* Update version to 2.0.0

## 1.0.0+2 (11 Nov 2020)

* Upgrade gradle-wrapper.properties distributionUrl from 4.10.2 to 5.1.1
* Update CHANGELOG

## 1.0.0+1 (31 Oct 2020)

* Fixed a little bug permission
* Remove method checkPermission
* Chane Example Plugin
* Update README.md
* Update README.md (example)
* Update CHANGELOG

## 1.0.0+0 (26 Oct 2020)

* Fixed a bug behavior permission which I just realized
* Chane Example Plugin
* Update README.md
* Update CHANGELOG

## 1.0.0 (16 Oct 2020)

* Migrate to AndroidX

## 0.4.0+0 (24 june 2020)

* Update README
* Update LICENSE

## 0.4.0 (25 jan 2020)

* Update Android Gradle Version from 3.2.1 to 3.4.0
* Update kotlin version from 1.2.71 to 1.3.50
* Fix Android The Android Gradle plugin supports only Kotlin Gradle plugin version 1.3.10 and higher

## 0.3.0

* Add Example to Copy File with local Path
* Update CHANGELOG
* Update README.md
* Update Example

## 0.2.0+1

* Update README.md

## 0.2.0

* Update CHANGELOG
* Fixes Open setting

## 0.0.2

* Update CHANGELOG
* Update README.md
* Add Comment API

## 0.0.1+1

* Update README.md
* Update LICENSE
* Update Example

## 0.0.1

* Initial release
