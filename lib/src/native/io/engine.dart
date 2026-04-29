import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/native/io/io_bindings.dart';
import 'package:image_pipeline/src/native/io/worker.dart';

TransformerEngine createTransformerEngine() => IoTransformerEngine();

class IoTransformerEngine extends TransformerEngine {
  bool _isInitialized = false;
  ImageWorker _worker = ShortLivedImageWorker();

  /// Uses a new, short-lived isolate for each transformation.
  /// This is the default behavior.
  void useShortLivedWorker() {
    _worker.close();
    _worker = ShortLivedImageWorker();
  }

  /// Spawns a persistent background isolate that handles all transformations.
  /// This can provide better performance for multiple sequential operations.
  Future<void> spawnLongLivedWorker() async {
    _worker.close();
    _worker = await LongLivedImageWorker.spawn();
  }

  /// Transforms the image using the configured worker.
  Future<Uint8List> transform(Uint8List input, List<int> operations) {
    return _worker.transform(input, operations);
  }

  @override
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    final namePtr = 'image_pipeline'.toNativeUtf8();

    try {
      final result = IoBindings.instance.initEngine(namePtr.cast<Char>());

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

    _worker.close();
    IoBindings.instance.shutdownEngine();
    _isInitialized = false;
  }
}

extension TransformerEngineIoExtension on TransformerEngine {
  /// Restituisce l'engine IO per configurare i Worker.
  /// Lancia un'eccezione se eseguito su piattaforme non-IO.
  IoTransformerEngine get io {
    if (this is! IoTransformerEngine) {
      throw UnsupportedError('L\'estensione IO è disponibile solo su piattaforme native.');
    }
    return this as IoTransformerEngine;
  }
}
