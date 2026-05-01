import 'package:image_pipeline/src/operations/operation.dart';
import 'package:image_pipeline/src/pipeline.dart';

/// {@template quality_op}
/// An operation that adjusts the output quality of the image.
///
/// This primarily affects JPEG compression. A higher value means better quality
/// but larger file size (0-100).
/// {@endtemplate}
class QualityOp implements ImageOperation {
  /// {@macro quality_op}
  const QualityOp({required this.quality});

  /// The target image quality (0-100).
  final int quality;

  @override
  void apply(Pipeline pipeline) {
    pipeline.setQuality(quality);
  }
}
