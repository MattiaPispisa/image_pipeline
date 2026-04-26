@TestOn('vm')
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:image_pipeline/src/operations/resize.dart';
import '../mocks.dart';

void main() {
  group('ResizeOp', () {
    test('should call resize on pipeline with correct values', () {
      final pipeline = MockPipeline();
      const op = ResizeOp(maxWidth: 100, maxHeight: 200);

      op.apply(pipeline);

      verify(() => pipeline.resize(100, 200)).called(1);
    });

    test('should accept null values for width and height', () {
      final pipeline = MockPipeline();
      const op = ResizeOp();

      op.apply(pipeline);

      verify(() => pipeline.resize(null, null)).called(1);
    });
  });
}
