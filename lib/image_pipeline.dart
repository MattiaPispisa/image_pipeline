/// A cross-platform image processing library for Dart and Flutter.
///
/// Example usage:
/// ```dart
/// final transformer = ImageTransformer.native();
/// final Uint8List result = await transformer.transform(
///   imageBytes,
///   [
///     const ResizeOp(maxWidth: 500, maxHeight: 500),
///     const QualityOp(quality: 80),
///   ],
/// );
/// ```
library;

export 'src/exceptions.dart';
export 'src/operations/operations.dart';
export 'src/transformer.dart';
