@JS('image_pipeline')
library image_pipeline;

import 'dart:js_interop';

/// Initializes the underlying photon wrapper and WASM bridge
@JS('init_engine')
external JSPromise<JSBoolean> initEngine(JSString pluginName);

/// Processes image buffer through the defined operation arrays
@JS('execute_pipeline')
external JSPromise<JSUint8Array> executePipeline(
  JSUint8Array inputBytes,
  JSInt32Array operations,
);
