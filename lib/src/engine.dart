import 'native/engine_stub.dart'
    if (dart.library.io) 'native/io/engine.dart'
    if (dart.library.html) 'native/web/engine.dart';

/// The underlying platform-specific engine that manages native resources.
///
/// This singleton class orchestrates the lifecycle of the native bindings
/// (like `libvips` on IO, or WASM on Web). It is usually accessed internally
/// by the pipeline, but its initialization and termination can be managed manually.
abstract class TransformerEngine {
  static TransformerEngine? _instance;

  /// Returns the singleton [TransformerEngine] instance for the current platform.
  static TransformerEngine get instance {
    _instance ??= createTransformerEngine();
    return _instance!;
  }

  /// Injects a mock instance for testing purposes.
  static void setMockInstanceForTesting(TransformerEngine? mock) {
    _instance = mock;
  }

  /// Clears the mock instance for testing purposes.
  static void clearMockInstanceForTesting() {
    _instance = null;
  }

  /// Ensures that the engine is initialized.
  /// This can be called multiple times safely.
  Future<void> ensureInitialized();

  /// Shuts down the engine and frees resources.
  Future<void> terminate();
}
