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

  group('Native transformation', () {
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

    testWidgets('Lowering quality reduces image size',
        (WidgetTester tester) async {
      final highQuality = await ImageTransformer.native()
          .transform(originalBytes, [const QualityOp(quality: 90)]);
      final lowQuality = await ImageTransformer.native()
          .transform(originalBytes, [const QualityOp(quality: 10)]);

      expect(lowQuality.length, lessThan(highQuality.length));
    });

    testWidgets('Downsizing image reduces image size',
        (WidgetTester tester) async {
      final originalResult =
          await ImageTransformer.native().transform(originalBytes, []);
      final smallResult = await ImageTransformer.native().transform(
          originalBytes, [const ResizeOp(maxWidth: 50, maxHeight: 50)]);

      expect(smallResult.length, lessThan(originalResult.length));
    });

    testWidgets(
        'Providing a larger dimension does not upscale/change the image',
        (WidgetTester tester) async {
      final originalResult =
          await ImageTransformer.native().transform(originalBytes, []);
      final largeResult = await ImageTransformer.native().transform(
          originalBytes, [const ResizeOp(maxWidth: 10000, maxHeight: 10000)]);

      // C clamps scale to 1.0, so the pipeline shouldn't resize.
      // The JPG compression should yield identical bytes since input pixels and quality (75) are identical.
      expect(largeResult.length, equals(originalResult.length));
    });
  });
}
