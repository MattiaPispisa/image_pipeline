// tool/download_assets.dart
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

const String repoOwner = 'MattiaPispisa';
const String repoName = 'image_pipeline';

Future<void> main(List<String> args) async {
  final version = args.isEmpty ? _pubspecVersion() : args.first;
  print('🚀 Inizio setup asset per la versione $version...\n');

  final tempDir = Directory.systemTemp.createTempSync('image_pipeline_assets_');

  try {
    await _setupWebAssets(version, tempDir);

    // In futuro, potrai aggiungere qui una funzione _setupDesktopAssets(version, tempDir)

    print('\n🎉 Setup di tutti gli asset completato con successo!');
  } catch (e) {
    print('\n❌ Si è verificato un errore critico:');
    print(e);
    exit(1);
  } finally {
    // Pulizia file temporanei (eseguita sempre, anche in caso di crash)
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}

String _pubspecVersion() {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    throw Exception("File pubspec.yaml non trovato nella root.");
  }

  final doc = yaml.loadYaml(pubspecFile.readAsStringSync());
  final rawVersion = doc['version'] as String;

  final cleanVersion = rawVersion.split('+').first;
  return 'v$cleanVersion';
}

Future<void> _setupWebAssets(String version, Directory tempDir) async {
  final webAsset = 'web_transformer.zip';
  final downloadUrl =
      'https://github.com/$repoOwner/$repoName/releases/download/$version/$webAsset';
  final tempZipPath = path.join(tempDir.path, webAsset);

  print('🌐 [WEB] Download in corso: $webAsset');
  await _downloadFile(downloadUrl, tempZipPath);

  // Calcola il percorso di destinazione nel progetto
  final targetWebDir = Directory(path.join('test', 'src', 'native', 'web'));

  // Crea la cartella se non esiste
  if (!targetWebDir.existsSync()) {
    targetWebDir.createSync(recursive: true);
  }

  print('📦 [WEB] Estrazione dei file in: ${targetWebDir.path}');
  // Estrae il contenuto dello zip direttamente nella cartella di test
  extractFileToDisk(tempZipPath, targetWebDir.path);

  print('✅ [WEB] Asset posizionati correttamente.');
}

/// Utility generica per il download di file tramite HTTP
Future<void> _downloadFile(String url, String savePath) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();

    // GitHub spesso usa redirect 302 per gli asset, HttpClient li segue di default
    if (response.statusCode == 404) {
      throw Exception(
        'Asset non trovato (404). Verifica che il tag della release e il nome del file siano corretti.',
      );
    } else if (response.statusCode >= 400) {
      throw Exception(
        'Errore HTTP ${response.statusCode} durante il download.',
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
