import 'package:image_pipeline/src/pipeline.dart';

/// stub for not supported platforms
///
/// Throws an [UnsupportedError] when called, indicating that the
/// platform is not supported for image transformation.
Pipeline createPipeline() {
  throw UnsupportedError('Platform not supported');
}
