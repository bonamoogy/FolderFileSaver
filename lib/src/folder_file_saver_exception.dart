import 'package:flutter/services.dart';

/// Why a save failed.
enum FolderFileSaverErrorCode {
  /// The source file does not exist.
  fileNotFound,

  /// The user did not grant the permission needed to save.
  ///
  /// That is storage on Android 9 and lower, and Photos on iOS. Call
  /// `FolderFileSaver.openAppSettings()` so the user can grant it.
  permissionDenied,

  /// The download failed: no connection, timeout, or an HTTP error.
  downloadFailed,

  /// The file could not be read as an image (only for resizing).
  invalidImage,

  /// An argument was missing or invalid, e.g. a malformed URL.
  invalidArgument,

  /// The file could not be written to its destination.
  saveFailed,

  /// Any other error.
  unknown,
}

/// Thrown when a file cannot be saved.
class FolderFileSaverException implements Exception {
  const FolderFileSaverException(this.code, this.message);

  /// Converts the [PlatformException] sent by the native side.
  factory FolderFileSaverException.fromPlatformException(PlatformException e) {
    return FolderFileSaverException(
      _codes[e.code] ?? FolderFileSaverErrorCode.unknown,
      e.message ?? e.code,
    );
  }

  static const _codes = {
    'FILE_NOT_FOUND': FolderFileSaverErrorCode.fileNotFound,
    'PERMISSION_DENIED': FolderFileSaverErrorCode.permissionDenied,
    'DOWNLOAD_FAILED': FolderFileSaverErrorCode.downloadFailed,
    'INVALID_IMAGE': FolderFileSaverErrorCode.invalidImage,
    'INVALID_ARGUMENT': FolderFileSaverErrorCode.invalidArgument,
    'SAVE_FAILED': FolderFileSaverErrorCode.saveFailed,
  };

  /// Why the save failed.
  final FolderFileSaverErrorCode code;

  /// A readable description, for logs. Not meant to be shown to end users.
  final String message;

  @override
  String toString() => 'FolderFileSaverException(${code.name}): $message';
}
