# Fix untuk Flutter Build APK Error - TensorFlow Lite R8 Issue

## Masalah yang Diperbaiki:
- **R8 Obfuscation Error**: Missing class org.tensorflow.lite.gpu.GpuDelegateFactory$Options
- **TensorFlow Lite Compatibility**: ProGuard rules untuk TensorFlow Lite

## Perubahan yang Dilakukan:

### 1. **proguard-rules.pro** (Menambahkan aturan ProGuard)
- Keep rules untuk TensorFlow Lite classes
- Specific rules untuk GPU Delegate
- Native methods protection
- Interface preservation

### 2. **build.gradle.kts** (Konfigurasi build)
- Enabled minification dan resource shrinking
- Added NDK filters untuk optimasi
- Packaging options untuk menghindari konflik
- ProGuard files configuration

### 3. **gradle.properties** (Pengaturan R8)
- R8 full mode disabled untuk kompatibilitas
- R8 enabled dengan mode aman

## Cara Testing:

### Method 1: Build APK Normal
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Method 2: Jika Masih Error, Build tanpa R8
```bash
# Uncomment baris di gradle.properties:
# android.enableR8=false

flutter clean
flutter pub get  
flutter build apk --release
```

### Method 3: Build dengan Split APK (Reduce Size)
```bash
flutter build apk --release --split-per-abi
```

## Troubleshooting Tambahan:

### Jika Build Masih Gagal:
1. **Disable R8 Sementara**:
   - Edit `android/gradle.properties`
   - Uncomment: `android.enableR8=false`

2. **Clean Build**:
   ```bash
   flutter clean
   cd android
   ./gradlew clean
   cd ..
   flutter pub get
   ```

3. **Alternative Build Command**:
   ```bash
   flutter build apk --no-shrink --release
   ```

### Jika APK Terlalu Besar:
1. **Build Split APK**:
   ```bash
   flutter build apk --release --split-per-abi
   ```

2. **Build App Bundle**:
   ```bash
   flutter build appbundle --release
   ```

## File yang Dimodifikasi:
- ✅ `android/app/proguard-rules.pro` - TensorFlow Lite rules
- ✅ `android/app/build.gradle.kts` - Build configuration  
- ✅ `android/gradle.properties` - R8 settings

## Expected Hasil:
- APK build berhasil tanpa R8 error
- TensorFlow Lite berfungsi normal di release build
- Size APK optimal dengan resource shrinking
