@TestOn('vm')
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:image_pipeline/src/operations/quality.dart';
import '../mocks.dart';

void main() {
  group('QualityOp', () {
    test('should call setQuality on pipeline with correct value', () {
      final pipeline = MockPipeline();
      const quality = 80;
      final op = const QualityOp(quality: quality);

      op.apply(pipeline);

      verify(() => pipeline.setQuality(quality)).called(1);
    });
  });
}
