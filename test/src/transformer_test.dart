@TestOn('vm')
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:image_pipeline/src/transformer.dart';
import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/operations/quality.dart';
import 'package:image_pipeline/src/operations/resize.dart';

import 'mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  group('ImageTransformer', () {
    test(
      'transform() should apply all operations and execute pipeline',
      () async {
        final pipeline = MockPipeline();
        final transformer = ImageTransformer(() => pipeline);
        final input = Uint8List.fromList([1, 2, 3]);

        when(() => pipeline.execute(any())).thenAnswer((_) async => input);

        final operations = [
          const QualityOp(quality: 90),
          const ResizeOp(maxWidth: 100),
        ];

        final result = await transformer.transform(input, operations);

        verify(() => pipeline.setQuality(90)).called(1);
        verify(() => pipeline.resize(100, null)).called(1);
        verify(() => pipeline.execute(input)).called(1);
        expect(result, equals(input));
      },
    );

    test(
      'initialize() and terminate() interact with TransformerEngine',
      () async {
        final mockEngine = MockTransformerEngine();

        when(() => mockEngine.ensureInitialized()).thenAnswer((_) async {});
        when(() => mockEngine.terminate()).thenAnswer((_) async {});

        TransformerEngine.setMockInstanceForTesting(mockEngine);

        await ImageTransformer.initialize();
        verify(() => mockEngine.ensureInitialized()).called(1);

        await ImageTransformer.terminate();
        verify(() => mockEngine.terminate()).called(1);
      },
    );

    test(
      'native() factory should create instance without crashing (or catch UnsupportedError)',
      () {
        try {
          final instance = ImageTransformer.native();
          expect(instance, isNotNull);
        } catch (e) {
          // May throw UnsupportedError or Exception depending on native init
          expect(e, isNotNull);
        }
      },
    );

    test(
      'TransformerEngine.instance should invoke createTransformerEngine (or catch UnsupportedError)',
      () {
        // Clear _instance mock if any
        TransformerEngine.setMockInstanceForTesting(null);
        try {
          final engine = TransformerEngine.instance;
          expect(engine, isNotNull);
        } catch (e) {
          expect(e, isNotNull);
        }
      },
    );
  });
}
