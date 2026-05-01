// ignore_for_file: avoid_print just for demo

import 'dart:io';
import 'dart:typed_data';
import 'package:image_pipeline/image_pipeline.dart';
import 'package:path/path.dart' as path;

const _sampleImagePaths = ['assets', 'sample', 'sample_jpeg.jpeg'];
const _sampleOutputImagePath = 'example/transformed_sample';

void main() async {
  final inputBytes = await _getFileOrThrow();

  try {
    print('Transforming image...');
    final result = await ImageTransformer.native().transform(inputBytes, [
      const ResizeOp(maxWidth: 1920, maxHeight: 1920),
      const QualityOp(quality: 80),
    ]);

    final outputFile = File('$_sampleOutputImagePath.${result.extension}');
    await outputFile.writeAsBytes(result.bytes);

    print('Transformation complete! Saved to: ${outputFile.path}');
  } catch (e, s) {
    print('An error occurred during transformation: $e\n\n$s');
  } finally {
    print('Shutting down engine...');
    await ImageTransformer.terminate();
  }
}

Future<Uint8List> _getFileOrThrow() async {
  final inputFile = File(
    path.joinAll([path.current, ..._sampleImagePaths]),
  );
  if (!inputFile.existsSync()) {
    throw Exception('Error: ${inputFile.path} not found.');
  }
  return inputFile.readAsBytes();
}
