@JS('image_pipeline')
library;

import 'dart:js_interop';

@JS('init_engine')
/// js interop for init engine
external JSPromise<JSBoolean> initEngine(
  JSString mode,
  JSString basePath,
  JSString workerPath,
);

@JS('execute_pipeline')
/// js interop for execute pipeline
external JSPromise<JSUint8Array> executePipeline(
  JSUint8Array inputBytes,
  JSInt32Array operations,
);
