@TestOn('vm')
library;

import 'dart:typed_data';

import 'package:image_pipeline/image_pipeline.dart';

import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/native/io/io_bindings.dart';
import 'package:test/test.dart';

import '../load_assets.dart';
import 'io_mob_pipeline.dart';

void main() {
  group('Native mobile transformation', () {
    late List<Uint8List> originalImages;

    setUpAll(() async {
      IoBindings.setMockInstanceForTesting(createIoTestMobBindings());
      originalImages = loadIoAssets();
      await TransformerEngine.instance.ensureInitialized();
    });

    tearDownAll(() async {
      await TransformerEngine.instance.terminate();
      IoBindings.clearMockInstanceForTesting();
    });

    test(
      'resize() and setQuality() run without errors on real device',
      () async {
        for (final originalBytes in originalImages) {
          expect(
            await ImageTransformer.native().transform(originalBytes, const [
              ResizeOp(maxWidth: 100, maxHeight: 200),
              QualityOp(quality: 80),
            ]),
            isA<Uint8List>(),
          );
        }
      },
    );

    test('Lowering quality reduces image size', () async {
      for (final originalBytes in originalImages) {
        final highQuality = await ImageTransformer.native().transform(
          originalBytes,
          [const QualityOp(quality: 90)],
        );
        final lowQuality = await ImageTransformer.native().transform(
          originalBytes,
          [const QualityOp(quality: 10)],
        );

        expect(lowQuality.length, lessThan(highQuality.length));
      }
    });

    test('Downsizing image reduces image size', () async {
      for (final originalBytes in originalImages) {
        final originalResult = await ImageTransformer.native().transform(
          originalBytes,
          [],
        );
        final smallResult = await ImageTransformer.native().transform(
          originalBytes,
          [const ResizeOp(maxWidth: 50, maxHeight: 50)],
        );

        expect(smallResult.length, lessThan(originalResult.length));
      }
    });

    test(
      'Providing a larger dimension does not upscale/change the image',
      () async {
        for (final originalBytes in originalImages) {
          final originalResult = await ImageTransformer.native().transform(
            originalBytes,
            [],
          );
          final largeResult = await ImageTransformer.native().transform(
            originalBytes,
            [const ResizeOp(maxWidth: 10000, maxHeight: 10000)],
          );

          expect(largeResult.length, equals(originalResult.length));
        }
      },
    );
  });
}
