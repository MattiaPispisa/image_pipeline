// tool/generate_mob_test_bindings.dart
import 'dart:io';

import 'package:path/path.dart' as path;

void main() {
  // ⚠️ Sostituisci questo path con la posizione reale del file generato da ffigen
  final sourceFile = File(
    path.joinAll([
      Directory.current.path,
      'lib',
      'src',
      'native',
      'io',
      'io_transformer_bindings_generated.dart',
    ]),
  );

  // Posizioniamo i binding di test direttamente nella cartella test/
  final targetFile = File(
    path.joinAll([
      Directory.current.path,
      'test',
      'src',
      'native',
      'io',
      'mobile',
      'io_transformer_bindings_test_mob_generated.dart',
    ]),
  );

  if (!sourceFile.existsSync()) {
    print(
      '❌ Errore: File dei binding originali non trovato in ${sourceFile.path}',
    );
    exit(1);
  }

  print('📖 Lettura dei binding originali...');
  String content = sourceFile.readAsStringSync();

  print('🔄 Sostituzione dell\'assetId...');
  // Sostituiamo la stringa esatta dell'assetId
  content = content.replaceAll(
    "assetId: 'package:image_pipeline/io_transformer'",
    "assetId: 'package:image_pipeline/io_transformer_mob_test'",
  );

  // Modifichiamo l'intestazione per chiarezza
  content = content.replaceAll(
    '// AUTO GENERATED FILE, DO NOT EDIT.',
    '// AUTO GENERATED TEST BINDINGS, DO NOT EDIT.\n// Generato copiando i binding desktop tramite tool/generate_mob_test_bindings.dart',
  );

  // Creiamo la cartella di destinazione se non esiste
  if (!targetFile.parent.existsSync()) {
    targetFile.parent.createSync(recursive: true);
  }

  print('💾 Salvataggio del nuovo file...');
  targetFile.writeAsStringSync(content);

  print(
    '✅ Binding di test per il mobile creati con successo in: ${targetFile.path}',
  );
}
