@TestOn('browser') // Forza l'esecuzione solo su browser
import 'dart:async';

import 'package:image_pipeline/image_pipeline.dart';
import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/native/web/engine.dart';
import 'package:image_pipeline/src/native/web/pipeline.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:typed_data';

const _assetsBasePath = '../../../../assets/sample/';

// Funzione di utilità per scaricare l'immagine di test tramite fetch
Future<Uint8List> loadAsset() async {
  final response = await web.window
      .fetch('$_assetsBasePath/sample.jpeg'.toJS)
      .toDart;
  final byteBuffer = await (await response.arrayBuffer().toDart).toDart;

  // Creiamo la "vista" Uint8List a partire dal buffer
  return byteBuffer.asUint8List();
}

void main() {
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
  });

  group('WebPipeline Tests', () {
    test('Esecuzione in modalità SYNC', () async {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final engine = WebTransformerEngine(
        mode: WebExecutionMode.sync,
        basePath: './',
        workerPath: './transformer_worker.js?v=$timestamp',
      );
      TransformerEngine.setMockInstanceForTesting(engine);
      await engine.ensureInitialized();

      print('2. Init completato. Fetch immagine...');
      // Usiamo la modalità sync per evitare problemi coi worker nel test runner
      final pipeline = ImageTransformer(WebPipeline());

      final inputBytes = await loadAsset();
      print('3. Immagine caricata. Lunghezza byte: ${inputBytes.length}');

      final resultBytes = await pipeline.transform(inputBytes, [
        ResizeOp(maxHeight: 100, maxWidth: 100),
        QualityOp(quality: 80),
      ]);
      print('4. Pipeline eseguita. Lunghezza byte: ${resultBytes.length}');

      // Verifica che l'output esista e sia valido
      expect(resultBytes, isNotNull);
      expect(resultBytes.isNotEmpty, isTrue);
      // I byte di un file JPEG iniziano sempre con 0xFF 0xD8
      expect(resultBytes[0], equals(0xFF));
      expect(resultBytes[1], equals(0xD8));
    });
    /* 
    test('Esecuzione in modalità WORKER', () async {
      final pipeline = WebPipeline(mode: WebExecutionMode.worker);

      final inputBytes = await loadTestImage();
      pipeline.resize(50, 50);

      final resultBytes = await pipeline.execute(inputBytes);

      expect(resultBytes.isNotEmpty, isTrue);
    }); */
  });
}
