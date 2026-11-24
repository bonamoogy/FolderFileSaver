/// Where a file was saved.
enum SaveLocation {
  /// Android `Pictures/` (or `<App name>/` on Android 9 and lower).
  pictures,

  /// Android `Movies/` (or `<App name>/` on Android 9 and lower).
  videos,

  /// Android `Music/` (or `<App name>/` on Android 9 and lower).
  music,

  /// Android `Audiobooks/` (or `<App name>/` on Android 9 and lower).
  audiobooks,

  /// Android `Documents/` (or `<App name>/` on Android 9 and lower).
  documents,

  /// The iOS Photos library.
  photos,

  /// The app's own folder, which iOS shows in the Files app.
  files,
}

/// The result of a successful save.
class SavedFile {
  const SavedFile({
    required this.name,
    required this.location,
    this.path,
    this.uri,
  });

  /// Builds a [SavedFile] from the map the platform side sends back.
  factory SavedFile.fromMap(Map<Object?, Object?> map) {
    final locationName = map['location'] as String?;
    return SavedFile(
      name: map['name'] as String? ?? '',
      path: map['path'] as String?,
      uri: map['uri'] as String?,
      location: SaveLocation.values.firstWhere(
        (location) => location.name == locationName,
        orElse: () => SaveLocation.documents,
      ),
    );
  }

  /// The file name it was saved under.
  ///
  /// This can differ from the original name. For example, `photo (1).jpg`
  /// when `photo.jpg` already existed.
  final String name;

  /// Absolute path of the saved file.
  ///
  /// `null` when the file went into the iOS Photos library, which has no
  /// file path. Use [uri] to refer to it instead.
  final String? path;

  /// A URI for the saved file:
  ///
  /// * Android 10 and higher: a `content://media/...` MediaStore URI.
  /// * Android 9 and lower, and iOS Files: a `file://` URI.
  /// * iOS Photos: `ph://<local identifier>` of the created asset.
  final String? uri;

  /// Which folder or library the file was saved into.
  final SaveLocation location;

  @override
  String toString() =>
      'SavedFile(name: $name, location: ${location.name}, path: $path, uri: $uri)';
}
