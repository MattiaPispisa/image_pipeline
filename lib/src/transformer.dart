import 'dart:typed_data';

import 'package:image_pipeline/src/operations/operation.dart';
import 'package:image_pipeline/src/pipeline.dart';
import 'package:image_pipeline/src/pipeline_factory.dart';

abstract class ImageTransformer {
  factory ImageTransformer() => _ImplImageTransformer(createPipeline());

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
