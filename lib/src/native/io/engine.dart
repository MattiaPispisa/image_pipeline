import 'dart:ffi';

import 'package:ffi/ffi.dart' as ffi;
import 'package:image_pipeline/src/engine.dart';
import 'io_transformer_bindings_generated.dart' as bindings;

TransformerEngine createTransformerEngine() => IoTransformerEngine();

class IoTransformerEngine extends TransformerEngine {
  bool _isInitialized = false;

  @override
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    final namePtr = 'image_pipeline'.toNativeUtf8();

    try {
      final result = bindings.init_engine(namePtr.cast<Char>());

      if (!result) {
        throw Exception('Failed to initialize libvips');
      }

      _isInitialized = true;
    } finally {
      ffi.malloc.free(namePtr);
    }
  }

  @override
  Future<void> terminate() async {
    if (!_isInitialized) return;

    bindings.shutdown_engine();
    _isInitialized = false;
  }
}
