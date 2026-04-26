import 'dart:io';
import 'dart:typed_data';

List<Uint8List> loadIoAssets() {
  final currentPath = Directory.current.path;

  final samplesDir = Directory('$currentPath/assets/sample');

  return samplesDir
      .listSync()
      .whereType<File>()
      .map((f) => f.readAsBytesSync())
      .toList();
}
