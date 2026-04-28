import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

const _assetsBasePath = '../../../../assets/sample';

// Funzione principale che scarica tutto
Future<List<Uint8List>> loadWebAssets() async {
  // 1. Scarica il file JSON con la lista dei nomi
  final manifestResponse = await web.window
      .fetch('$_assetsBasePath/images.json'.toJS)
      .toDart;

  // Convertiamo la risposta in testo e poi facciamo il parse del JSON
  final manifestText = await manifestResponse.text().toDart;
  // A seconda della versione di dart:js_interop, potrebbe servire il cast esplicito a String
  final List<dynamic> fileNames = jsonDecode(manifestText as String);

  // 2. Creiamo una lista di Future per scaricare le immagini simultaneamente
  final downloadTasks = fileNames.map((name) => _loadAsset(name as String));

  // 3. Aspettiamo che tutti i download finiscano e ritorniamo la lista
  return Future.wait(downloadTasks);
}

// Funzione helper basata sul tuo codice originale
Future<Uint8List> _loadAsset(String fileName) async {
  final response = await web.window
      .fetch('$_assetsBasePath/$fileName'.toJS)
      .toDart;

  final jsArrayBuffer = await response.arrayBuffer().toDart;
  final byteBuffer = jsArrayBuffer.toDart;

  return byteBuffer.asUint8List();
}
