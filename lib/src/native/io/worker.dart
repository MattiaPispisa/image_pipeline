import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as pkg_ffi;
import 'package:image_pipeline/src/engine.dart';
import 'package:image_pipeline/src/native/io/io_bindings.dart' as bindings;



abstract class ImageWorker {
  Future<Uint8List> transform(Uint8List input, List<int> operations);
  void close();
}

/// A worker that spawns an isolate per request using [Isolate.run].
class ShortLivedImageWorker implements ImageWorker {
  @override
  Future<Uint8List> transform(Uint8List input, List<int> operations) async {
    return Isolate.run(() => _performTransform(input, operations));
  }

  @override
  void close() {}
}

/// A long-lived worker isolate that waits for commands via a [ReceivePort].
class LongLivedImageWorker implements ImageWorker {
  final SendPort _commands;
  final ReceivePort _responses;
  final Map<int, Completer<Object?>> _activeRequests = {};
  int _idCounter = 0;
  bool _closed = false;

  LongLivedImageWorker._(this._responses, this._commands) {
    _responses.listen(_handleResponsesFromIsolate);
  }

  static Future<LongLivedImageWorker> spawn() async {
    final initPort = RawReceivePort();
    final connection = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (initialMessage) {
      final commandPort = initialMessage as SendPort;
      connection.complete((
        ReceivePort.fromRawReceivePort(initPort),
        commandPort,
      ));
    };

    try {
      await Isolate.spawn(_startRemoteIsolate, initPort.sendPort);
    } on Object {
      initPort.close();
      rethrow;
    }

    final (ReceivePort receivePort, SendPort sendPort) = await connection.future;
    return LongLivedImageWorker._(receivePort, sendPort);
  }

  @override
  Future<Uint8List> transform(Uint8List input, List<int> operations) async {
    if (_closed) throw StateError('Worker is closed');
    final completer = Completer<Object?>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, input, operations));
    
    final result = await completer.future;
    return result as Uint8List;
  }

  void _handleResponsesFromIsolate(dynamic message) {
    final (int id, Object? response) = message as (int, Object?);
    final completer = _activeRequests.remove(id);
    if (completer == null) return;

    if (response is RemoteError) {
      completer.completeError(response);
    } else if (response is Exception) {
      completer.completeError(response);
    } else {
      completer.complete(response);
    }

    if (_closed && _activeRequests.isEmpty) {
      _responses.close();
    }
  }

  static void _handleCommandsToIsolate(ReceivePort receivePort, SendPort sendPort) {
    receivePort.listen((message) async {
      if (message == 'shutdown') {
        receivePort.close();
        return;
      }
      
      final (int id, Uint8List input, List<int> operations) = 
          message as (int, Uint8List, List<int>);
          
      try {
        final result = await _performTransform(input, operations);
        sendPort.send((id, result));
      } catch (e) {
        sendPort.send((id, Exception(e.toString())));
      }
    });
  }

  static void _startRemoteIsolate(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);
    _handleCommandsToIsolate(receivePort, sendPort);
  }

  @override
  void close() {
    if (!_closed) {
      _closed = true;
      _commands.send('shutdown');
      if (_activeRequests.isEmpty) {
        _responses.close();
      }
    }
  }
}

/// The core transformation logic that runs inside an isolate.
Future<Uint8List> _performTransform(Uint8List input, List<int> operations) async {
  await TransformerEngine.instance.ensureInitialized();

  final inputBuffer = pkg_ffi.calloc<ffi.Uint8>(input.length);
  inputBuffer.asTypedList(input.length).setAll(0, input);

  final operationsTr = pkg_ffi.calloc<ffi.Int32>(operations.length);
  operationsTr.asTypedList(operations.length).setAll(0, operations);

  final outLength = pkg_ffi.calloc<ffi.Size>();

  try {
    final resultTr = bindings.IoBindings.instance.transformImage(
      inputBuffer: inputBuffer,
      inputLength: input.length,
      opsArray: operationsTr,
      opsCount: operations.length,
      outLength: outLength,
    );

    if (resultTr == ffi.nullptr) {
      throw Exception('Failed to transform image');
    }

    final outList = resultTr.asTypedList(outLength.value);
    // Create a copy of the list before freeing the C buffer
    final outUint8List = Uint8List.fromList(outList);

    bindings.IoBindings.instance.freeImageBuffer(resultTr);

    return outUint8List;
  } finally {
    pkg_ffi.calloc.free(inputBuffer);
    pkg_ffi.calloc.free(operationsTr);
    pkg_ffi.calloc.free(outLength);
  }
}
