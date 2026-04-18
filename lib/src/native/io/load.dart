import 'dart:ffi';
import 'dart:io';

DynamicLibrary loadLib() {
  if (Platform.isMacOS || Platform.isLinux) {
    return DynamicLibrary.open("libtransform.so");
  } else if (Platform.isWindows) {
    return DynamicLibrary.open("transform.dll");
  }
  throw UnsupportedError("Platform not supported");
}
