// ignore_for_file: avoid_print just for benchmark

import 'dart:io';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:en_logger/en_logger.dart';
import 'package:image/image.dart' as img;
import 'package:image_pipeline/image_pipeline.dart';
import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/native/io/engine.dart';

final logger = EnLogger(handlers: [_PrintHandler()]);

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

class NativePipelineBenchmark extends AsyncBenchmarkBase {
  NativePipelineBenchmark(this.imageBytes) : super('image_pipeline (Native)');

  final Uint8List imageBytes;

  @override
  Future<void> setup() async {
    logger.info('Setting up NativePipelineBenchmark...');
    await TransformerEngine.instance.ensureInitialized();
    await TransformerEngine.instance.io.spawnLongLivedWorker();
  }

  @override
  Future<void> teardown() async {
    await TransformerEngine.instance.terminate();
  }

  @override
  Future<void> run() async {
    final result = await ImageTransformer.native().transform(
      imageBytes,
      [
        const ResizeOp(maxWidth: 500, maxHeight: 500),
        const QualityOp(quality: 80),
      ],
    );
    if (result.bytes.isEmpty) throw Exception('Transformation failed');
  }
}

class DartImageBenchmark extends AsyncBenchmarkBase {
  DartImageBenchmark(this.imageBytes) : super('package:image (Pure Dart)');

  final Uint8List imageBytes;

  @override
  Future<void> setup() async {
    logger.info('Setting up DartImageBenchmark...');
  }

  @override
  Future<void> run() async {
    // decode, resize (fit), encode
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Cannot decode image');

    // Resize "fit box" up to max 500x500
    var targetWidth = image.width;
    var targetHeight = image.height;

    if (image.width > 500 || image.height > 500) {
      final ratioX = 500 / image.width;
      final ratioY = 500 / image.height;
      final ratio = ratioX < ratioY ? ratioX : ratioY;

      targetWidth = (image.width * ratio).round();
      targetHeight = (image.height * ratio).round();
    }

    final resized = img.copyResize(
      image,
      width: targetWidth,
      height: targetHeight,
    );
    final result = img.encodeJpg(resized, quality: 80);

    if (result.isEmpty) throw Exception('Transformation failed');
  }
}

void main() async {
  logger.info('Loading sample image...');

  // Trova un file sample.jpeg nella directory
  final file = File('assets/sample/sample.jpeg');
  if (!file.existsSync()) {
    logger.error('Sample image not found at ${file.path}');
    exit(1);
  }

  final imageBytes = file.readAsBytesSync();
  logger
    ..info('Sample image loaded: ${imageBytes.length} bytes.')
    ..info('--- Starting Native Benchmark ---');
  final nativeBenchmark = NativePipelineBenchmark(imageBytes);
  await nativeBenchmark.report();

  logger.info('--- Starting Pure Dart Benchmark ---');
  final dartBenchmark = DartImageBenchmark(imageBytes);
  await dartBenchmark.report();

  logger.info('Benchmarks completed.');
}
