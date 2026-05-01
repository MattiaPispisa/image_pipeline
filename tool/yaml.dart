import 'dart:io' as io;

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

yaml.YamlMap getPubspec() {
  final pubspecFile = io.File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    throw Exception('pubspec.yaml not found in the root.');
  }

  return yaml.loadYaml(pubspecFile.readAsStringSync()) as yaml.YamlMap;
}

extension PubspecYamlMap on yaml.YamlMap {
  String get releaseVersion {
    return 'v${(this['version']! as String).split('+').first}';
  }

  String get repository {
    return this['repository'] as String;
  }

  yaml.YamlMap get _ffiGen {
    return this['ffigen'] as yaml.YamlMap;
  }

  String get ffiGenOutputFileName {
    final output = _ffiGen['output'] as String;

    return path.basename(output);
  }

  String get ffiGenAssetId {
    final output = _ffiGen['ffi-native'] as yaml.YamlMap;

    return output['assetId'] as String;
  }
}
