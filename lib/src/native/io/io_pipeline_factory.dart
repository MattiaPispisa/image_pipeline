import 'package:image_pipeline/src/native/io/pipeline.dart' as io;
import 'package:image_pipeline/src/pipeline.dart' as pipeline;

pipeline.Pipeline createPipeline() => io.IoPipeline();
