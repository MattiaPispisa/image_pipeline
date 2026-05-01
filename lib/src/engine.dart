import 'package:image_pipeline/src/native/engine_stub.dart'
    if (dart.library.io) 'native/io/engine.dart'
    if (dart.library.html) 'native/web/engine.dart';

/// {@template transformer_engine}
/// The underlying platform-specific engine that manages native resources.
///
/// This singleton class orchestrates the lifecycle of the native bindings.
///
/// It is usually accessed internally by the pipeline, but its initialization
/// and termination can be managed manually.
///
/// ```dart
/// import 'package:image_pipeline/image_pipeline.dart';
///
/// final engine = TransformerEngine.instance;
/// await engine.ensureInitialized();
/// await engine.terminate();
/// ```
/// {@endtemplate}
abstract class TransformerEngine {
  /// {@macro transformer_engine}
  const TransformerEngine();

  static TransformerEngine? _instance;

  /// Returns the singleton [TransformerEngine]
  /// instance for the current platform.
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
