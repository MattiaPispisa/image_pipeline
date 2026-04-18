import 'package:image_pipeline/src/operations/operation.dart';
import 'package:image_pipeline/src/pipeline.dart';

class ResizeOp implements ImageOperation {
  const ResizeOp({this.maxWidth, this.maxHeight});

  final int? maxWidth;
  final int? maxHeight;

  @override
  void apply(Pipeline pipeline) {
    pipeline.resize(maxWidth, maxHeight);
  }
}
