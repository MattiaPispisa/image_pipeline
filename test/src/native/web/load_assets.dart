import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

const _assetsBasePath = '../../../../assets/sample';

/// Loads all the sample images from the web server.
Future<List<Uint8List>> loadWebAssets() async {
  final manifestResponse = await web.window
      .fetch('$_assetsBasePath/images.json'.toJS)
      .toDart;

  final manifestText = await manifestResponse.text().toDart;
  final fileNames = (jsonDecode(manifestText.toDart) as List<dynamic>).map(
    (name) => name as String,
  );

  return Future.wait(fileNames.map(_loadAsset));
}

/// load a single image from [_assetsBasePath]
Future<Uint8List> _loadAsset(String fileName) async {
  final response = await web.window
      .fetch('$_assetsBasePath/$fileName'.toJS)
      .toDart;

  final jsArrayBuffer = await response.arrayBuffer().toDart;
  final byteBuffer = jsArrayBuffer.toDart;

  return byteBuffer.asUint8List();
}
