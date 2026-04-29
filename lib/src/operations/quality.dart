import 'package:image_pipeline/src/operations/operation.dart';
import 'package:image_pipeline/src/pipeline.dart';

/// An operation that adjusts the output quality of the image.
///
/// This primarily affects JPEG compression. A higher value means better quality
/// but larger file size.
class QualityOp implements ImageOperation {
  /// Creates a new [QualityOp].
  const QualityOp({required this.quality});

  /// The target image quality, typically between 0 and 100.
  final int quality;

  @override
  void apply(Pipeline pipeline) {
    pipeline.setQuality(quality);
  }
}
