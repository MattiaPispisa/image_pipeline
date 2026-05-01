// ignore_for_file: avoid_print necessary for the hook script to work

import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:en_logger/en_logger.dart';
import 'package:hooks/hooks.dart';
import 'package:http/http.dart' as http;
import 'package:native_toolchain_c/native_toolchain_c.dart' as native_toolchain;
import 'package:path/path.dart' as path;

const _repoOwner =
    'MattiaPispisa'; // TODO(MattiaPispisa): can be derived from pubspec
const _repoName =
    'image_pipeline'; // TODO(MattiaPispisa): can be derived from pubspec
const _cmakeFileName = 'io_desktop_transformer';
const _ioRemoteAssetFileName = 'io_transformer';
const _ioCodeAssetName =
    'io_transformer'; // TODO(MattiaPispisa): can be derived from pubspec

void main(List<String> args) async {
  await build(args, (input, output) async {
    final logger = EnLogger(handlers: [_PrintHandler()]);

    if (input.isMobile) {
      await _mobileBuild(
        input: input,
        output: output,
        logger: logger,
        assetName: _ioCodeAssetName,
      );
    } else if (input.isDesktop) {
      await _desktopBuild(input: input, output: output, logger: logger);
      logger.info('Building secondary mobile asset for desktop testing...');
      await _mobileBuild(
        input: input,
        output: output,
        logger: logger,
        assetName: '${_ioCodeAssetName}_mob_test',
      );
    }
  });
}

Future<void> _mobileBuild({
  required EnLogger logger,
  required BuildInput input,
  required BuildOutputBuilder output,
  required String assetName,
}) async {
  try {
    logger.info(
      'Mobile target detected (${input.config.code.targetOS}).'
      ' Starting local C compilation (Asset: $assetName)...',
    );

    final builder = native_toolchain.CBuilder.library(
      name: input.packageName,
      assetName: assetName,
      sources: [
        input.packageRoot
            .resolve(path.joinAll(['native', 'io', 'mobile', 'transform.c']))
            .toFilePath(),
      ],
      libraries: ['m'],
    );

    await builder.run(input: input, output: output);

    logger.info('Mobile build ($assetName) completed successfully!');
  } catch (e, stackTrace) {
    logger.error(
      'Fatal error during mobile build execution: $e',
      stackTrace: stackTrace,
    );
    exitCode = 1;
  }
}

Future<void> _desktopBuild({
  required EnLogger logger,
  required BuildInput input,
  required BuildOutputBuilder output,
}) async {
  try {
    final (osName, ext, archName) = _getOsInfo(input);
    final versionTag = await _getLibraryVersion(input);

    final downloadFileName = '$_ioRemoteAssetFileName-$osName-$archName.$ext';
    var finalLibraryUri = await _downloadPrebuiltAsset(
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
    osName = 'macos';
    ext = 'dylib';
  } else if (targetOS == OS.linux) {
    osName = 'linux';
    ext = 'so';
  } else if (targetOS == OS.windows) {
    osName = 'windows';
    ext = 'dll';
  } else {
    throw UnsupportedError('Unsupported OS: $targetOS');
  }

  final archName = switch (targetArch) {
    Architecture.x64 => 'x64',
    Architecture.arm64 => 'arm64',
    Architecture.ia32 => 'ia32',
    Architecture.arm => 'arm',
    Architecture.riscv64 => 'riscv64',
    _ => targetArch.name,
  };

  return (osName, ext, archName);
}

/// Find - from pubspec.yaml - the version of the library.
Future<String> _getLibraryVersion(BuildInput input) async {
  final pubspecFile = File.fromUri(input.packageRoot.resolve('pubspec.yaml'));

  if (!pubspecFile.existsSync()) {
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

  if (file.existsSync()) {
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
  final nativeSrcDir = input.packageRoot
      .resolve(path.joinAll(['native', 'io', 'desktop']))
      .toFilePath();

  output.dependencies.add(
    input.packageRoot.resolve(
      path.joinAll(['native', 'io', 'desktop', 'transform.c']),
    ),
  );
  output.dependencies.add(
    input.packageRoot.resolve(
      path.joinAll(['native', 'io', 'desktop', 'CMakeLists.txt']),
    ),
  );
  output.dependencies.add(
    input.packageRoot.resolve(path.joinAll(['native', 'transform.h'])),
  );

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
      'CMake configuration failed (do you have libvips installed locally?):\n'
      '${cmakeConfig.stderr}',
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

  final compiledFileName = '$_cmakeFileName.$ext';
  final compiledLibUri = input.outputDirectory.resolve(compiledFileName);

  if (!File.fromUri(compiledLibUri).existsSync()) {
    throw Exception(
      'Build apparently successful,'
      ' but the file $compiledFileName was not generated.',
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

extension _BuildInputHelper on BuildInput {
  bool get isMobile =>
      config.code.targetOS == OS.android || config.code.targetOS == OS.iOS;

  bool get isDesktop =>
      config.code.targetOS == OS.macOS ||
      config.code.targetOS == OS.linux ||
      config.code.targetOS == OS.windows;
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

    print(messageBuffer);
  }
}
