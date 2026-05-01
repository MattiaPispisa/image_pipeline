import 'package:image_pipeline/src/operations/operation.dart';
import 'package:image_pipeline/src/pipeline.dart';

/// {@template resize_op}
/// An operation that resizes an image (downscale only).
///
/// The image will be proportionally scaled down to fit within the specified
/// [maxWidth] and [maxHeight]. If the original image is already smaller
/// than the given dimensions, it will not be upscaled.
/// {@endtemplate}
class ResizeOp implements ImageOperation {
  /// {@macro resize_op}
  const ResizeOp({this.maxWidth, this.maxHeight});

  /// The maximum width of the resulting image.
  final int? maxWidth;

  /// The maximum height of the resulting image.
  final int? maxHeight;

  @override
  void apply(Pipeline pipeline) {
    pipeline.resize(maxWidth, maxHeight);
  }
}
