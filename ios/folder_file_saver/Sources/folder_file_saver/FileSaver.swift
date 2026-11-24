import Photos
import UIKit

/// Saves files where the user can find them:
///
/// - Images and videos go to the Photos library. This only needs the
///   "add photos" permission (`NSPhotoLibraryAddUsageDescription`).
/// - Everything else goes to `Documents/<App name> <Type>/`, which the Files
///   app shows when the app sets `UIFileSharingEnabled` and
///   `LSSupportsOpeningDocumentsInPlace` in its Info.plist.
final class FileSaver {
  private let fileManager = FileManager.default

  /// Saves a copy of `source`. `folderName` replaces the type-based folder
  /// suffix for files saved to the Files app. Photos has no folders.
  func save(_ source: URL, folderName: String?) async throws -> SavedFile {
    guard fileManager.fileExists(atPath: source.path) else {
      throw SaverError(.fileNotFound, "File not found: \(source.path)")
    }

    let category = FileCategory(fileExtension: source.pathExtension)
    switch category {
    case .photo:
      return try await saveToPhotos(source, as: .photo)
    case .video where UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(source.path):
      return try await saveToPhotos(source, as: .video)
    default:
      let appName = FileNames.appName(from: Bundle.main.infoDictionary)
      let folder = FileNames.folderName(appName: appName, custom: folderName, category: category)
      return try saveToFiles(source, folder: folder)
    }
  }

  // MARK: - Photos library

  private func saveToPhotos(_ source: URL, as type: PHAssetResourceType) async throws -> SavedFile {
    guard await Self.requestAddPermission() else {
      throw SaverError(
        .permissionDenied,
        "Photos access was denied. Add NSPhotoLibraryAddUsageDescription to Info.plist, "
          + "then let the user allow it in Settings.")
    }

    let localIdentifier: String? = try await withCheckedThrowingContinuation { continuation in
      var identifier: String?
      PHPhotoLibrary.shared().performChanges({
        let options = PHAssetResourceCreationOptions()
        options.originalFilename = source.lastPathComponent
        let request = PHAssetCreationRequest.forAsset()
        request.addResource(with: type, fileURL: source, options: options)
        identifier = request.placeholderForCreatedAsset?.localIdentifier
      }, completionHandler: { success, error in
        if success {
          continuation.resume(returning: identifier)
        } else {
          let reason = error?.localizedDescription ?? "unknown error"
          continuation.resume(throwing: SaverError(
            .saveFailed, "Photos could not save \(source.lastPathComponent): \(reason)"))
        }
      })
    }

    return SavedFile(
      name: source.lastPathComponent,
      path: nil,
      uri: "ph://\(localIdentifier ?? "")",
      location: "photos")
  }

  /// Asks for permission to add to Photos, if the user was not asked before.
  private static func requestAddPermission() async -> Bool {
    if #available(iOS 14, *) {
      switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
      case .authorized, .limited:
        return true
      case .notDetermined:
        return await withCheckedContinuation { continuation in
          PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            continuation.resume(returning: status == .authorized || status == .limited)
          }
        }
      default:
        return false
      }
    }

    switch PHPhotoLibrary.authorizationStatus() {
    case .authorized:
      return true
    case .notDetermined:
      return await withCheckedContinuation { continuation in
        PHPhotoLibrary.requestAuthorization { status in
          continuation.resume(returning: status == .authorized)
        }
      }
    default:
      return false
    }
  }

  // MARK: - Files app

  private func saveToFiles(_ source: URL, folder: String) throws -> SavedFile {
    do {
      let documents = try fileManager.url(
        for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
      let directory = documents.appendingPathComponent(folder, isDirectory: true)
      try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

      let target = FileNames.uniqueURL(in: directory, fileName: source.lastPathComponent)
      try fileManager.copyItem(at: source, to: target)

      return SavedFile(
        name: target.lastPathComponent,
        path: target.path,
        uri: target.absoluteString,
        location: "files")
    } catch {
      throw SaverError(.saveFailed, "Could not save \(source.lastPathComponent): \(error.localizedDescription)")
    }
  }
}
