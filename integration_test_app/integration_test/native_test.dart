import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_pipeline/image_pipeline.dart';
import 'package:integration_test/integration_test.dart';

import 'package:image_pipeline/src/engine.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await TransformerEngine.instance.ensureInitialized();
  });

  group('IoTransformerEngine (Integration)', () {
    late Uint8List originalBytes;

    setUpAll(() async {
      final byteData = await rootBundle.load('assets/sample/sample.jpeg');
      originalBytes = byteData.buffer.asUint8List();
    });

    testWidgets('Initialization and termination logic on real device',
        (WidgetTester tester) async {
      final engine = TransformerEngine.instance;

      await engine.ensureInitialized();
      await engine.ensureInitialized();

      await engine.terminate();
      await engine.terminate();

      expect(true, isTrue);
    });

    testWidgets('resize() and setQuality() run without errors on real device',
        (WidgetTester tester) async {
      expect(
        await ImageTransformer.native().transform(
          originalBytes,
          [
            ResizeOp(maxWidth: 100, maxHeight: 200),
            QualityOp(quality: 80),
          ],
        ),
        isA<Uint8List>(),
      );
    });
  });
}
