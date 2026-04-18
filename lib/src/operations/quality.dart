import 'package:image_pipeline/src/operations/operation.dart';
import 'package:image_pipeline/src/pipeline.dart';

class QualityOp implements ImageOperation {
  const QualityOp({required this.quality});

  final int quality;

  @override
  void apply(Pipeline pipeline) {
    pipeline.setQuality(quality);
  }
}
