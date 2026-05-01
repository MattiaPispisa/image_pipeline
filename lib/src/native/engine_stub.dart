import 'package:image_pipeline/src/engine.dart';

/// stub for not supported platforms
///
/// Throws an [UnsupportedError] when called, indicating that the
/// platform is not supported for image transformation.
TransformerEngine createTransformerEngine() =>
    throw UnsupportedError('Platform not supported');
