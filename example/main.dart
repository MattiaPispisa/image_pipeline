// ignore_for_file: avoid_print just for demo

import 'dart:io';
import 'dart:typed_data';
import 'package:image_pipeline/image_pipeline.dart';

const _sampleImagePath = '../assets/sample/sample.jpeg';
const _sampleOutputImagePath = 'example/transformed_sample.jpeg';

void main() async {
  final inputBytes = await _getFileOrThrow();

  try {
    print('Transforming image...');
    final outputBytes = await ImageTransformer.native().transform(inputBytes, [
      const ResizeOp(maxWidth: 1920, maxHeight: 1920),
      const QualityOp(quality: 80),
    ]);

    final outputFile = File(_sampleOutputImagePath);
    await outputFile.writeAsBytes(outputBytes);

    print('Transformation complete! Saved to: ${outputFile.path}');
  } catch (e, s) {
    print('An error occurred during transformation: $e\n\n$s');
  } finally {
    print('Shutting down engine...');
    await ImageTransformer.terminate();
  }
}

Future<Uint8List> _getFileOrThrow() async {
  final inputFile = File(_sampleImagePath);
  if (!inputFile.existsSync()) {
    throw Exception('Error: $_sampleImagePath not found.');
  }
  return inputFile.readAsBytes();
}
