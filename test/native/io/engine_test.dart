import 'package:test/test.dart';
import 'package:image_pipeline/src/native/io/engine.dart';

void main() {
  group('IoTransformerEngine', () {
    test('initialization and termination logic', () async {
      final engine = IoTransformerEngine();
      
      // Multiple ensureInitialized shouldn't fail
      await engine.ensureInitialized();
      await engine.ensureInitialized();
      
      // Multiple terminate shouldn't fail
      await engine.terminate();
      await engine.terminate();
    });
  });
}
