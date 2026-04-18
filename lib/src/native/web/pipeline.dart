import 'dart:typed_data';

import 'package:image_pipeline/src/pipeline.dart';

class WebPipeline implements Pipeline {
  @override
  Future<Uint8List> execute(Uint8List input) {
    throw UnimplementedError();
  }

  @override
  void resize(int? maxWidth, int? maxHeight) {
    throw UnimplementedError();
  }

  @override
  void setQuality(int quality) {
    throw UnimplementedError();
  }
}
