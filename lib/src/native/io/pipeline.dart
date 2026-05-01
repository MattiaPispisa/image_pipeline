import 'dart:typed_data';

import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/native/io/engine.dart';
import 'package:image_pipeline/src/pipeline.dart' as pipeline;

/// Creates a [pipeline.Pipeline] implementation for IO platforms.
pipeline.Pipeline createPipeline() => IoPipeline();

/// {@template pipeline}
/// The [pipeline.Pipeline] implementation for IO platforms.
///
/// [pipeline.Pipeline.execute] forwards the call to the [IoTransformerEngine].
/// {@endtemplate}
class IoPipeline implements pipeline.Pipeline {
  /// {@macro pipeline}
  IoPipeline() : _operations = [];

  final List<int> _operations;

  @override
  Future<Uint8List> execute(Uint8List input) async {
    return TransformerEngine.instance.io.transform(input, _operations);
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
