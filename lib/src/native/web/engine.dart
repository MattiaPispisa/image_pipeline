import 'package:image_pipeline/src/engine.dart';

TransformerEngine createTransformerEngine() => WebTransformerEngine();

class WebTransformerEngine extends TransformerEngine {
  @override
  Future<void> ensureInitialized() async {
    throw UnimplementedError();
  }

  @override
  Future<void> terminate() async {
    throw UnimplementedError();
  }
}
