/// {@template native_exception_strings}
/// Constants for error strings returned by the native components (JS/C).
/// {@endtemplate}
abstract final class NativeExceptionStrings {
  /// Thrown when the engine is not initialized.
  static const engineNotInitialized = 'engine_not_initialized';

  /// Thrown when the image format is not supported or cannot be decoded.
  static const unsupportedFormat = 'unsupported_image_format';

  /// Prefix for errors occurring at a specific step in the web pipeline.
  static const errorAtStep = 'error_at_step';
}
