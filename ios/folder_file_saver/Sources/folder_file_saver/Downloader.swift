import Foundation

/// Downloads a URL to a local file.
enum Downloader {
  /// Downloads `urlString` into `outputDirectory` and returns the file. The
  /// name is `fileName` if given, otherwise it comes from the server or the URL.
  static func download(
    _ urlString: String,
    to outputDirectory: URL,
    fileName: String?,
    headers: [String: String]
  ) async throws -> URL {
    guard let url = URL(string: urlString),
          let scheme = url.scheme?.lowercased(),
          scheme == "http" || scheme == "https"
    else {
      throw SaverError(.invalidArgument, "Only http and https URLs are supported: \(urlString)")
    }

    var request = URLRequest(url: url, timeoutInterval: 30)
    for (field, value) in headers {
      request.setValue(value, forHTTPHeaderField: field)
    }

    let (downloaded, response) = try await fetch(request, into: outputDirectory)

    if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
      try? FileManager.default.removeItem(at: downloaded)
      throw SaverError(.downloadFailed, "HTTP \(http.statusCode) from \(urlString)")
    }

    let name = FileNames.downloadName(
      preferred: fileName,
      suggested: response.suggestedFilename,
      fallback: "download_\(Int(Date().timeIntervalSince1970))")
    let target = outputDirectory.appendingPathComponent(name)
    do {
      try FileManager.default.moveItem(at: downloaded, to: target)
    } catch {
      throw SaverError(.saveFailed, "Could not store the download: \(error.localizedDescription)")
    }
    return target
  }

  /// Runs a download task. The system deletes its temporary file as soon as
  /// the completion handler returns, so the file is moved into `directory` first.
  /// URLSession follows redirects on its own.
  private static func fetch(_ request: URLRequest, into directory: URL) async throws -> (URL, URLResponse) {
    try await withCheckedThrowingContinuation { continuation in
      let task = URLSession.shared.downloadTask(with: request) { location, response, error in
        if let error = error {
          continuation.resume(throwing: SaverError(
            .downloadFailed,
            "Could not download \(request.url?.absoluteString ?? ""): \(error.localizedDescription)"))
          return
        }
        guard let location = location, let response = response else {
          continuation.resume(throwing: SaverError(.downloadFailed, "Empty response"))
          return
        }

        let kept = directory.appendingPathComponent(UUID().uuidString)
        do {
          try FileManager.default.moveItem(at: location, to: kept)
          continuation.resume(returning: (kept, response))
        } catch {
          continuation.resume(throwing: SaverError(
            .saveFailed, "Could not keep the downloaded file: \(error.localizedDescription)"))
        }
      }
      task.resume()
    }
  }
}
