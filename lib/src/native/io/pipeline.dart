import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:image_pipeline/src/native/io/io_bindings.dart' as bindings;
import 'package:image_pipeline/src/pipeline.dart' as pipeline;
import 'package:image_pipeline/src/engine.dart';

pipeline.Pipeline createPipeline() => IoPipeline();

class IoPipeline implements pipeline.Pipeline {
  IoPipeline() : _operations = [];

  final List<int> _operations;

  @override
  Future<Uint8List> execute(Uint8List input) async {
    await TransformerEngine.instance.ensureInitialized();

    // TODO(MattiaPispisa): isolate behavior

    final inputBuffer = ffi.calloc<Uint8>(input.length);
    inputBuffer.asTypedList(input.length).setAll(0, input);

    final operationsTr = ffi.calloc<Int32>(_operations.length);
    operationsTr.asTypedList(_operations.length).setAll(0, _operations);

    final outLength = ffi.calloc<Size>();

    try {
      final resultTr = bindings.IoBindings.instance.transformImage(
        inputBuffer: inputBuffer,
        inputLength: input.length,
        opsArray: operationsTr,
        opsCount: _operations.length,
        outLength: outLength,
      );

      if (resultTr == nullptr) {
        throw Exception('Failed to transform image');
      }

      final outList = resultTr.asTypedList(outLength.value);
      final outUint8List = Uint8List.fromList(outList);

      bindings.IoBindings.instance.freeImageBuffer(resultTr);

      return outUint8List;
    } finally {
      ffi.calloc.free(inputBuffer);
      ffi.calloc.free(operationsTr);
      ffi.calloc.free(outLength);
    }
  }

  @override
  void resize(int? maxWidth, int? maxHeight) {
    _operations
      ..add(1)
      ..add(maxWidth ?? 0)
      ..add(maxHeight ?? 0);
  }

  @override
  void setQuality(int quality) {
    _operations
      ..add(2)
      ..add(quality);
  }
}
