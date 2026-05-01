@TestOn('vm')
library;

import 'package:image_pipeline/src/operations/resize.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('ResizeOp', () {
    test('should call resize on pipeline with correct values', () {
      final pipeline = MockPipeline();
      const ResizeOp(maxWidth: 100, maxHeight: 200).apply(pipeline);

      verify(() => pipeline.resize(100, 200)).called(1);
    });

    test('should accept null values for width and height', () {
      final pipeline = MockPipeline();
      const ResizeOp().apply(pipeline);

      verify(() => pipeline.resize(null, null)).called(1);
    });
  });
}
