import 'dart:typed_data';

import 'package:image_pipeline/src/operations/operation.dart';

abstract class ImageTransformer {
  Future<Uint8List> transform(
    Uint8List input,
    List<ImageOperation> operations,
  );
}
