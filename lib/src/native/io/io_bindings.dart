import 'dart:ffi' as ffi;

import 'package:image_pipeline/src/native/io/io_transformer_bindings_generated.dart'
    as bindings;

abstract class IoBindings {
  static IoBindings? _instance;

  static IoBindings get instance {
    _instance ??= _IoBindingsImpl();
    return _instance!;
  }

  /// Injects a mock instance for testing purposes.
  static void setMockInstanceForTesting(IoBindings? mock) {
    _instance = mock;
  }

  /// Clears the mock instance for testing purposes.
  static void clearMockInstanceForTesting() {
    _instance = null;
  }

  bool initEngine(ffi.Pointer<ffi.Char> argv0);
  void shutdownEngine();
  ffi.Pointer<ffi.Uint8> transformImage({
    required ffi.Pointer<ffi.Uint8> inputBuffer,
    required int inputLength,
    required ffi.Pointer<ffi.Int32> opsArray,
    required int opsCount,
    required ffi.Pointer<ffi.Size> outLength,
  });
  void freeImageBuffer(ffi.Pointer<ffi.Uint8> buffer);
}

class _IoBindingsImpl implements IoBindings {
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
