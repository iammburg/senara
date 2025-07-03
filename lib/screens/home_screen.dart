import 'package:flutter/material.dart';
import '../widgets/button.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:camera/camera.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui' as ui;
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/scan_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isScanning = false;
  String translationResult = "Hasil terjemahan akan muncul di sini...";
  CameraController? _cameraController;
  Interpreter? _interpreter;
  bool _isCameraInitialized = false;
  bool _isProcessingFrame = false;
  bool _isImageStreamActive = false;
  File? _selectedImage;

  // Firebase services
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // Session Logging
  List<ScanLogEntry> _currentSessionLog = [];

  // Performance optimization
  DateTime _lastPredictionTime = DateTime.now();
  static const int _predictionIntervalMs =
      300; // Increased to 300ms for low-end devices

  // Confidence tracking for stability
  String? _lastPrediction;
  int _consistentPredictionCount = 0;
  static const int _requiredConsistency = 2; // Reduced consistency requirement

  // Buffer management
  int _frameSkipCounter = 0;
  static const int _frameSkipRate =
      5; // Process every 5th frame for better performance

  // Log throttling variables
  DateTime? _lastLogTime;
  static const int _logIntervalMs = 2000; // 2 seconds interval for logging
  String? _lastLoggedCharacter;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    // Don't load model automatically, wait for user to start scanning
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset
              .low, // Back to low for better performance on low-end devices
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } else {
        throw Exception("No cameras found");
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal mengakses kamera: $e")));
      }
    }
  }

  Future<void> _loadModel() async {
    try {
      debugPrint("Loading model...");
      _interpreter = await Interpreter.fromAsset(
        'assets/models/best_model_v2.tflite',
        options: InterpreterOptions()
          ..threads =
              2, // Reduced threads for better performance on low-end devices
      );
      debugPrint("Model loaded successfully");

      // Get model info
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      debugPrint("Input tensors: ${inputTensors.length}");
      debugPrint("Output tensors: ${outputTensors.length}");

      if (inputTensors.isNotEmpty) {
        debugPrint("Input shape: ${inputTensors[0].shape}");
        debugPrint("Input type: ${inputTensors[0].type}");
      }

      if (outputTensors.isNotEmpty) {
        debugPrint("Output shape: ${outputTensors[0].shape}");
        debugPrint("Output type: ${outputTensors[0].type}");
        debugPrint("Number of classes: ${outputTensors[0].shape.last}");
      }
    } catch (e) {
      debugPrint("Error loading model: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat model: $e"),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _startScanning() async {
    if (_cameraController == null ||
        !_isCameraInitialized ||
        !_cameraController!.value.isInitialized) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Kamera belum siap.")));
      return;
    }

    if (!isScanning) {
      // Load model when starting to scan
      if (_interpreter == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Memuat model...")));
        await _loadModel();
        if (_interpreter == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Gagal memuat model")));
          return;
        }
      }

      // Reset tracking variables and start new session
      _lastPrediction = null;
      _consistentPredictionCount = 0;
      _frameSkipCounter = 0;
      _isProcessingFrame = false;

      // Initialize new scanning session
      _currentSessionLog.clear();

      setState(() {
        isScanning = true;
        translationResult = "Memulai deteksi...";
      });
      _processCameraStream();
    } else {
      setState(() {
        isScanning = false;
        translationResult = "Hasil terjemahan akan muncul di sini...";
      });
      _stopImageStream();
    }
  }

  void _stopImageStream() {
    try {
      if (_isImageStreamActive && _cameraController != null) {
        _cameraController!.stopImageStream();
        _isImageStreamActive = false;
        _isProcessingFrame = false; // Reset processing flag
        debugPrint("Image stream stopped successfully");
      }
    } catch (e) {
      debugPrint("Error stopping image stream: $e");
      // Force reset flags even on error
      _isImageStreamActive = false;
      _isProcessingFrame = false;
    }
  }

  void _processCameraStream() {
    if (_interpreter == null) {
      debugPrint("Model not loaded yet");
      return;
    }

    _cameraController?.startImageStream((CameraImage image) async {
      // Frame skipping for performance
      _frameSkipCounter++;
      if (_frameSkipCounter % _frameSkipRate != 0) {
        return;
      }

      // Skip if already processing a frame
      if (_isProcessingFrame) return;

      // Throttle predictions - only predict every 300ms
      final now = DateTime.now();
      if (now.difference(_lastPredictionTime).inMilliseconds <
          _predictionIntervalMs) {
        return;
      }

      _isProcessingFrame = true;
      _isImageStreamActive = true;
      _lastPredictionTime = now;

      try {
        // Preprocess the image with optimization
        final input = _preprocessImageOptimized(image);

        // Get model output shape dynamically
        final outputTensors = _interpreter!.getOutputTensors();
        final outputShape = outputTensors[0].shape;
        final numClasses = outputShape.last;

        // Prepare output buffer based on actual model output
        final output = List.filled(numClasses, 0.0).reshape([1, numClasses]);

        // Run inference
        _interpreter!.run(input, output);

        // Get the predicted class
        final predictions = output[0] as List<double>;
        final maxIndex = predictions.indexOf(
          predictions.reduce((a, b) => a > b ? a : b),
        );
        final confidence = predictions[maxIndex];

        debugPrint(
          "Prediction: Index $maxIndex, Confidence: ${confidence.toStringAsFixed(3)}",
        );

        // Lowered confidence threshold for better detection
        if (confidence > 0.5) {
          // Convert index to letter (A=0, B=1, etc.)
          final predictedLetter = String.fromCharCode(65 + maxIndex);

          // Check for consistent predictions
          if (_lastPrediction == predictedLetter) {
            _consistentPredictionCount++;
          } else {
            _consistentPredictionCount = 1;
            _lastPrediction = predictedLetter;
          }

          // Only update UI if we have consistent predictions
          if (_consistentPredictionCount >= _requiredConsistency && mounted) {
            // Check throttling for log recording
            final now = DateTime.now();
            final shouldLogEntry =
                _lastLogTime == null ||
                now.difference(_lastLogTime!).inMilliseconds >=
                    _logIntervalMs ||
                _lastLoggedCharacter != predictedLetter;

            if (shouldLogEntry) {
              // Add to session log with throttling
              final logEntry = ScanLogEntry(
                character: predictedLetter,
                confidence: confidence,
                timestamp: now,
              );
              _currentSessionLog.add(logEntry);
              _lastLogTime = now;
              _lastLoggedCharacter = predictedLetter;
            }

            setState(() {
              translationResult =
                  "Prediksi: $predictedLetter (Confidence: ${(confidence * 100).toStringAsFixed(1)}%)";
            });
          }
        } else {
          // Low confidence - reset consistency tracking
          if (confidence < 0.2) {
            // Very low confidence
            _consistentPredictionCount = 0;
            _lastPrediction = null;
            if (mounted && _consistentPredictionCount == 0) {
              setState(() {
                translationResult =
                    "Arahkan tangan ke kamera untuk mendeteksi isyarat...";
              });
            }
          }
        }
      } catch (e) {
        debugPrint("Error during inference: $e");
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  List<List<List<List<double>>>> _preprocessImageOptimized(CameraImage image) {
    try {
      // Get model input shape dynamically
      final inputTensors = _interpreter!.getInputTensors();
      final inputShape = inputTensors[0].shape;
      final inputSize = inputShape[1]; // Assuming square input

      // Pre-allocate the 4D tensor for better memory management
      List<List<List<List<double>>>> input = List.generate(
        1,
        (batch) => List.generate(
          inputSize,
          (y) => List.generate(inputSize, (x) => List.generate(3, (c) => 0.0)),
        ),
      );

      // Get image dimensions
      final int imageWidth = image.width;
      final int imageHeight = image.height;

      // Use only Y plane for grayscale conversion (faster processing)
      final Uint8List yPlane = image.planes[0].bytes;

      // Calculate resize ratios
      final double scaleX = imageWidth / inputSize;
      final double scaleY = imageHeight / inputSize;

      // Optimized resize and normalization
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          // Simple nearest neighbor interpolation (faster than bilinear)
          int origY = (y * scaleY).round().clamp(0, imageHeight - 1);
          int origX = (x * scaleX).round().clamp(0, imageWidth - 1);

          int pixelIndex = origY * imageWidth + origX;

          if (pixelIndex < yPlane.length) {
            // Convert grayscale to RGB (use same value for all channels)
            double grayValue = yPlane[pixelIndex].toDouble();

            // Normalize to 0-1 range
            double normalizedValue = grayValue / 255.0;

            input[0][y][x][0] = normalizedValue; // R
            input[0][y][x][1] = normalizedValue; // G
            input[0][y][x][2] = normalizedValue; // B
          }
        }
      }

      return input;
    } catch (e) {
      debugPrint("Error preprocessing image: $e");
      // Return default tensor on error
      final inputTensors = _interpreter!.getInputTensors();
      final inputSize = inputTensors[0].shape[1];

      return List.generate(
        1,
        (batch) => List.generate(
          inputSize,
          (y) => List.generate(inputSize, (x) => List.generate(3, (c) => 0.0)),
        ),
      );
    }
  }

  Future<void> _uploadMedia() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        translationResult = "Memproses gambar...";
      });
      await _predictImage(_selectedImage!);
    } else {
      setState(() {
        translationResult = "Tidak ada gambar yang dipilih.";
      });
    }
  }

  Future<void> _predictImage(File imageFile) async {
    try {
      if (_interpreter == null) {
        await _loadModel();
        if (_interpreter == null) {
          setState(() {
            translationResult = "Gagal memuat model";
          });
          return;
        }
      }
      // Baca gambar dan resize ke input model
      final bytes = await imageFile.readAsBytes();
      final img = await decodeImageFromList(bytes);
      final inputTensors = _interpreter!.getInputTensors();
      final inputShape = inputTensors[0].shape;
      final inputSize = inputShape[1];
      // Resize dan konversi ke tensor [1, inputSize, inputSize, 3]
      final input = await _preprocessImageFromFile(img, inputSize);
      final outputTensors = _interpreter!.getOutputTensors();
      final numClasses = outputTensors[0].shape.last;
      final output = List.filled(numClasses, 0.0).reshape([1, numClasses]);
      _interpreter!.run(input, output);
      final predictions = output[0] as List<double>;
      final maxIndex = predictions.indexOf(
        predictions.reduce((a, b) => a > b ? a : b),
      );
      final confidence = predictions[maxIndex];
      if (confidence > 0.5) {
        final predictedLetter = String.fromCharCode(65 + maxIndex);
        setState(() {
          translationResult =
              "Prediksi: $predictedLetter (Confidence: ${(confidence * 100).toStringAsFixed(1)}%)";
        });
      } else {
        setState(() {
          translationResult = "Gambar tidak dikenali. Coba gambar lain.";
        });
      }
    } catch (e) {
      setState(() {
        translationResult = "Error memproses gambar: $e";
      });
    }
  }

  Future<List<List<List<List<double>>>>> _preprocessImageFromFile(
    ui.Image img,
    int inputSize,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();
    canvas.drawImageRect(
      img,
      ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, inputSize.toDouble(), inputSize.toDouble()),
      paint,
    );
    final picture = recorder.endRecording();
    final imgResized = await picture.toImage(inputSize, inputSize);
    final byteData = await imgResized.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    final bytes = byteData!.buffer.asUint8List();
    List<List<List<List<double>>>> input = List.generate(
      1,
      (batch) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) => List.generate(3, (c) {
            int pixelIndex = (y * inputSize + x) * 4;
            // RGBA
            double r = bytes[pixelIndex] / 255.0;
            double g = bytes[pixelIndex + 1] / 255.0;
            double b = bytes[pixelIndex + 2] / 255.0;
            return c == 0
                ? r
                : c == 1
                ? g
                : b;
          }),
        ),
      ),
    );
    return input;
  }

  void _resetUpload() {
    setState(() {
      _selectedImage = null;
      translationResult = "Hasil terjemahan akan muncul di sini...";
    });
  }

  // Session Log Management Functions
  void _removeLogEntry(int entryIndex) {
    setState(() {
      if (entryIndex >= 0 && entryIndex < _currentSessionLog.length) {
        _currentSessionLog.removeAt(entryIndex);
      }
    });
  }

  void _clearSessionLog() {
    setState(() {
      _currentSessionLog.clear();
    });
  }

  String _getSessionText() {
    return _currentSessionLog.map((entry) => entry.character).join('');
  }

  void _saveToHistory() async {
    if (_currentSessionLog.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data untuk disimpan'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Check if user is logged in
    if (!_authService.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login untuk menyimpan session ke history'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      print('Creating session for user: ${_authService.userId}');
      print('User signed in: ${_authService.isSignedIn}');

      final session = ScanSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _authService.userId!,
        logEntries: List.from(_currentSessionLog),
        createdAt: DateTime.now(),
        sessionText: _getSessionText(),
      );

      print('Session created: ${session.toMap()}');

      // Save to Firestore
      await _firestoreService.saveScanSession(session);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session disimpan: "${session.sessionText}"'),
          duration: const Duration(seconds: 3),
        ),
      );

      // Clear current session after saving
      _clearSessionLog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan session: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildLogEntryCard(ScanLogEntry entry, int index) {
    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.character,
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(entry.confidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => _removeLogEntry(index),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.red[400],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    try {
      // Stop image stream first
      _stopImageStream();
      // Add delay to ensure stream is fully stopped
      Future.delayed(const Duration(milliseconds: 100), () {
        _cameraController?.dispose();
      });
    } catch (e) {
      debugPrint("Error disposing camera: $e");
    }
    try {
      _interpreter?.close();
    } catch (e) {
      debugPrint("Error closing interpreter: $e");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header Section (Fixed at top)
            Container(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Text(
                    'Senara',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.sign_language, size: 28, color: Colors.blue[800]),
                ],
              ),
            ),

            // Scrollable Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    // Camera Preview Area (Fixed Height)
                    SizedBox(
                      height:
                          300, // Fixed height to prevent camera from shrinking
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black12,
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _selectedImage != null
                                  ? Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : (_cameraController != null &&
                                            _isCameraInitialized &&
                                            _cameraController!
                                                .value
                                                .isInitialized
                                        ? CameraPreview(_cameraController!)
                                        : const Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                CircularProgressIndicator(),
                                                SizedBox(height: 16),
                                                Text("Memuat kamera..."),
                                              ],
                                            ),
                                          )),
                            ),
                            if (_selectedImage != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: _resetUpload,
                                  tooltip: 'Reset',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      children: [
                        // Start/Stop Scan Button
                        Expanded(
                          child: CustomButton.scan(
                            onPressed: _startScanning,
                            isScanning: isScanning,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Upload Media Button
                        Expanded(
                          child: CustomButton.upload(onPressed: _uploadMedia),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Translation Result Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.translate,
                                color: Colors.blue[700],
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Hasil Terjemahan',
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              translationResult,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Session Log Card
                    if (_currentSessionLog.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  color: Colors.blue[700],
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Log Sesi Scan',
                                  style: TextStyle(
                                    fontFamily: 'Lexend',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: Icon(
                                    Icons.clear_all,
                                    color: Colors.red[400],
                                  ),
                                  onPressed: _clearSessionLog,
                                  tooltip: 'Hapus Semua',
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.save,
                                    color: Colors.green[600],
                                  ),
                                  onPressed: _saveToHistory,
                                  tooltip: 'Simpan ke History',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Teks Hasil: ${_getSessionText()}',
                                    style: TextStyle(
                                      fontFamily: 'Lexend',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total: ${_currentSessionLog.length} karakter',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _currentSessionLog.length,
                                itemBuilder: (context, index) {
                                  final entry = _currentSessionLog[index];
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: _buildLogEntryCard(entry, index),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
