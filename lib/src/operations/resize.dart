import 'package:image_pipeline/src/operations/operation.dart';
import 'package:image_pipeline/src/pipeline.dart';

class ResizeOp implements ImageOperation {
  final int? maxWidth;
  final int? maxHeight;

  const ResizeOp({this.maxWidth, this.maxHeight});

  @override
  void apply(Pipeline pipeline) {
    pipeline.resize(maxWidth, maxHeight);
  }
}
