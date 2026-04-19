import 'package:mocktail/mocktail.dart';
import 'package:image_pipeline/src/pipeline.dart';
import 'package:image_pipeline/src/engine.dart';

class MockPipeline extends Mock implements Pipeline {}
class MockTransformerEngine extends Mock implements TransformerEngine {}
