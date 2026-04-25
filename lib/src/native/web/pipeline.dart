import 'dart:js_interop';
import 'dart:typed_data';

import 'package:image_pipeline/src/pipeline.dart' as pipeline;
import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/native/web/web_transformer_bindings.dart'
    as bindings;

pipeline.Pipeline createPipeline() => WebPipeline();

class WebPipeline implements pipeline.Pipeline {
  final List<int> _operations = [];

  @override
  Future<Uint8List> execute(Uint8List input) async {
    await TransformerEngine.instance.ensureInitialized();

    // Convert standard Dart typed lists directly to their JS equivalents
    final inputJs = input.toJS;
    final operationsJs = Int32List.fromList(_operations).toJS;

    try {
      // Execute the Javascript side, resolving the JSPromise
      final jsResult = await bindings
          .executePipeline(inputJs, operationsJs)
          .toDart;

      // Convert JSUint8Array back to Dart Uint8List
      return jsResult.toDart;
    } catch (e) {
      throw Exception('Failed to transform image on Web: $e');
    }
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
