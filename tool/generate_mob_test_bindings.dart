// ignore_for_file: avoid_print only for tool purpose

import 'dart:io';

import 'package:path/path.dart' as path;

void main() {
  final sourceFile = File(
    path.joinAll([
      Directory.current.path,
      'lib',
      'src',
      'native',
      'io',
      // TODO(MattiaPispisa): can be readed from pubspec.yaml
      'io_transformer_bindings_generated.dart',
    ]),
  );

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
      '❌ Error: Original bindings file not found at ${sourceFile.path}',
    );
    exit(1);
  }

  print('📖 Reading original bindings...');
  var content = sourceFile.readAsStringSync();

  print('🔄 Replacing assetId...');
  content = content.replaceAll(
    "assetId: 'package:image_pipeline/io_transformer'",
    "assetId: 'package:image_pipeline/io_transformer_mob_test'",
  );

  content = content.replaceAll(
    '// AUTO GENERATED FILE, DO NOT EDIT.',
    '// AUTO GENERATED TEST BINDINGS, DO NOT EDIT.\n// Generato copiando i binding desktop tramite tool/generate_mob_test_bindings.dart',
  );
  if (!targetFile.parent.existsSync()) {
    targetFile.parent.createSync(recursive: true);
  }

  print('💾 Saving new file...');
  targetFile.writeAsStringSync(content);

  print(
    '✅ Test bindings for mobile created successfully in: ${targetFile.path}',
  );
}
