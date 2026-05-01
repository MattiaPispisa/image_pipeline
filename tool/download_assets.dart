// ignore_for_file: avoid_print just for tool purpose.

import 'dart:io';
import 'package:archive/archive_io.dart' as archive;
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

const String repoOwner = 'MattiaPispisa';
const String repoName = 'image_pipeline';

Future<void> main(List<String> args) async {
  final version = args.isEmpty ? _pubspecVersion() : args.first;
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

String _pubspecVersion() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    throw Exception('pubspec.yaml not found in the root.');
  }

  final doc = yaml.loadYaml(pubspecFile.readAsStringSync()) as yaml.YamlMap;
  final rawVersion = doc['version'] as String;

  final cleanVersion = rawVersion.split('+').first;
  return 'v$cleanVersion';
}

Future<void> _setupWebAssets(String version, Directory tempDir) async {
  const webAsset = 'web_transformer.zip';
  final downloadUrl =
      'https://github.com/$repoOwner/$repoName/releases/download/$version/$webAsset';
  final tempZipPath = path.join(tempDir.path, webAsset);

  print('🌐 [WEB] Downloading $webAsset');
  await _downloadFile(downloadUrl, tempZipPath);

  final targetWebDir = Directory(path.join('test', 'src', 'native', 'web'));

  if (!targetWebDir.existsSync()) {
    targetWebDir.createSync(recursive: true);
  }

  print('📦 [WEB] Extracting files to: ${targetWebDir.path}');
  await archive.extractFileToDisk(tempZipPath, targetWebDir.path);

  print('✅ [WEB] Assets correctly positioned.');
}

Future<void> _downloadFile(String url, String savePath) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();

    if (response.statusCode == 404) {
      throw Exception(
        'Asset not found (404).'
        ' Check that the release tag and filename are correct.',
      );
    } else if (response.statusCode >= 400) {
      throw Exception(
        'HTTP Error ${response.statusCode} during download.',
      );
    }

    final file = File(savePath);
    final sink = file.openWrite();
    await response.pipe(sink);
    await sink.close();
  } finally {
    client.close();
  }
}
