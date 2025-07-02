# Optimisasi Aplikasi Senara - Sign Language Detection

## Masalah yang Diperbaiki:

### 1. **Performance Issues (Kamera Lag)**
- **Sebelum**: ResolutionPreset.low, threads = 4, interval 500ms
- **Sesudah**: ResolutionPreset.medium, threads = 2, interval 200ms
- **Frame skipping**: Memproses setiap frame ke-3 untuk mengurangi beban CPU
- **Memory management**: Optimisasi disposal dan reset flag

### 2. **Preprocessing Optimization**
- **Sebelum**: Full YUV to RGB conversion dengan bilinear interpolation
- **Sesudah**: Grayscale processing dengan nearest neighbor (3x lebih cepat)
- **Memory**: Pre-allocated tensor untuk mengurangi garbage collection

### 3. **Confidence Threshold Adjustment**
- **Sebelum**: Threshold 70%, consistency = 3
- **Sesudah**: Threshold 50%, consistency = 2
- **Reasoning**: Model mungkin trained dengan confidence yang lebih rendah

### 4. **Debug & Monitoring**
- Tambahan logging untuk troubleshooting
- Reset state variables saat start/stop scanning
- Better error handling dan recovery

## Tips untuk Testing:

1. **Lighting**: Pastikan pencahayaan cukup terang
2. **Distance**: Jarak tangan ke kamera sekitar 30-50cm  
3. **Background**: Gunakan background yang kontras dengan tangan
4. **Hand Position**: Posisikan tangan di tengah frame kamera
5. **Stability**: Tahan gesture selama 2-3 detik untuk hasil konsisten

## Jika Masih Lag:

Jika device masih terlalu lemah, bisa coba:
```dart
// Di _initializeCamera()
ResolutionPreset.low // Kembali ke low jika medium terlalu berat

// Di _processCameraStream()  
static const int _frameSkipRate = 5; // Skip lebih banyak frame
static const int _predictionIntervalMs = 300; // Interval lebih lama
```

## Model Requirements:

Pastikan model `best_model_v2.tflite`:
- Input shape: [1, 224, 224, 3] atau [1, 224, 224, 1]
- Output shape: [1, num_classes] dimana num_classes = jumlah huruf
- Normalisasi input: 0-1 range
