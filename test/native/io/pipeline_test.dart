import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:image_pipeline/src/native/io/pipeline.dart';
import 'package:image_pipeline/src/native/io/engine.dart';
import 'package:image_pipeline/src/engine.dart';

void main() {
  setUpAll(() {
    TransformerEngine.setMockInstanceForTesting(IoTransformerEngine());
  });

  group('IoPipeline', () {
    test('resize() and setQuality() run without errors', () {
      final pipeline = IoPipeline();
      
      pipeline.resize(100, 200);
      pipeline.resize(null, null);
      pipeline.setQuality(80);
    });

    test('execute() with invalid bytes gracefully throws Exception', () async {
      final pipeline = IoPipeline();
      final input = Uint8List(0);
      
      try {
        await pipeline.execute(input);
        fail('Should have thrown an exception');
      } catch (e) {
        expect(e.toString(), contains('Failed to transform image'));
      }
    });
  });
}
