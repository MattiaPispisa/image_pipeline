import 'dart:typed_data';

import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/operations/operation.dart';
import 'package:image_pipeline/src/pipeline.dart';
import 'package:image_pipeline/src/pipeline_factory.dart';
import 'package:mime/mime.dart' as mime;

/// {@template image_transformer}
/// The main entry point for processing images.
///
/// Use [ImageTransformer.native] to automatically select the optimal processing
/// pipeline for the current platform (e.g., FFI for IO, WASM for Web).
///
/// Example usage:
/// ```dart
/// final transformer = ImageTransformer.native();
/// final result = await transformer.transform(
///   imageBytes,
///   [
///     const ResizeOp(maxWidth: 500, maxHeight: 500),
///     const QualityOp(quality: 80),
///   ],
/// );
/// ```
/// {@endtemplate}
abstract interface class ImageTransformer {
  /// {@macro image_transformer}
  ///
  /// [ImageTransformer.native] is preferred for ease of use and automatic
  /// platform detection. This constructor is provided for testing purposes
  /// or for scenarios where custom pipeline implementations are needed.
  factory ImageTransformer(Pipeline Function() pipeline) =>
      _ImplImageTransformer(pipeline);

  /// {@macro image_transformer}
  ///
  /// Creates an [ImageTransformer] that automatically resolves the native
  /// implementation for the current platform.
  factory ImageTransformer.native() => ImageTransformer(createPipeline);

  /// Initializes the image processing library.
  /// This is called automatically on the first transformation, but can be
  /// called explicitly for better control over the application lifecycle.
  static Future<void> initialize() =>
      TransformerEngine.instance.ensureInitialized();

  /// Shuts down the image processing library and frees native resources.
  static Future<void> terminate() => TransformerEngine.instance.terminate();

  /// Transforms the [input] image bytes by sequentially
  /// applying the given [operations].
  ///
  /// The operations are bundled and executed in a single native pass
  /// when possible for maximum performance.
  ///
  /// Returns a [Future] that resolves to the processed image bytes.
  Future<TransformResult> transform(
    Uint8List input,
    List<ImageOperation> operations,
  );
}

/// {@template transform_result}
/// The result of an image transformation.
/// {@endtemplate}
class TransformResult {
  /// {@macro transform_result}
  const TransformResult({
    required this.bytes,
    required this.mimeType,
  });

  /// The processed image bytes.
  final Uint8List bytes;

  /// The format of the output image.
  final String? mimeType;

  /// The format extension.
  String? get extension =>
      mimeType != null ? mime.extensionFromMime(mimeType!) : null;
}

class _ImplImageTransformer implements ImageTransformer {
  _ImplImageTransformer(this._pipelineFactory);

  final Pipeline Function() _pipelineFactory;

  @override
  Future<TransformResult> transform(
    Uint8List input,
    List<ImageOperation> operations,
  ) async {
    final pipeline = _pipelineFactory();
    for (final op in operations) {
      op.apply(pipeline);
    }

    final output = await pipeline.execute(input);
    return TransformResult(
      bytes: output,
      mimeType: mime.lookupMimeType('', headerBytes: output),
    );
  }
}
