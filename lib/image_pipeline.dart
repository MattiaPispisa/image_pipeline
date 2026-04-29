/// A high-performance, cross-platform image processing library.
///
/// This library provides a unified API for applying transformations to images
/// (like resizing and quality adjustments) across Mobile, Desktop, and Web.
/// It uses highly optimized native C bindings (libvips) for IO platforms and
/// WASM bindings for the Web.
library image_pipeline;

export 'src/operations/operations.dart';
export 'src/transformer.dart';
