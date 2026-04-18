import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;
import 'package:image_pipeline/src/native/io/io_transformer_bindings_generated.dart'
    as bindings;
import 'package:image_pipeline/src/pipeline.dart';

class IoPipeline implements Pipeline {
  IoPipeline() : _operations = [];

  final List<int> _operations;

  @override
  Future<Uint8List> execute(Uint8List input) async {
    final operationTr = ffi.calloc<Uint8>(input.length);
    operationTr.asTypedList(input.length).setAll(0, input);

    final operationsTr = ffi.calloc<Int32>(_operations.length);
    operationsTr.asTypedList(_operations.length).setAll(0, _operations);

    final outLength = ffi.calloc<Size>();

    final resultTr = bindings.transform_image(
      operationTr,
      input.length,
      operationsTr,
      _operations.length,
      outLength,
    );

    if (resultTr == nullptr) {
      throw Exception('Failed to transform image');
    }

    final outList = resultTr.asTypedList(outLength.value);
    final outUint8List = Uint8List.fromList(outList);

    ffi.calloc.free(operationTr);
    ffi.calloc.free(operationsTr);
    ffi.calloc.free(outLength);

    return outUint8List;
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
