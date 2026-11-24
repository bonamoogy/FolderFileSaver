import Flutter

/// A failure with an error code that is sent to Dart as-is.
/// The codes must match `FolderFileSaverException` in Dart.
struct SaverError: Error {
  enum Code: String {
    case fileNotFound = "FILE_NOT_FOUND"
    case permissionDenied = "PERMISSION_DENIED"
    case downloadFailed = "DOWNLOAD_FAILED"
    case invalidImage = "INVALID_IMAGE"
    case invalidArgument = "INVALID_ARGUMENT"
    case saveFailed = "SAVE_FAILED"
  }

  let code: Code
  let message: String

  init(_ code: Code, _ message: String) {
    self.code = code
    self.message = message
  }

  var flutterError: FlutterError {
    FlutterError(code: code.rawValue, message: message, details: nil)
  }
}

/// Where a file ended up. Sent to Dart as a map.
struct SavedFile {
  let name: String
  let path: String?
  let uri: String
  let location: String

  var asDictionary: [String: Any] {
    var map: [String: Any] = ["name": name, "uri": uri, "location": location]
    if let path = path { map["path"] = path }
    return map
  }
}
