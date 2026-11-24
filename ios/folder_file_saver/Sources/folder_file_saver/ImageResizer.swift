import UIKit

/// Writes resized copies of images. The original file is never changed.
enum ImageResizer {
  /// Resizes `source` to `width` x `height` pixels and writes it into
  /// `outputDirectory`. When one side is 0, it is calculated from the aspect
  /// ratio. JPEG stays JPEG; every other format is written as PNG.
  static func resize(_ source: URL, width: Int, height: Int, outputDirectory: URL) throws -> URL {
    guard FileManager.default.fileExists(atPath: source.path) else {
      throw SaverError(.fileNotFound, "File not found: \(source.path)")
    }
    guard let image = UIImage(contentsOfFile: source.path) else {
      throw SaverError(.invalidImage, "Not a readable image: \(source.lastPathComponent)")
    }

    // UIImage.size is in points and already takes the EXIF orientation into account.
    let originalSize = CGSize(
      width: image.size.width * image.scale,
      height: image.size.height * image.scale)
    let targetSize = FileNames.targetSize(original: originalSize, width: width, height: height)

    let format = UIGraphicsImageRendererFormat.default()
    format.scale = 1
    let resized = UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
      image.draw(in: CGRect(origin: .zero, size: targetSize))
    }

    let isJpeg = ["jpg", "jpeg"].contains(source.pathExtension.lowercased())
    let fileName = isJpeg
      ? source.lastPathComponent
      : source.deletingPathExtension().lastPathComponent + ".png"
    guard let data = isJpeg ? resized.jpegData(compressionQuality: 1) : resized.pngData() else {
      throw SaverError(.saveFailed, "Could not encode the resized image")
    }

    let output = outputDirectory.appendingPathComponent(fileName)
    do {
      try data.write(to: output)
    } catch {
      throw SaverError(.saveFailed, "Could not write the resized image: \(error.localizedDescription)")
    }
    return output
  }
}
