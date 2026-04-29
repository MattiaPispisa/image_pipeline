import 'dart:ffi';
import 'dart:typed_data';

import 'package:image_pipeline/src/pipeline.dart' as pipeline;
import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/native/io/engine.dart';

pipeline.Pipeline createPipeline() => IoPipeline();

class IoPipeline implements pipeline.Pipeline {
  IoPipeline() : _operations = [];

  final List<int> _operations;

  @override
  Future<Uint8List> execute(Uint8List input) async {
    final engine = TransformerEngine.instance as IoTransformerEngine;
    return engine.transform(input, _operations);
  }

  @override
  void resize(int? maxWidth, int? maxHeight) {
    _operations
      ..add(1)
      ..add(maxWidth ?? 0)
      ..add(maxHeight ?? 0);
  }

  @override
  void setQuality(int quality) {
    _operations
      ..add(2)
      ..add(quality);
  }
}
