import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:hooks/hooks.dart';
import 'package:code_assets/code_assets.dart';
import 'package:en_logger/en_logger.dart';

const _repoOwner =
    'MattiaPispisa'; // TODO(MattiaPispisa): can be derived from pubspec
const _repoName =
    'image_pipeline'; // TODO(MattiaPispisa): can be derived from pubspec
const _cmakeFileName = 'io_transformer';
const _ioRemoteAssetFileName = 'io_transformer';
const _ioCodeAssetName =
    'io_transformer'; // TODO(MattiaPispisa): can be derived from pubspec

void main(List<String> args) async {
  await build(args, (input, output) async {
    final logger = EnLogger(handlers: [_PrintHandler()]);

    try {
      final (osName, ext, archName) = _getOsInfo(input);
      final versionTag = await _getLibraryVersion(input);

      final downloadFileName = '$_ioRemoteAssetFileName-$osName-$archName.$ext';
      Uri? finalLibraryUri = await _downloadPrebuiltAsset(
        input: input,
        logger: logger,
        version: versionTag,
        fileName: downloadFileName,
      );

      if (finalLibraryUri == null) {
        logger.warning('Download failed. Starting local build...');
        finalLibraryUri = await _fallbackLocalBuild(
          input: input,
          output: output,
          logger: logger,
          ext: ext,
        );
      }

      _addAssetToOutput(input, output, finalLibraryUri);

      logger.info('Build hook completed successfully!');
    } catch (e, stackTrace) {
      logger.error(
        'Fatal error during native hook execution: $e',
        stackTrace: stackTrace,
      );
      exitCode = 1;
    }
  });
}

/// Get OS information.
///
/// Returns a tuple of (osName, code extension, architectureName).
(String, String, String) _getOsInfo(BuildInput input) {
  final targetOS = input.config.code.targetOS;
  final targetArch = input.config.code.targetArchitecture;

  String osName;
  String ext;

  // Determina OS ed estensione
  if (targetOS == OS.macOS) {
    osName = 'macOS';
    ext = 'dylib';
  } else if (targetOS == OS.linux) {
    osName = 'Linux';
    ext = 'so';
  } else if (targetOS == OS.windows) {
    osName = 'Windows';
    ext = 'dll';
  } else {
    throw UnsupportedError('Unsupported OS: $targetOS');
  }

  final archName = targetArch == Architecture.arm64 ? 'arm64' : 'x64';

  return (osName, ext, archName);
}

/// Find - from pubspec.yaml - the version of the library.
Future<String> _getLibraryVersion(BuildInput input) async {
  final pubspecFile = File.fromUri(input.packageRoot.resolve('pubspec.yaml'));

  if (!await pubspecFile.exists()) {
    throw Exception('Unable to find pubspec.yaml in ${input.packageRoot}');
  }

  final content = await pubspecFile.readAsString();
  final versionLine = content
      .split('\n')
      .firstWhere(
        (line) => line.startsWith('version:'),
        orElse: () => throw Exception('No version found in pubspec.yaml'),
      );

  final rawVersion = versionLine.split(':').last.trim();
  final cleanVersion = rawVersion.split('+').first;
  return 'v$cleanVersion';
}

Future<Uri?> _downloadPrebuiltAsset({
  required BuildInput input,
  required EnLogger logger,
  required String version,
  required String fileName,
}) async {
  final downloadUrl =
      'https://github.com/$_repoOwner/$_repoName/releases/download/$version/$fileName';

  final downloadedFileUri = input.outputDirectory.resolve(fileName);
  final file = File.fromUri(downloadedFileUri);

  if (await file.exists()) {
    logger.info('Native binary found in cache: $fileName');
    return downloadedFileUri;
  }

  logger.info('Downloading $fileName from $downloadUrl ...');

  try {
    final response = await http.get(Uri.parse(downloadUrl));
    if (response.statusCode == 200) {
      await file.writeAsBytes(response.bodyBytes);
      logger.info('Download completed!');
      return downloadedFileUri;
    } else {
      logger.warning('HTTP error ${response.statusCode} during download.');
      return null;
    }
  } catch (e) {
    logger.warning('Network exception during download: $e');
    return null;
  }
}

Future<Uri> _fallbackLocalBuild({
  required BuildInput input,
  required BuildOutputBuilder output,
  required EnLogger logger,
  required String ext,
}) async {
  final outDir = input.outputDirectory.toFilePath();
  final nativeSrcDir = input.packageRoot.resolve('native/io').toFilePath();

  logger.info('Running CMake configuration...');
  final cmakeConfig = await Process.run('cmake', [
    '-B',
    outDir,
    '-S',
    nativeSrcDir,
    '-DCMAKE_BUILD_TYPE=Release',
  ]);

  if (cmakeConfig.exitCode != 0) {
    throw Exception(
      'CMake configuration failed (do you have libvips installed locally?):\n${cmakeConfig.stderr}',
    );
  }

  logger.info('Running CMake build...');
  final cmakeBuild = await Process.run('cmake', [
    '--build',
    outDir,
    '--config',
    'Release',
  ]);

  if (cmakeBuild.exitCode != 0) {
    throw Exception('CMake build failed:\n${cmakeBuild.stderr}');
  }

  output.dependencies.add(input.packageRoot.resolve('native/io/'));
  final compiledFileName = '$_cmakeFileName.$ext';
  final compiledLibUri = input.outputDirectory.resolve(compiledFileName);

  if (!await File.fromUri(compiledLibUri).exists()) {
    throw Exception(
      'Build apparently successful, but the file $compiledFileName was not generated.',
    );
  }

  logger.info('Local build completed successfully!');
  return compiledLibUri;
}

void _addAssetToOutput(
  BuildInput input,
  BuildOutputBuilder output,
  Uri fileUri,
) {
  final packageName = input.packageName;

  output.assets.code.add(
    CodeAsset(
      package: packageName,
      name: _ioCodeAssetName,
      file: fileUri,
      linkMode: DynamicLoadingBundled(),
    ),
  );
}

class _PrintHandler extends EnLoggerHandler {
  @override
  void write(
    String message, {
    required Severity severity,
    String? prefix,
    StackTrace? stackTrace,
    List<EnLoggerData>? data,
  }) {
    final messageBuffer = StringBuffer();

    if (prefix != null) {
      messageBuffer.write(prefixFormat?.format(prefix));
    }

    messageBuffer.write(message);

    if (stackTrace != null) {
      messageBuffer.write('\n\n$stackTrace');
    }

    print(messageBuffer.toString());
  }
}
