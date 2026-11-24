import Flutter
import UIKit

/// Connects the Dart API to `FileSaver`, `ImageResizer` and `Downloader`.
///
/// File work runs in a background task and the reply is sent on the main thread.
public class FolderFileSaverPlugin: NSObject, FlutterPlugin {
  private let saver = FileSaver()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "folder_file_saver", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(FolderFileSaverPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    let folderName = args["folderName"] as? String
    let deleteOriginal = args["deleteOriginal"] as? Bool ?? false

    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)

    case "openAppSettings":
      openAppSettings(result)

    case "saveFile":
      guard let filePath = requiredString("filePath", in: args, result) else { return }
      run(result) { saver, _ in
        let source = URL(fileURLWithPath: filePath)
        let saved = try await saver.save(source, folderName: folderName)
        if deleteOriginal { try? FileManager.default.removeItem(at: source) }
        return saved
      }

    case "saveResizedImage":
      guard let imagePath = requiredString("imagePath", in: args, result) else { return }
      let width = args["width"] as? Int ?? 0
      let height = args["height"] as? Int ?? 0
      guard width > 0 || height > 0 else {
        result(SaverError(.invalidArgument, "Give a width or a height greater than 0").flutterError)
        return
      }
      run(result) { saver, tempDirectory in
        let source = URL(fileURLWithPath: imagePath)
        let resized = try ImageResizer.resize(
          source, width: width, height: height, outputDirectory: tempDirectory)
        let saved = try await saver.save(resized, folderName: folderName)
        if deleteOriginal { try? FileManager.default.removeItem(at: source) }
        return saved
      }

    case "saveFromUrl":
      guard let url = requiredString("url", in: args, result) else { return }
      let fileName = args["fileName"] as? String
      let headers = args["headers"] as? [String: String] ?? [:]
      run(result) { saver, tempDirectory in
        let downloaded = try await Downloader.download(
          url, to: tempDirectory, fileName: fileName, headers: headers)
        return try await saver.save(downloaded, folderName: folderName)
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Runs `work` in a background task with a fresh temp folder that is deleted
  /// afterwards, and replies with the saved file or the error.
  private func run(
    _ result: @escaping FlutterResult,
    _ work: @escaping (FileSaver, URL) async throws -> SavedFile
  ) {
    let saver = self.saver
    Task.detached(priority: .userInitiated) {
      let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("folder_file_saver/\(UUID().uuidString)", isDirectory: true)
      defer { try? FileManager.default.removeItem(at: tempDirectory) }

      let reply: Any
      do {
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        reply = try await work(saver, tempDirectory).asDictionary
      } catch let error as SaverError {
        reply = error.flutterError
      } catch {
        reply = SaverError(.saveFailed, error.localizedDescription).flutterError
      }
      DispatchQueue.main.async { result(reply) }
    }
  }

  private func openAppSettings(_ result: @escaping FlutterResult) {
    guard let url = URL(string: UIApplication.openSettingsURLString),
          UIApplication.shared.canOpenURL(url)
    else {
      result(false)
      return
    }
    UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
  }

  /// Reads a required string argument, or replies with an error and returns nil.
  private func requiredString(_ key: String, in args: [String: Any], _ result: FlutterResult) -> String? {
    guard let value = args[key] as? String, !value.isEmpty else {
      result(SaverError(.invalidArgument, "'\(key)' is required").flutterError)
      return nil
    }
    return value
  }
}
