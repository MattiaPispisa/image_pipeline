import 'package:image_pipeline/src/operations/operation.dart';
import 'package:image_pipeline/src/pipeline.dart';

/// An operation that resizes the image.
///
/// The image will be proportionally scaled down to fit within the specified
/// [maxWidth] and [maxHeight]. If the original image is already smaller than
/// the given dimensions, it will not be upscaled.
class ResizeOp implements ImageOperation {
  /// Creates a new [ResizeOp].
  const ResizeOp({this.maxWidth, this.maxHeight});

  /// The maximum allowed width of the resulting image.
  final int? maxWidth;

  /// The maximum allowed height of the resulting image.
  final int? maxHeight;

  @override
  void apply(Pipeline pipeline) {
    pipeline.resize(maxWidth, maxHeight);
  }
}
