import 'dart:ffi';

import 'package:image_pipeline/src/engine.dart';
import 'io_transformer_bindings_generated.dart' as bindings;

TransformerEngine createTransformerEngine() => IoTransformerEngine();

class IoTransformerEngine extends TransformerEngine {
  bool _isInitialized = false;

  @override
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    // init_vips takes argv0 as parameter, but VIPS_INIT(NULL) is fine.
    // In Dart FFI we pass nullptr.
    final result = bindings.init_vips(nullptr);

    if (!result) {
      throw Exception('Failed to initialize libvips');
    }

    _isInitialized = true;
  }

  @override
  Future<void> terminate() async {
    if (!_isInitialized) return;

    bindings.shutdown_vips();
    _isInitialized = false;
  }
}
