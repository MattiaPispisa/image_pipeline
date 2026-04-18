import 'dart:typed_data';

import 'package:image_pipeline/src/operations/operation.dart';
import 'package:image_pipeline/src/pipeline.dart';
import 'package:image_pipeline/src/pipeline_factory.dart';

import 'package:image_pipeline/src/engine.dart';

abstract class ImageTransformer {
  factory ImageTransformer() => _ImplImageTransformer(createPipeline());

  /// Initializes the image processing library.
  /// This is called automatically on the first transformation, but can be
  /// called explicitly for better control over the application lifecycle.
  static Future<void> initialize() =>
      TransformerEngine.instance.ensureInitialized();

  /// Shuts down the image processing library and frees native resources.
  static Future<void> terminate() => TransformerEngine.instance.terminate();

  Future<Uint8List> transform(Uint8List input, List<ImageOperation> operations);
}

class _ImplImageTransformer implements ImageTransformer {
  _ImplImageTransformer(this._pipeline);

  final Pipeline _pipeline;

  @override
  Future<Uint8List> transform(
    Uint8List input,
    List<ImageOperation> operations,
  ) {
    for (final op in operations) {
      op.apply(_pipeline);
    }

    return _pipeline.execute(input);
  }
}
