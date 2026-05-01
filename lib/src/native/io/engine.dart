import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/native/io/io_bindings.dart';
import 'package:image_pipeline/src/native/io/worker.dart';

/// Creates an image transformation engine for the IO platform.
///
/// This engine uses native bindings for image processing and spawns
/// worker isolates to perform transformations asynchronously.
TransformerEngine createTransformerEngine() => IoTransformerEngine();

/// {@template io_transformer_engine}
/// The native IO implementation of the [TransformerEngine].
///
/// This engine manages the native bindings for image processing and provides
/// a worker pool (via isolates) to ensure image processing does not block
/// the UI thread.
/// {@endtemplate}
class IoTransformerEngine extends TransformerEngine {
  /// {@macro io_transformer_engine}
  IoTransformerEngine()
    : _isInitialized = false,
      _worker = const ShortLivedImageWorker();

  bool _isInitialized;
  ImageWorker _worker;

  /// Uses a new, short-lived isolate for each transformation.
  /// This is the default behavior.
  void useShortLivedWorker() {
    _worker.close();
    _worker = const ShortLivedImageWorker();
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

/// Extension to access IO-specific features of the [TransformerEngine].
extension TransformerEngineIoExtension on TransformerEngine {
  /// Gets the IO-specific transformer engine to configure worker isolates.
  ///
  /// Throws an [UnsupportedError] if called on a non-IO platform (e.g., Web).
  IoTransformerEngine get io {
    if (this is! IoTransformerEngine) {
      throw UnsupportedError(
        'The IO extension is only available on native platforms.',
      );
    }
    return this as IoTransformerEngine;
  }
}
