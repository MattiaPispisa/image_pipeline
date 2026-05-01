@TestOn('vm')
library;

import 'package:image_pipeline/src/operations/quality.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  group('QualityOp', () {
    test('should call setQuality on pipeline with correct value', () {
      final pipeline = MockPipeline();
      const quality = 80;
      const QualityOp(quality: quality).apply(pipeline);

      verify(() => pipeline.setQuality(quality)).called(1);
    });
  });
}
