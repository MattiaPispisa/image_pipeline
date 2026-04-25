import 'dart:js_interop';

import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/native/web/web_transformer_bindings.dart'
    as bindings;

TransformerEngine createTransformerEngine() => WebTransformerEngine();

class WebTransformerEngine extends TransformerEngine {
  bool _isInitialized = false;

  @override
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    final pluginName = 'image_pipeline'.toJS;

    try {
      final success = await bindings.initEngine(pluginName).toDart;

      if (!success.toDart) {
        throw Exception("Failed to initialize photondart JS bindings");
      }

      _isInitialized = true;
    } catch (e) {
      throw Exception("photondart initialization error: $e");
    }
  }

  @override
  Future<void> terminate() async {
    if (!_isInitialized) return;
    _isInitialized = false;
  }
}
