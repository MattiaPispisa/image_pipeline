import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:web/web.dart' as web;

const _assetsBasePath = '../../../../assets/sample';

class WebAssets {
  const WebAssets({required this.supported, required this.unsupported});

  final List<Uint8List> supported;
  final List<Uint8List> unsupported;
}

const _unsupportedExtensions = ['.tiff', '.heic'];

/// Loads all the sample images from the web server.
Future<WebAssets> loadWebAssets() async {
  final manifestResponse = await web.window
      .fetch('$_assetsBasePath/images.json'.toJS)
      .toDart;

  final manifestText = await manifestResponse.text().toDart;
  final fileNames = (jsonDecode(manifestText.toDart) as List<dynamic>).map(
    (name) => name as String,
  );

  final supportedNames = fileNames.where(
    (name) => !_unsupportedExtensions.contains(path.extension(name)),
  );
  final unsupportedNames = fileNames.where(
    (name) => _unsupportedExtensions.contains(path.extension(name)),
  );

  final supported = await Future.wait(supportedNames.map(_loadAsset));
  final unsupported = await Future.wait(unsupportedNames.map(_loadAsset));

  print('Supported: $supportedNames');
  print('Unsupported: $unsupportedNames');

  return WebAssets(
    supported: supported,
    unsupported: unsupported,
  );
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
