# ----------------------------------------------------------
# FLUTTER STANDARD RULES
# ----------------------------------------------------------
# Keeps the main Flutter engine classes and plugins from being removed
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ----------------------------------------------------------
# TFLITE (TENSORFLOW) RULES
# ----------------------------------------------------------
# Prevents R8 from crashing on missing GPU/Delegate classes
-dontwarn org.tensorflow.lite.**
-keep class org.tensorflow.lite.** { *; }

# ----------------------------------------------------------
# GOOGLE PLAY CORE / DEFERRED COMPONENTS RULES
# ----------------------------------------------------------
# Flutter has built-in support for downloading modules on demand.
# Since you aren't using this, R8 complains the libraries are missing.
# These rules tell R8 to ignore those specific missing classes.
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# ----------------------------------------------------------
# GENERAL SAFETY RULES
# ----------------------------------------------------------
# Ensures annotation classes used by libraries are not stripped
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod