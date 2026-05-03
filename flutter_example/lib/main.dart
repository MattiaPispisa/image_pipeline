import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_pipeline/image_pipeline.dart';
import 'package:share_plus/share_plus.dart';

const _kTitle = 'Image Pipeline Shares';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _kTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PipelineExampleScreen(),
    );
  }
}

class PipelineExampleScreen extends StatefulWidget {
  const PipelineExampleScreen({super.key});

  @override
  State<PipelineExampleScreen> createState() => _PipelineExampleScreenState();
}

class _PipelineExampleScreenState extends State<PipelineExampleScreen> {
  // --- APP STATE ---
  Uint8List? _inputBytes;
  bool _isProcessing = false;

  // Configuration
  bool _enableResize = false;
  bool _enableQuality = false;

  // Mock parameters
  final int _targetWidth = 800;
  final int _targetHeight = 600;
  final int _targetQuality = 75;

  bool get _canProcess =>
      _inputBytes != null &&
      (_enableResize || _enableQuality) &&
      !_isProcessing;

  // --- LOGIC ---

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _inputBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _transformAndShare() async {
    if (!_canProcess || _inputBytes == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      List<ImageOperation> operations = [];
      if (_enableResize) {
        operations.add(
          ResizeOp(maxWidth: _targetWidth, maxHeight: _targetHeight),
        );
      }
      if (_enableQuality) {
        operations.add(QualityOp(quality: _targetQuality));
      }

      final result = await ImageTransformer.native().transform(
        _inputBytes!,
        operations,
      );

      if (!mounted) return;

      final xFile = XFile.fromData(
        result.bytes,
        name: 'transformed_image.${result.extension}',
        mimeType: result.mimeType,
      );

      final shareResult = await Share.shareXFiles([
        xFile,
      ], text: 'Here is your transformed image!');

      if (shareResult.status == ShareResultStatus.success ||
          shareResult.status == ShareResultStatus.dismissed) {
        _resetForm();
      }
    } catch (e, stackTrace) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'COPY',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: e.toString()));
              },
            ),
          ),
        );
      }
      print("Error: $e");
      print("stackTrace: $stackTrace");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _inputBytes = null;
      _enableResize = false;
      _enableQuality = false;
    });
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(_kTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_inputBytes != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Clear',
              onPressed: _isProcessing ? null : _resetForm,
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _ImagePickerCard(
                inputBytes: _inputBytes,
                isProcessing: _isProcessing,
                onPickImage: _pickImage,
              ),
              const SizedBox(height: 24),
              _OperationsCard(
                isProcessing: _isProcessing,
                enableResize: _enableResize,
                enableQuality: _enableQuality,
                targetWidth: _targetWidth,
                targetHeight: _targetHeight,
                targetQuality: _targetQuality,
                onResizeChanged: (val) => setState(() => _enableResize = val),
                onQualityChanged: (val) => setState(() => _enableQuality = val),
              ),
              const SizedBox(height: 32),
              _TransformButton(
                isProcessing: _isProcessing,
                onPressed: _canProcess ? _transformAndShare : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final Uint8List? inputBytes;
  final bool isProcessing;
  final VoidCallback onPickImage;

  const _ImagePickerCard({
    required this.inputBytes,
    required this.isProcessing,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '1. Select an image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Image'),
              onPressed: isProcessing ? null : onPickImage,
            ),
            if (inputBytes != null) ...[
              const SizedBox(height: 16),
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(inputBytes!, fit: BoxFit.cover),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OperationsCard extends StatelessWidget {
  final bool isProcessing;
  final bool enableResize;
  final bool enableQuality;
  final int targetWidth;
  final int targetHeight;
  final int targetQuality;
  final ValueChanged<bool> onResizeChanged;
  final ValueChanged<bool> onQualityChanged;

  const _OperationsCard({
    required this.isProcessing,
    required this.enableResize,
    required this.enableQuality,
    required this.targetWidth,
    required this.targetHeight,
    required this.targetQuality,
    required this.onResizeChanged,
    required this.onQualityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '2. Select operations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Resize'),
              subtitle: Text('Fit into $targetWidth x $targetHeight'),
              value: enableResize,
              onChanged: isProcessing
                  ? null
                  : (val) => onResizeChanged(val ?? false),
            ),
            CheckboxListTile(
              title: const Text('Compress (Quality)'),
              subtitle: Text('Set quality to $targetQuality%'),
              value: enableQuality,
              onChanged: isProcessing
                  ? null
                  : (val) => onQualityChanged(val ?? false),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransformButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback? onPressed;

  const _TransformButton({required this.isProcessing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        icon: isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.share),
        label: Text(isProcessing ? 'Processing...' : 'Transform and Share'),
        onPressed: onPressed,
      ),
    );
  }
}
