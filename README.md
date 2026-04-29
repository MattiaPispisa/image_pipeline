# Image Pipeline

A high-performance, cross-platform image processing library for Dart and Flutter.

**Image Pipeline** leverages native code to process images with blazing speed without blocking the UI thread. Under the hood, it abstracts and delegates operations to highly optimized libraries specifically chosen for each platform:
- **Mobile**: [stb](https://github.com/nothings/stb) (single-file public domain libraries for C/C++) via FFI
- **Desktop**: [libvips](https://libvips.github.io/libvips/) (a demand-driven, horizontally threaded image processing library) via FFI
- **Web**: [Photon](https://silvia-odwyer.github.io/photon/) (a high-performance Rust image processing library) compiled to WASM

## What it does

This library allows you to efficiently perform a sequence of operations on an image (e.g., resizing, compressing, or formatting) by pushing them into a `Pipeline`. Once all operations are defined, the pipeline executes them in a single, highly-optimized native pass, rather than repeatedly passing memory back and forth between Dart and the host platform.

### Supported Operations
- `ResizeOp`: Scales down images while preserving their aspect ratio (fit box).
- `QualityOp`: Adjusts output quality (primarily for JPEG compression).

*Need an operation that isn't listed here? You can easily build your own! Check out the [How to Extend the Library](#how-to-extend-the-library) section below.*

---

## How to Use It

### 1. Basic Usage

The library provides a simple, unified API across all platforms:

```dart
import 'package:image_pipeline/image_pipeline.dart';

void main() async {
  // 1. Initialize the engine (optional, but recommended on app startup)
  await ImageTransformer.initialize();

  // 2. Load your image bytes (from file, network, etc.)
  final Uint8List imageBytes = ...;

  // 3. Transform the image
  final transformer = ImageTransformer.native();
  final Uint8List processedBytes = await transformer.transform(
    imageBytes,
    [
      const ResizeOp(maxWidth: 500, maxHeight: 500),
      const QualityOp(quality: 80),
    ],
  );

  // Use processedBytes!
}
```

### 2. Platform Setup

#### IO (Mobile & Desktop)
On native platforms (Android, iOS, macOS, Windows, Linux), the library takes advantage of **Dart Native Assets**. You don't need to configure anything—just build your project, and the `libvips` C library will be automatically compiled and bundled with your application.

*Worker Configuration:*
By default, the IO engine spawns a lightweight, short-lived Isolate for each transformation to prevent UI jank. If you process hundreds of images sequentially, you can optionally configure a persistent worker:
```dart
import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/io.dart'; // Ensure you've exported this in your lib if needed

// Spawns a dedicated long-lived isolate
await TransformerEngine.instance.io.spawnLongLivedWorker();
```

#### Web
On the Web, the library uses a WASM-compiled version of the pipeline. Similar to libraries like `sqlite3`, you must manually download the Web assets from the release page and place them in your `web/` directory alongside `main.dart.js`.

To run the web application or tests locally, ensure the assets are served properly.

---

## Architecture Design

The library is designed with a clean separation of concerns:

- **`ImageTransformer`**: The public facade. You interact with this class to feed operations. It automatically proxies the workload to the correct platform engine.
- **`TransformerEngine`**: A cross-platform orchestrator singleton. It handles the lifecycle of the underlying native bindings (initializing and terminating `libvips` or the WASM module).
- **`Pipeline`**: A builder-pattern interface. It accumulates `ImageOperation`s (like `ResizeOp`) internally. When `execute()` is called, it translates all operations into a single native call.
- **`Bindings`**: The FFI / WASM boundary. `IoBindings` communicates with `transform.c`, while `WebBindings` communicates with JS/WASM.

---

## How to Extend the Library

Adding a new operation (e.g., `CropOp`) requires updating a few key layers to keep the native pipeline in sync.

### Step 1: Create the Dart Operation
Create a new class implementing `ImageOperation`:
```dart
class CropOp implements ImageOperation {
  const CropOp(this.width, this.height);
  final int width;
  final int height;

  @override
  void apply(Pipeline pipeline) => pipeline.crop(width, height);
}
```

### Step 2: Update the `Pipeline` Interface
Add the corresponding method to `lib/src/pipeline.dart`:
```dart
abstract class Pipeline {
  // ...
  void crop(int width, int height);
}
```
You will then need to implement this method in both `IoPipeline` (for native) and `WebPipeline` (for JS/WASM), saving the parameters into their respective state objects.

### Step 3: Update the Native Bindings
Modify the underlying implementation to support the new operation.
For **Native IO**:
1. Open `native/io/transform.h` and update the C struct (e.g., `PipelineConfig`) to hold your crop variables.
2. Open `native/io/transform.c` and implement the `libvips` cropping logic inside `transform_image`.
3. Re-run FFIGen or rely on the Native Assets build hook.

For **Web**:
1. Update your JS wrapper and WASM compilation pipeline to accept the crop parameters and process them.

### Step 4: Add Tests
Finally, write automated tests in `test/src/native/io/` and `test/src/native/web/` to ensure your new operation is completely isomorphic across platforms!