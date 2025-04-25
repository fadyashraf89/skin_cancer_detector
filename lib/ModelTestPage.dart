import 'exports.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;

class ModelTestPage extends StatefulWidget {
  final String uid;
  const ModelTestPage({super.key, required this.uid});

  @override
  State<ModelTestPage> createState() => _ModelTestPageState();
}

class _ModelTestPageState extends State<ModelTestPage> {
  File? _image;
  List? _results;
  String _status = "Model loading...";
  String? _timestamp;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      await Tflite.loadModel(
        model: 'assets/skin_model.tflite',
        labels: 'assets/labels.txt',
      );
      setState(() => _status = "Model ready 🎉");
    } catch (e) {
      setState(() => _status = "Model load failed ❌: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _status = "Analyzing...";
      _timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    });

    _runModel(_image!);
  }

  Future<void> _runModel(File image) async {
    setState(() => _isLoading = true);

    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 3,
      threshold: 0.5,
    );

    setState(() {
      _results = recognitions;
      _status = (_results != null && _results!.isNotEmpty)
          ? "Prediction complete ✅"
          : "No prediction found.";
      _isLoading = false;
    });
  }

  Future<void> _savePredictionToHistory() async {
    if (_results == null || _results!.isEmpty || _image == null) return;

    var connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection.')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final originalBytes = await _image!.readAsBytes();
      final decodedImage = img.decodeImage(originalBytes);
      final resizedImage = img.copyResize(decodedImage!, width: 400);
      final compressedBytes = img.encodeJpg(resizedImage, quality: 70);
      final base64Image = base64Encode(compressedBytes);

      final predictions = _results!.map((res) {
        return {
          'label': res['label'],
          'confidence': res['confidence'],
        };
      }).toList();

      await FirebaseFirestore.instance
          .collection('history')
          .doc(widget.uid)
          .set({
        'predictions': FieldValue.arrayUnion([
          {
            'timestamp': _timestamp,
            'imageBase64': base64Image,
            'predictions': predictions,
          }
        ])
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prediction saved to history!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving prediction: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  Widget _buildImagePreview() {
    return _image == null
        ? const Text("No image selected.")
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_image!, height: 250),
          );
  }

  Widget _buildPredictionCard() {
    if (_results == null || _results!.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("🩺 Prediction Result",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            ..._results!.map((res) {
              return Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.label_outline),
                      const SizedBox(width: 8),
                      Text("${res['label']}",
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.percent),
                      const SizedBox(width: 8),
                      Text(
                        "Confidence: ${(100 * res['confidence']).toStringAsFixed(2)}%",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                ],
              );
            }),
            if (_timestamp != null)
              Row(
                children: [
                  const Icon(Icons.access_time),
                  const SizedBox(width: 8),
                  Text("Scanned at: $_timestamp"),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Skin Cancer Detector"),
        backgroundColor: Colors.teal.shade400,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HistoryPage(
                          uid: widget.uid,
                        )),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(_status, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            _buildImagePreview(),
            const SizedBox(height: 20),
            _buildPredictionCard(),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(),
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text("Gallery"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade300,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _savePredictionToHistory,
              icon: const Icon(Icons.save),
              label: const Text("Save Prediction"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
