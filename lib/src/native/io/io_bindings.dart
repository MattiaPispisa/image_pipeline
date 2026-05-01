import 'dart:ffi' as ffi;

import 'package:image_pipeline/src/native/io/io_transformer_bindings_generated.dart'
    as bindings;

/// Interface for native IO bindings generative via ffi.
abstract class IoBindings {
  static IoBindings? _instance;

  /// Returns the [IoBindings] instance.
  ///
  /// This will create an [IoBindings] if not already created.
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

  /// Initializes the engine.
  bool initEngine(ffi.Pointer<ffi.Char> argv0);

  /// Shuts down the engine.
  void shutdownEngine();

  /// Transforms the image using the given operations.
  ffi.Pointer<ffi.Uint8> transformImage({
    required ffi.Pointer<ffi.Uint8> inputBuffer,
    required int inputLength,
    required ffi.Pointer<ffi.Int32> opsArray,
    required int opsCount,
    required ffi.Pointer<ffi.Size> outLength,
  });

  /// Frees the image buffer.
  void freeImageBuffer(ffi.Pointer<ffi.Uint8> buffer);
}

/// Implementation of [IoBindings].
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
