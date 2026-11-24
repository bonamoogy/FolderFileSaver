import CoreGraphics
import Foundation

// Pure helpers with no UIKit or Photos dependency, so they can be unit tested
// anywhere. The Android equivalents live in `FileUtils.kt`.

/// The kind of file being saved, picked from its extension.
enum FileCategory: Equatable {
  case photo
  case video
  case audio
  case document

  init(fileExtension: String) {
    switch fileExtension.lowercased() {
    case "jpg", "jpeg", "png", "gif", "heic", "heif", "webp":
      self = .photo
    case "mp4", "mov", "m4v":
      self = .video
    case "mp3", "m4a", "wav", "aac", "ogg", "flac", "opus":
      self = .audio
    default:
      self = .document
    }
  }

  /// Default suffix of the app folder in the Files app, e.g. "<App name> Audios".
  var folderSuffix: String {
    switch self {
    case .photo: return "Pictures"
    case .video: return "Videos"
    case .audio: return "Audios"
    case .document: return "Documents"
    }
  }
}

enum FileNames {
  static let defaultAppName = "Folder File Saver"

  /// The app's display name from `info`, used to name its folders.
  static func appName(from info: [String: Any]?) -> String {
    let name = (info?["CFBundleDisplayName"] as? String) ?? (info?["CFBundleName"] as? String)
    let sanitized = sanitize(name ?? "")
    return sanitized.isEmpty ? defaultAppName : sanitized
  }

  /// "<App name> <folderName>", or "<App name> <type folder>" when `folderName` is empty.
  static func folderName(appName: String, custom: String?, category: FileCategory) -> String {
    let suffix = sanitize(custom ?? "")
    return "\(appName) \(suffix.isEmpty ? category.folderSuffix : suffix)"
  }

  /// Replaces characters that are not allowed in a file or folder name.
  static func sanitize(_ name: String) -> String {
    let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|").union(.controlCharacters)
    return name.components(separatedBy: invalid).joined(separator: "_")
      .trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: ".")))
  }

  /// A URL in `directory` named `fileName`, adding " (1)", " (2)"… if it exists.
  static func uniqueURL(
    in directory: URL,
    fileName: String,
    fileExists: (String) -> Bool = FileManager.default.fileExists(atPath:)
  ) -> URL {
    var candidate = directory.appendingPathComponent(fileName)
    let base = (fileName as NSString).deletingPathExtension
    let fileExtension = (fileName as NSString).pathExtension
    var index = 1
    while fileExists(candidate.path) {
      let name = fileExtension.isEmpty ? "\(base) (\(index))" : "\(base) (\(index)).\(fileExtension)"
      candidate = directory.appendingPathComponent(name)
      index += 1
    }
    return candidate
  }

  /// The name to save a download under.
  ///
  /// `suggested` is what the server or URL suggests (`URLResponse.suggestedFilename`).
  /// A `preferred` name from the caller wins, and borrows the suggested extension
  /// when it has none.
  static func downloadName(preferred: String?, suggested: String?, fallback: String) -> String {
    let suggestedName = sanitize(suggested ?? "")
    let base = suggestedName.isEmpty ? fallback : suggestedName

    let custom = sanitize(preferred ?? "")
    guard !custom.isEmpty else { return base }

    let suggestedExtension = (base as NSString).pathExtension
    if (custom as NSString).pathExtension.isEmpty, !suggestedExtension.isEmpty {
      return "\(custom).\(suggestedExtension)"
    }
    return custom
  }

  /// The size to resize an image to. When `width` or `height` is 0, it is
  /// calculated from the aspect ratio. Same rules as `FileUtils.targetSize` on Android.
  static func targetSize(original: CGSize, width: Int, height: Int) -> CGSize {
    guard original.width > 0, original.height > 0, width > 0 || height > 0 else { return original }
    let targetWidth = width > 0
      ? CGFloat(width)
      : max(1, (original.width * CGFloat(height) / original.height).rounded(.down))
    let targetHeight = height > 0
      ? CGFloat(height)
      : max(1, (original.height * CGFloat(width) / original.width).rounded(.down))
    return CGSize(width: targetWidth, height: targetHeight)
  }
}
