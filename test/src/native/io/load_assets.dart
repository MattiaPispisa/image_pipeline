import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;

const _acceptedExtensions = [
  '.jpeg',
  '.jpg',
  '.png',
  '.heic',
  '.webp',
];

/// loads all assets from the assets/sample folder
List<Uint8List> loadIoAssets() {
  final currentPath = Directory.current.path;

  final samplesDir = Directory('$currentPath/assets/sample');

  return samplesDir
      .listSync()
      .whereType<File>()
      .where((f) => _acceptedExtensions.contains(path.extension(f.path)))
      .map((f) => f.readAsBytesSync())
      .toList();
}
