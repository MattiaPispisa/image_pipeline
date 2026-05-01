import 'package:image_pipeline/image_pipeline.dart';
import 'package:image_pipeline/src/native/exception.dart';
import 'package:test/test.dart';

void main() {
  group('ImageTransformException', () {
    test('ImageTransformException.fromNative returns EngineNotInitializedException', () {
      final exception = ImageTransformException.fromNative(
        NativeExceptionStrings.engineNotInitialized,
      );
      expect(exception, isA<EngineNotInitializedException>());
      expect(exception.message, contains('Engine not initialized'));
    });

    test('ImageTransformException.fromNative returns UnsupportedImageFormatException', () {
      const errorMsg = 'unsupported_image_format: .tiff';
      final exception = ImageTransformException.fromNative(errorMsg);
      expect(exception, isA<UnsupportedImageFormatException>());
      expect(exception.message, equals(errorMsg));
    });

    test('ImageTransformException.fromNative returns ImageTransformerPlatformException for unknown errors', () {
      const errorMsg = 'some_random_native_error';
      final exception = ImageTransformException.fromNative(errorMsg);
      expect(exception, isA<ImageTransformerPlatformException>());
      expect(exception.message, equals(errorMsg));
    });
  });

  group('Exception Types toString()', () {
    test('UnsupportedImageFormatException toString', () {
      const exception = UnsupportedImageFormatException('custom error');
      expect(
        exception.toString(),
        equals('UnsupportedImageFormatException: custom error'),
      );
    });

    test('EngineNotInitializedException toString', () {
      const exception = EngineNotInitializedException();
      expect(
        exception.toString(),
        equals('EngineNotInitializedException: Engine not initialized.'),
      );
    });

    test('ImageTransformerPlatformException toString', () {
      const exception = ImageTransformerPlatformException('platform error');
      expect(
        exception.toString(),
        equals('ImageTransformerPlatformException: platform error'),
      );
    });
  });
}
