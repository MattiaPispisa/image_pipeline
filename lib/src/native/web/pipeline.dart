import 'dart:js_interop';
import 'dart:typed_data';

import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/native/web/web_transformer_bindings.dart'
    as bindings;
import 'package:image_pipeline/src/pipeline.dart' as pipeline;

/// Creates a [pipeline.Pipeline] implementation for web platforms.
pipeline.Pipeline createPipeline() => WebPipeline();

/// {@template web_pipeline}
/// The web implementation of the [pipeline.Pipeline].
/// {@endtemplate}
class WebPipeline implements pipeline.Pipeline {
  /// {@macro web_pipeline}
  WebPipeline() : _operations = [];

  final List<int> _operations;

  @override
  Future<Uint8List> execute(Uint8List input) async {
    await TransformerEngine.instance.ensureInitialized();

    final inputJs = input.toJS;
    final operationsJs = Int32List.fromList(_operations).toJS;

    try {
      final jsResult = await bindings
          .executePipeline(inputJs, operationsJs)
          .toDart;

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
