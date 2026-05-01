// ignore_for_file: avoid_print just for tool purpose

import 'dart:convert';
import 'dart:io';
import 'github.dart';
import 'yaml.dart';

Future<void> main(List<String> args) async {
  final version = getPubspec().releaseVersion;
  print('🚀 Starting release checks for version $version...\n');

  try {
    print('🔍 Checking pana score (this may take a minute)...');
    await _ensureMaxPana();

    print('\n🔍 Checking GitHub release assets...');
    await _ensurePubspecVersionInGithubRelease(version);

    print('\n✅ All checks passed! Ready for pub.dev release.');
    print('Next step: dart pub publish');
  } catch (e) {
    print('\n❌ Release check failed:');
    print(e);
    exit(1);
  }
}

Future<void> _ensureMaxPana() async {
  final result = await Process.run('dart', [
    'pub',
    'global',
    'run',
    'pana',
    '--json',
    '.',
  ]);
  if (result.exitCode != 0) {
    throw Exception(
      'pana command failed. ${result.stderr}',
    );
  }
  return _parsePanaOutput(result.stdout as String);
}

void _parsePanaOutput(String output) {
  final data = jsonDecode(output) as Map<String, dynamic>;

  final scores = data['scores'] as Map<String, dynamic>?;
  if (scores == null) {
    throw Exception('Could not find scores in pana output.');
  }

  final granted = scores['grantedPoints'] as int? ?? 0;
  final max = scores['maxPoints'] as int? ?? 0;

  if (granted < max) {
    throw Exception(
      'pana score is too low: $granted/$max. Maximum score is required for release.',
    );
  }

  print('✅ pana score: $granted/$max');
}

Future<void> _ensurePubspecVersionInGithubRelease(String version) async {
  try {
    final assets = await getReleaseAssets(version);

    if (assets.length < 6) {
      throw Exception(
        'GitHub release $version must have at least 6 assets.'
        ' Found: ${assets.length}',
      );
    }

    print('✅ GitHub release $version found with ${assets.length} assets.');
    for (final asset in assets) {
      print('   - $asset');
    }
  } catch (e) {
    throw Exception('Could not verify GitHub release: $e');
  }
}
