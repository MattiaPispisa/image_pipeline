# Image Pipeline

[![package badge][package_badge]][pub_link]
[![pub points][pub_points_badge]][pub_link]
[![pub likes][pub_likes_badge]][pub_link]
[![codecov][codecov_badge]][codecov_link]
[![license][license_badge]][license_link]
[![pub publisher][pub_publisher_badge]][pub_publisher_link]

A cross-platform image processing library for Dart and Flutter.

**Image Pipeline** leverages native code to process images. Under the hood, it abstracts and delegates operations to libraries specifically chosen for each platform:

- **Desktop**: [libvips](https://libvips.github.io/libvips/);
- **Web**: [Photon](https://silvia-odwyer.github.io/photon/);
- **Mobile**: [stb](https://github.com/nothings/stb).

## Table of Contents

- [Image Pipeline](#image-pipeline)
  - [Table of Contents](#table-of-contents)
  - [What it does](#what-it-does)
    - [Supported Operations](#supported-operations)
  - [Installation](#installation)
    - [Platform setup](#platform-setup)
  - [How to Use It](#how-to-use-it)
    - [1. Basic Usage](#1-basic-usage)
    - [2. IO extension](#2-io-extension)
  - [Build](#build)
    - [IO](#io)
      - [Mobile (Android \& iOS)](#mobile-android--ios)
      - [Desktop (Windows, macOS, \& Linux)](#desktop-windows-macos--linux)
    - [Web](#web)
  - [Benchmarks](#benchmarks)
    - [Running Benchmarks](#running-benchmarks)
  - [Development Setup](#development-setup)
  - [Architecture Design](#architecture-design)
  - [How to Extend the Library](#how-to-extend-the-library)
    - [Step 1: Create the Dart Operation](#step-1-create-the-dart-operation)
    - [Step 2: Update the `Pipeline` Interface](#step-2-update-the-pipeline-interface)
    - [Step 3: Update the Native Bindings](#step-3-update-the-native-bindings)
    - [Step 4: Add Tests](#step-4-add-tests)
  - [Examples](#examples)
  - [Philosophy](#philosophy)

## What it does

This library allows you to perform a chain of operations on an image (e.g., resizing, compressing, or formatting) by pushing them into a `Pipeline`. Once all operations are defined, the pipeline executes them in a single native pass.

### Supported Operations

- `ResizeOp`: Scales down images while preserving their aspect ratio (fit box).
- `QualityOp`: Adjusts output quality (primarily for JPEG compression).

[How to Extend the available operations](#how-to-extend-the-library)

---

## Installation

Add the package to your `pubspec.yaml`:

```bash
dart pub add image_pipeline
```

### Platform setup

Thanks to [Dart's Native Assets](https://dart.dev/tools/hooks), Image Pipeline requires nearly zero configuration for most platforms:

- **Mobile (iOS & Android):** Zero configuration. The native C code is automatically compiled by Flutter during the app build.
- **Desktop (macOS, Windows, Linux):** Zero configuration. The build hook automatically downloads and bundles the pre-compiled dynamic libraries for your target architecture.
- **Web:** Requires a quick manual setup to serve the WASM binaries.
  1. Download the `web_transformer.zip` from the [latest release](https://github.com/MattiaPispisa/image_pipeline/releases).
  2. Extract the files (`transformer.js`, `transformer_worker.js`, `photon_rs.js`, `photon_rs_bg.wasm`) into your project's `web/` directory.
  3. Ensure these files are accessible at runtime alongside your `main.dart.js`.

  When running locally (e.g., `flutter run -d chrome`), ensure your local server is configured to serve `.wasm` files with the correct `application/wasm` MIME type.

---

## How to Use It

### 1. Basic Usage

The library provides a simple, unified API across all platforms:

```dart
import 'package:image_pipeline/image_pipeline.dart';

void main() async {
  // 1. Initialize the engine (optional, but recommended on app startup)
  //    otherwise it is initialized on the first transformation (lazy init)
  await ImageTransformer.initialize();

  // 2. Load your image bytes (from file, network, etc.)
  final Uint8List imageBytes = ...;

  // 3. Transform the image
  final transformer = ImageTransformer.native();
  final result = await transformer.transform(
    imageBytes,
    [
      const ResizeOp(maxWidth: 500, maxHeight: 500),
      const QualityOp(quality: 80),
    ],
  );

  // Use result.bytes!
  final processedBytes = result.bytes;
}
```

### 2. IO extension

**Worker Configuration**: by default, the IO engine spawns a lightweight, short-lived Isolate ([Isolate.run](https://dart.dev/language/isolates#running-an-existing-method-in-a-new-isolate)) for each transformation to prevent UI jank. If you process hundreds of images sequentially, you can optionally configure a persistent worker ([long-lived isolate](https://dart.dev/language/isolates#sending-multiple-messages-between-isolates-with-ports)):

```dart
// Spawns a dedicated long-lived isolate
await TransformerEngine.instance.io.spawnLongLivedWorker();

// Use the short-lived worker (default behavior)
await TransformerEngine.instance.io.useShortLivedWorker();
```

---

## Build

### IO

The library uses [hooks and native assets](https://dart.dev/tools/hooks) to automatically manage the compilation and bundling of native code.

#### Mobile (Android & iOS)

The mobile implementation uses the [stb](https://github.com/nothings/stb) libraries (image, image_resize, and image_write). The C code is bundled within the package and compiled directly during your application's build process. This makes the mobile pipeline completely **autonomous** and "plug-and-play" with no external dependencies required on the host system.

#### Desktop (Windows, macOS, & Linux)

The desktop implementation leverages [libvips](https://libvips.github.io/libvips/). Because `libvips` is a system dependency, the build hook follows a hybrid strategy:

1. **Prebuilt Assets**: The hook first attempts to download a pre-compiled binary from the GitHub releases that matches the target OS and Architecture.
2. **Local Fallback**: If a prebuilt binary is unavailable or the download fails, the hook attempts to compile the native bridge locally using `cmake`. **Note**: This fallback requires `libvips` (and its development headers) to be already installed on your system.

Currently, we provide prebuilt artifacts for the following matrix:

- **Linux**: `x64`, `arm64`
- **macOS**: `x64`, `arm64`
- **Windows**: `x64`, `arm64`

### Web

On the Web, the library utilizes a pipeline compiled to WebAssembly (WASM) for execution in the browser.

---

## Benchmarks

The library is benchmarked against common Pure-Dart alternatives to measure the efficiency of the native delegation.

### Running Benchmarks

To run the benchmarks locally, ensure you have the native assets configured and run:

```bash
dart run benchmark/benchmark.dart
```

_Note: Results may vary based on image size and hardware. The native pipeline typically shows a 4x-5x speed improvement for common sequential operations._

---

## Development Setup

To contribute to this library or run tests locally, follow these setup steps:

1. **Download Assets**: Pre-compiled binaries are required for desktop tests. If you are using VS Code, run the task `📥 Download Assets`. Alternatively, run:

   ```bash
   dart run tool/download_assets.dart
   ```

2. **Generate Test Bindings**: The mobile implementation tests require specific mock bindings. Run the VS Code task `🧬 Genera Bindings Mobile Test` or:

   ```bash
   dart run tool/generate_mob_test_bindings.dart
   ```

3. **Install Native Dependencies**: If you intend to perform a local build (fallback build) on desktop, `libvips` must be installed on your system (`brew install vips`, ...). This is required for the `cmake` compilation step if prebuilt assets are not used.

## Architecture Design

The library is designed with a separation of concerns:

- **`ImageTransformer`**: The public facade. You interact with this class to feed operations. It automatically proxies the workload to the correct platform engine.
- **`TransformerEngine`**: A cross-platform orchestrator singleton. It handles the lifecycle of the underlying native bindings.
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

Modify the underlying implementation to support the new operation. All the native bridge logic resides in the `native/` directory.

- **IO**: Extend the C headers and implementation files (e.g., `transform.h` and `transform.c`) located in `native/io/`. You may need to regenerate the Dart FFI bindings or rely on the build hook to pick up the changes.
- **Web**: Update the JavaScript wrapper and the corresponding WASM implementation logic within the `native/web/` assets.

### Step 4: Add Tests

Finally, write automated tests in `test/src/native/io/` and `test/src/native/web/` to ensure your new operation is completely isomorphic across platforms!

---

## Examples

**dart**

A simple dart example is provided within [example](https://github.com/MattiaPispisa/image_pipeline/blob/main/example/main.dart) directory.

**flutter**

A simple flutter example is provided within [flutter_example](https://github.com/MattiaPispisa/image_pipeline/blob/main/flutter_example/lib/main.dart) directory.

![demo](https://raw.githubusercontent.com/MattiaPispisa/image_pipeline/main/assets/demo/image_pipeline_shares_example.gif)

---

## Philosophy

The core philosophy of **Image Pipeline** is to perform image operations as efficiently as possible by delegating them to high-performance native libraries. The project is designed with a robust, structured foundation to ensure that extending the library with new operations is simple and consistent across all platforms.

While the current set of operations is intentionally limited to a few key functions, additional features and transformations will be introduced over time as the core system reaches full stability.

[license_badge]: https://img.shields.io/badge/license-BSD--3--Clause-blue.svg
[license_link]: https://opensource.org/licenses/BSD-3-Clause
[package_badge]: https://img.shields.io/pub/v/image_pipeline.svg
[codecov_badge]: https://img.shields.io/codecov/c/github/MattiaPispisa/image_pipeline/main?logo=codecov
[codecov_link]: https://app.codecov.io/gh/MattiaPispisa/image_pipeline
[pub_points_badge]: https://img.shields.io/pub/points/image_pipeline
[pub_link]: https://pub.dev/packages/image_pipeline
[pub_publisher_badge]: https://img.shields.io/pub/publisher/image_pipeline
[pub_publisher_link]: https://pub.dev/packages?q=publisher%3Amattiapispisa.it
[pub_likes_badge]: https://img.shields.io/pub/likes/image_pipeline
