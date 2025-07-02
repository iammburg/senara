# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# TensorFlow Lite - More specific rules
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.nnapi.** { *; }
-keep class org.tensorflow.lite.support.** { *; }
-keep class org.tensorflow.lite.task.** { *; }

# TensorFlow Lite GPU Delegate - Specific classes that cause R8 issues
-keep class org.tensorflow.lite.gpu.GpuDelegate { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory$Options$* { *; }

# TensorFlow Lite NNAPI Delegate
-keep class org.tensorflow.lite.nnapi.NnApiDelegate { *; }

# TensorFlow Lite Flex Delegate
-keep class org.tensorflow.lite.flex.** { *; }

# Keep all TensorFlow Lite native methods and JNI interfaces
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep TensorFlow Lite model files and assets
-keep class **.tflite { *; }
-keepclassmembers class * {
    @org.tensorflow.lite.annotations.** <methods>;
}

# Prevent obfuscation of TensorFlow Lite interfaces
-keep interface org.tensorflow.lite.** { *; }

# Additional TensorFlow Lite support
-dontwarn org.tensorflow.lite.**
-dontwarn org.tensorflow.lite.gpu.**
-dontwarn org.tensorflow.lite.nnapi.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep TensorFlow Lite model files
-keep class **.tflite { *; }

# Camera
-keep class androidx.camera.** { *; }
-keep class androidx.camera.core.** { *; }
-keep class androidx.camera.camera2.** { *; }
-keep class androidx.camera.lifecycle.** { *; }

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Dart
-keep class **.dart.** { *; }

# Prevent obfuscation of Flutter engine
-dontwarn io.flutter.embedding.**