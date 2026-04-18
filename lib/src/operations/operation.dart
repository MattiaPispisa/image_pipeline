import 'package:image_pipeline/src/pipeline.dart';

abstract class ImageOperation {
  void apply(Pipeline pipeline);
}
