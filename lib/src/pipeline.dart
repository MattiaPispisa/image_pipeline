import 'dart:typed_data';

/// {@template pipeline}
/// A builder pattern interface for accumulating image processing operations.
///
/// `ImageTransformer` uses this interface to bundle the requested operations
/// and execute them in a single optimized pass.
/// {@endtemplate}
abstract class Pipeline {
  /// {@macro pipeline}
  const Pipeline();

  /// Schedules a resize operation.
  ///
  /// The image will be resized to fit within [maxWidth] and [maxHeight] while
  /// maintaining its aspect ratio.
  void resize(int? maxWidth, int? maxHeight);

  /// Schedules a quality adjustment operation.
  ///
  /// The [quality] is an integer from 0 to 100, affecting JPEG compression.
  void setQuality(int quality);

  /// Executes all accumulated operations on the [input] image bytes.
  Future<Uint8List> execute(Uint8List input);
}
