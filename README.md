# Folder File Saver

[![Pub Version](https://img.shields.io/pub/v/folder_file_saver)](https://pub.dev/packages/folder_file_saver)
[![GitHub](https://img.shields.io/github/license/bonamoogy/folderfilesaver)](https://github.com/bonamoogy/FolderFileSaver/blob/master/LICENSE)

### This Plugin provides
- Save file from URL
- Displays the file that you downloaded in Gallery And Media Player from Url
- Copy existing file to new Folder extension
- Create Folder of your File
   - Android Q or higher
     - jpg, png, jpeg = Pictures/appname Pictures
     - mp4 = Videos/appname Videos
     - mp3 = Musisc/appname Musics
     - m4a = Audiobooks/appname Audios
     - any extension = Documents/appname Documents
   - Under Android Q
     - jpg, png, jpeg = appname/Pictures
     - mp4 = appname/Videos
     - mp3 = appname/Musics
     - m4a = appname/Audios
     - any extension = appname/Documents
- Save file into your custom Directory
- Download images and resize width and height
- Open Settings device

#### Android
You need to add those permissions in AndroidManifest.xml in order the plugin to work
```
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```
#### IOS
>**Currently this Plugin not avaible for IOS**. 

### For demo

- git clone https://github.com/bonamoogy/FolderFileSaver/archive/master.zip
- cd folder_file_saver
- flutter pub get
- flutter run

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.
