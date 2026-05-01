import 'dart:js_interop';

import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/native/web/web_transformer_bindings.dart'
    as bindings;

/// Execution mode for the web pipeline.
enum WebExecutionMode {
  /// Use a Web Worker for background processing.
  worker,

  /// Run synchronously on the main thread (not recommended).
  sync,
}

/// Creates an image transformation engine for the web platform.
///
/// This engine uses Web Workers to perform
/// image transformations asynchronously.
TransformerEngine createTransformerEngine() => WebTransformerEngine(
  mode: WebExecutionMode.worker,
  basePath: './',
  workerPath: './transformer_worker.js',
);

/// {@template web_transformer_engine}
/// The web engine implementation of the [TransformerEngine].
///
/// This engine manages the web bindings for image processing.
/// {@endtemplate}
class WebTransformerEngine extends TransformerEngine {
  /// {@macro web_transformer_engine}
  WebTransformerEngine({
    required WebExecutionMode mode,
    required String basePath,
    required String workerPath,
  }) : _mode = mode,
       _basePath = basePath,
       _workerPath = workerPath,
       _isInitialized = false;

  bool _isInitialized;
  final WebExecutionMode _mode;
  final String _basePath;
  final String _workerPath;

  @override
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    final jsMode = _mode.name.toJS;

    final success = await bindings
        .initEngine(jsMode, _basePath.toJS, _workerPath.toJS)
        .toDart;

    if (!success.toDart) {
      throw Exception('Failed to initialize Web Pipeline');
    }
    _isInitialized = true;
  }

  @override
  Future<void> terminate() async {
    if (!_isInitialized) return;
    _isInitialized = false;
  }
}
