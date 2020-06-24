# folder_file_saver

[![Pub Version](https://img.shields.io/pub/v/folder_file_saver)](https://pub.dev/packages/folder_file_saver)
[![GitHub](https://img.shields.io/github/license/bonamoogy/folderfilesaver)](https://github.com/bonamoogy/FolderFileSaver/blob/master/LICENSE)

### This Plugin provides
- Displays the file that you downloaded in Gallery And Media Player from Url
- Copy existing file to new Folder extension
- Create Folder of your Downloaded
   - jpg, png, jpeg = appname/Pictures
   - mp4 = appname/Videos
   - mp3 = appname/Musics
   - m4a = appname/Audios
   - any extension = appname/Documents
- Download images and resize width and height
- Check permission user
   - if permission denied **require permission**
   - if permission denied with don't ask again **open settings app**
- Open Settings of device

#### Android
You need to request those permissions in AndroidManifest.xml in order the plugin to work
```
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```
#### IOS
>**Currently this Plugin not avaible for IOS**. 

### For demo

- git clone https://github.com/bonamoogy/FolderFileSaver/archive/master.zip
- cd folder_file_saver
- flutter packages get
- flutter run

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.
