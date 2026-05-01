@TestOn('browser') // Forza l'esecuzione solo su browser
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:image_pipeline/image_pipeline.dart';
import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/native/web/engine.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

import 'load_assets.dart';

void main() {
  group('WebPipeline Integration', () {
    late WebAssets assets;

    setUpAll(() async {
      final script =
          web.document.createElement('script') as web.HTMLScriptElement;

      // version script to avoid caching
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      script.src = 'transformer.js?v=$timestamp';

      final completer = Completer<void>();
      script
        ..onload = ((web.Event _) => completer.complete()).toJS
        ..onerror = ((web.Event _) => completer.completeError(
          'Error loading the transformer library',
        )).toJS;

      web.document.head!.append(script);
      await completer.future;

      final engine = WebTransformerEngine(
        mode: WebExecutionMode.sync,
        basePath: './',
        workerPath: './transformer_worker.js?v=$timestamp',
      );
      TransformerEngine.setMockInstanceForTesting(engine);
      await engine.ensureInitialized();

      assets = await loadWebAssets();
    });

    tearDownAll(() async {
      await TransformerEngine.instance.terminate();
    });

    test(
      'resize() and setQuality() run without errors on supported formats',
      () async {
        for (final originalBytes in assets.supported) {
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

    test(
      'throws UnsupportedImageFormatException on unsupported formats',
      () async {
        for (final originalBytes in assets.unsupported) {
          expect(
            () => ImageTransformer.native().transform(originalBytes, const [
              ResizeOp(maxWidth: 100, maxHeight: 200),
            ]),
            throwsA(isA<UnsupportedImageFormatException>()),
          );
        }
      },
    );

    test('Lowering quality reduces image size', () async {
      for (final originalBytes in assets.supported) {
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

    test('Sequential operations work correctly', () async {
      for (final originalBytes in assets.supported) {
        final transformer = ImageTransformer.native();
        final result = await transformer.transform(
          originalBytes,
          [
            const ResizeOp(maxWidth: 50, maxHeight: 50),
            const QualityOp(quality: 50),
          ],
        );
        expect(result, isA<Uint8List>());
      }
    });

    test('Downsizing image reduces image size', () async {
      for (final originalBytes in assets.supported) {
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
        for (final originalBytes in assets.supported) {
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
