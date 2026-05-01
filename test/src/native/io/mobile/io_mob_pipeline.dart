import 'dart:ffi' as ffi;

import 'package:image_pipeline/src/native/io/io_bindings.dart';
import './io_transformer_bindings_test_mob_generated.dart' as bindings;

/// creates a [IoBindings] instance for testing purposes
///
/// A native asset is creteated with the mobile bindings
/// for desktop platforms.
///
/// This allows to test the stb lib.
IoBindings createIoTestMobBindings() => IoTestMobBindingsImpl();

class IoTestMobBindingsImpl implements IoBindings {
  @override
  void freeImageBuffer(ffi.Pointer<ffi.Uint8> buffer) {
    return bindings.free_image_buffer(buffer);
  }

  @override
  bool initEngine(ffi.Pointer<ffi.Char> argv0) {
    return bindings.init_engine(argv0);
  }

  @override
  void shutdownEngine() {
    return bindings.shutdown_engine();
  }

  @override
  ffi.Pointer<ffi.Uint8> transformImage({
    required ffi.Pointer<ffi.Uint8> inputBuffer,
    required int inputLength,
    required ffi.Pointer<ffi.Int32> opsArray,
    required int opsCount,
    required ffi.Pointer<ffi.Size> outLength,
  }) {
    return bindings.transform_image(
      inputBuffer,
      inputLength,
      opsArray,
      opsCount,
      outLength,
    );
  }
}
