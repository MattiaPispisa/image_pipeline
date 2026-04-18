import 'package:image_pipeline/src/native/web/pipeline.dart' as web;
import 'package:image_pipeline/src/pipeline.dart' as pipeline;

pipeline.Pipeline createPipeline() => web.WebPipeline();
