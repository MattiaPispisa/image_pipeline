import 'native/engine_stub.dart'
    if (dart.library.io) 'native/io/engine.dart'
    if (dart.library.html) 'native/web/engine.dart';

abstract class TransformerEngine {
  static TransformerEngine? _instance;

  static TransformerEngine get instance {
    _instance ??= createTransformerEngine();
    return _instance!;
  }

  /// Ensures that the engine is initialized.
  /// This can be called multiple times safely.
  Future<void> ensureInitialized();

  /// Shuts down the engine and frees resources.
  Future<void> terminate();
}
