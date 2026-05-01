import 'package:image_pipeline/src/pipeline.dart';

/// {@template image_operation}
/// The base class for all image processing operations.
///
/// Subclasses define specific transformations
/// (e.g., resizing, quality adjustment)
/// that can be accumulated into a [Pipeline] for batch execution.
/// {@endtemplate}
abstract interface class ImageOperation {
  /// Applies this operation to the given [pipeline].
  void apply(Pipeline pipeline);
}
