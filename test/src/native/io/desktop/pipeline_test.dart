@TestOn('vm')
import 'dart:typed_data';

import 'package:image_pipeline/image_pipeline.dart';

import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/native/io/engine.dart';
import 'package:test/test.dart';

import '../load_assets.dart';

void main() {
  setUpAll(() async {
    await TransformerEngine.instance.ensureInitialized();
  });

  tearDownAll(() async {
    await TransformerEngine.instance.terminate();
  });

  for (final useLongLivedWorker in [false, true]) {
    final modeName = useLongLivedWorker ? 'Long-Lived Isolate' : 'Short-Lived Isolate';
    
    group('Native desktop transformation ($modeName)', () {
    late List<Uint8List> originalImages;

    setUpAll(() async {
      if (useLongLivedWorker) {
        await TransformerEngine.instance.io.spawnLongLivedWorker();
      } else {
        TransformerEngine.instance.io.useShortLivedWorker();
      }
      
      originalImages = loadIoAssets();
    });

    test(
      'resize() and setQuality() run without errors on real device',
      () async {
        for (final originalBytes in originalImages) {
          expect(
            await ImageTransformer.native().transform(originalBytes, [
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

          // C clamps scale to 1.0, so the pipeline shouldn't resize.
          // The JPG compression should yield identical bytes since input pixels and quality (75) are identical.
          expect(largeResult.length, equals(originalResult.length));
        }
      },
    );
  });
  }
}
