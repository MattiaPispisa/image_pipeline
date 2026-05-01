// ignore_for_file: avoid_print just for tool purpose.

import 'dart:io';
import 'package:archive/archive_io.dart' as archive;
import 'package:path/path.dart' as path;

import 'github.dart';
import 'yaml.dart';

Future<void> main(List<String> args) async {
  final version = args.isEmpty ? getPubspec().releaseVersion : args.first;
  print('🚀 Starting setup assets for version $version...\n');

  final tempDir = Directory.systemTemp.createTempSync('image_pipeline_assets_');

  try {
    await _setupWebAssets(version, tempDir);

    print('\n🎉 Setup of all assets completed successfully!');
  } catch (e) {
    print('\n❌ An error occurred:');
    print(e);
    exit(1);
  } finally {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}

Future<void> _setupWebAssets(String version, Directory tempDir) async {
  const webAsset = 'web_transformer.zip';
  final downloadUrl = gitHubReleaseAsset(
    version: version,
    asset: webAsset,
  );
  final tempZipPath = path.join(tempDir.path, webAsset);

  print('🌐 [WEB] Downloading $webAsset');
  await downloadFile(downloadUrl, tempZipPath);

  final targetWebDirs = [
    Directory(path.join('test', 'src', 'native', 'web')),
    Directory(path.join('flutter_example', 'web')),
  ];

  for (final targetWebDir in targetWebDirs) {
    if (!targetWebDir.existsSync()) {
      targetWebDir.createSync(recursive: true);
    }
    print('📦 [WEB] Extracting files to: ${targetWebDir.path}');
    await archive.extractFileToDisk(tempZipPath, targetWebDir.path);
    print('✅ [WEB] Assets correctly positioned.');
  }
}
