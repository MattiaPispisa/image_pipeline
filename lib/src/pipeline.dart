import 'dart:typed_data';

abstract class Pipeline {
  void resize(int? maxWidth, int? maxHeight);
  void setQuality(int quality);

  Future<Uint8List> execute(Uint8List input);
}
