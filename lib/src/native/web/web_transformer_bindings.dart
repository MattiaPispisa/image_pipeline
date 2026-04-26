@JS('image_pipeline')
library image_pipeline;

// lib/src/native/web/web_transformer_bindings.dart
import 'dart:js_interop';

@JS('init_engine')
// Aggiungiamo i parametri alla firma FFI/JS
external JSPromise<JSBoolean> initEngine(
  JSString mode,
  JSString basePath,
  JSString workerPath,
);

@JS('execute_pipeline')
external JSPromise<JSUint8Array> executePipeline(
  JSUint8Array inputBytes,
  JSInt32Array operations,
);
