import XCTest

@testable import folder_file_saver

// Unit tests for the iOS side of folder_file_saver.
//
// Run them from Xcode (open example/ios/Runner.xcworkspace, then Product > Test)
// or with:
//   xcodebuild test -workspace Runner.xcworkspace -scheme Runner \
//     -destination 'platform=iOS Simulator,name=iPhone 16'

class FileCategoryTests: XCTestCase {
  func testCategoryIsPickedFromExtensionIgnoringCase() {
    XCTAssertEqual(FileCategory(fileExtension: "JPG"), .photo)
    XCTAssertEqual(FileCategory(fileExtension: "heic"), .photo)
    XCTAssertEqual(FileCategory(fileExtension: "MOV"), .video)
    XCTAssertEqual(FileCategory(fileExtension: "mp4"), .video)
    XCTAssertEqual(FileCategory(fileExtension: "mp3"), .audio)
    XCTAssertEqual(FileCategory(fileExtension: "m4a"), .audio)
    XCTAssertEqual(FileCategory(fileExtension: "pdf"), .document)
    XCTAssertEqual(FileCategory(fileExtension: ""), .document)
  }

  func testFolderNameUsesTypeOrCustomName() {
    XCTAssertEqual(
      FileNames.folderName(appName: "My App", custom: nil, category: .audio), "My App Audios")
    XCTAssertEqual(
      FileNames.folderName(appName: "My App", custom: "  ", category: .document), "My App Documents")
    XCTAssertEqual(
      FileNames.folderName(appName: "My App", custom: "Reports/2024", category: .document),
      "My App Reports_2024")
  }
}

class FileNamesTests: XCTestCase {
  func testAppNamePrefersDisplayName() {
    XCTAssertEqual(
      FileNames.appName(from: ["CFBundleDisplayName": "Nice App", "CFBundleName": "nice_app"]),
      "Nice App")
    XCTAssertEqual(FileNames.appName(from: ["CFBundleName": "nice_app"]), "nice_app")
    XCTAssertEqual(FileNames.appName(from: nil), FileNames.defaultAppName)
  }

  func testSanitizeRemovesPathSeparators() {
    XCTAssertEqual(FileNames.sanitize("a/b\\c.png"), "a_b_c.png")
    XCTAssertEqual(FileNames.sanitize(" My App "), "My App")
    XCTAssertEqual(FileNames.sanitize("..hidden."), "hidden")
  }

  func testUniqueURLAddsCounter() {
    let directory = URL(fileURLWithPath: "/docs")
    var existing: Set<String> = []
    let unique = { FileNames.uniqueURL(in: directory, fileName: "a.png") { existing.contains($0) } }

    XCTAssertEqual(unique().lastPathComponent, "a.png")
    existing.insert("/docs/a.png")
    XCTAssertEqual(unique().lastPathComponent, "a (1).png")
    existing.insert("/docs/a (1).png")
    XCTAssertEqual(unique().lastPathComponent, "a (2).png")
  }

  func testUniqueURLWithoutExtension() {
    let url = FileNames.uniqueURL(in: URL(fileURLWithPath: "/docs"), fileName: "notes") {
      $0 == "/docs/notes"
    }
    XCTAssertEqual(url.lastPathComponent, "notes (1)")
  }

  func testDownloadNameUsesSuggestedName() {
    XCTAssertEqual(
      FileNames.downloadName(preferred: nil, suggested: "photo.jpg", fallback: "download"),
      "photo.jpg")
    XCTAssertEqual(
      FileNames.downloadName(preferred: nil, suggested: nil, fallback: "download"), "download")
  }

  func testPreferredDownloadNameWinsAndBorrowsExtension() {
    XCTAssertEqual(
      FileNames.downloadName(preferred: "my photo", suggested: "abc.png", fallback: "download"),
      "my photo.png")
    XCTAssertEqual(
      FileNames.downloadName(preferred: "report.pdf", suggested: "abc.bin", fallback: "download"),
      "report.pdf")
  }

  func testTargetSizeKeepsAspectRatioWhenOneSideIsZero() {
    let original = CGSize(width: 400, height: 200)
    XCTAssertEqual(FileNames.targetSize(original: original, width: 0, height: 0), original)
    XCTAssertEqual(
      FileNames.targetSize(original: original, width: 100, height: 100),
      CGSize(width: 100, height: 100))
    XCTAssertEqual(
      FileNames.targetSize(original: original, width: 100, height: 0),
      CGSize(width: 100, height: 50))
    XCTAssertEqual(
      FileNames.targetSize(original: original, width: 0, height: 100),
      CGSize(width: 200, height: 100))
  }
}

class SavedFileTests: XCTestCase {
  func testPhotosResultHasNoPath() {
    let saved = SavedFile(name: "a.png", path: nil, uri: "ph://ABC", location: "photos")
    let map = saved.asDictionary
    XCTAssertEqual(map["name"] as? String, "a.png")
    XCTAssertEqual(map["uri"] as? String, "ph://ABC")
    XCTAssertEqual(map["location"] as? String, "photos")
    XCTAssertNil(map["path"])
  }

  func testErrorCodesMatchDart() {
    XCTAssertEqual(SaverError(.permissionDenied, "x").flutterError.code, "PERMISSION_DENIED")
    XCTAssertEqual(SaverError(.fileNotFound, "x").flutterError.code, "FILE_NOT_FOUND")
  }
}
