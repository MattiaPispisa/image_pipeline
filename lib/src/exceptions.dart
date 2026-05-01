import 'package:image_pipeline/src/native/exception.dart';

/// {@template image_transformer_exceptions}
/// Generic exception for image transformation errors
/// {@endtemplate}
sealed class ImageTransformException implements Exception {
  /// {@macro image_transformer_exceptions}
  const ImageTransformException(this.message);

  /// Creates an [ImageTransformException] from a native error string.
  factory ImageTransformException.fromNative(String error) {
    if (error.contains(NativeExceptionStrings.engineNotInitialized)) {
      return const EngineNotInitializedException();
    }
    if (error.contains(NativeExceptionStrings.unsupportedFormat)) {
      return UnsupportedImageFormatException(error);
    }
    return ImageTransformerPlatformException(error);
  }

  /// The error message
  final String message;

  @override
  String toString() => 'ImageTransformException: $message';
}

/// {@template image_transformer_unsupported_format_exception}
/// Exception for unsupported image formats
/// {@endtemplate}
final class UnsupportedImageFormatException extends ImageTransformException {
  /// {@macro image_transformer_unsupported_format_exception}
  const UnsupportedImageFormatException([
    super.message = 'Unsupported image format or impossible to decode.',
  ]);

  @override
  String toString() => 'UnsupportedImageFormatException: $message';
}

/// {@template image_transformer_engine_not_initialized_exception}
/// Exception for engine not initialized
/// {@endtemplate}
final class EngineNotInitializedException extends ImageTransformException {
  /// {@macro image_transformer_engine_not_initialized_exception}
  const EngineNotInitializedException() : super('Engine not initialized.');

  @override
  String toString() => 'EngineNotInitializedException: $message';
}

/// {@template image_transformer_platform_exception}
/// Exception for platform specific errors
/// {@endtemplate}
final class ImageTransformerPlatformException extends ImageTransformException {
  /// {@macro image_transformer_platform_exception}
  const ImageTransformerPlatformException(super.message);

  @override
  String toString() => 'ImageTransformerPlatformException: $message';
}
