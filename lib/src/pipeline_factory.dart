export 'native/pipeline_stub.dart'
    if (dart.library.io) 'native/io/io_pipeline_factory.dart'
    if (dart.library.html) 'native/web/web_pipeline_factory.dart';
