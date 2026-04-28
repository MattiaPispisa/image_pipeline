@TestOn('browser') // Forza l'esecuzione solo su browser
import 'dart:async';

import 'package:image_pipeline/image_pipeline.dart';
import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/native/web/engine.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:typed_data';

import 'load_assets.dart';

void main() {
  group('WebPipeline Tests', () {
    late List<Uint8List> originalImages;

    setUpAll(() async {
      final script =
          web.document.createElement('script') as web.HTMLScriptElement;

      // Il percorso esatto rispetto alla cartella test/
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      script.src = 'transformer.js?v=$timestamp';

      final completer = Completer<void>();
      script.onload = ((web.Event _) => completer.complete()).toJS;
      script.onerror = ((web.Event _) => completer.completeError(
        'Errore caricamento script JS',
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

      originalImages = await loadWebAssets();
    });

    tearDownAll(() async {
      await TransformerEngine.instance.terminate();
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
