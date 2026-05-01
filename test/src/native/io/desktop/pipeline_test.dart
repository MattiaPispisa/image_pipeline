@TestOn('vm')
library;

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
    final modeName = useLongLivedWorker
        ? 'Long-Lived Isolate'
        : 'Short-Lived Isolate';

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
            final result = await ImageTransformer.native().transform(
              originalBytes,
              const [
                ResizeOp(maxWidth: 100, maxHeight: 200),
                QualityOp(quality: 80),
              ],
            );
            expect(result, isA<TransformResult>());
            expect(result.mimeType, equals('image/jpeg'));
            expect(result.extension, equals('jpg'));
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

          expect(lowQuality.bytes.length, lessThan(highQuality.bytes.length));
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

          expect(
            smallResult.bytes.length,
            lessThan(originalResult.bytes.length),
          );
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

            expect(
              largeResult.bytes.length,
              equals(originalResult.bytes.length),
            );
          }
        },
      );
    });
  }
}
