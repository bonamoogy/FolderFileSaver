# folder_file_saver

This Plugin provides:
- Displays the file that you downloaded in Gallery from Url
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

- git clone https://github.com/bonamoogy/FolderFileSaver.git
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
