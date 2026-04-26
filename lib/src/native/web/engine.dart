import 'dart:js_interop';

import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/native/web/web_transformer_bindings.dart'
    as bindings;

enum WebExecutionMode { worker, sync }

TransformerEngine createTransformerEngine() => WebTransformerEngine(
  mode: WebExecutionMode.worker,
  basePath: './',
  workerPath: './transformer_worker.js',
);

class WebTransformerEngine extends TransformerEngine {
  WebTransformerEngine({
    required this.mode,
    required this.basePath,
    required this.workerPath,
  });

  bool _isInitialized = false;
  final WebExecutionMode mode;
  final String basePath;
  final String workerPath;

  @override
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;

    final jsMode = mode.name.toJS; // 'worker' o 'sync'

    final success = await bindings
        .initEngine(jsMode, basePath.toJS, workerPath.toJS)
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
