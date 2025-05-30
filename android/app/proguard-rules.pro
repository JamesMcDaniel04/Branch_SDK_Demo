# Branch SDK rules
-keep class io.branch.** { *; }
-keep class com.google.android.gms.ads.identifier.** { *; }
-dontwarn io.branch.**

# Keep all Branch classes and methods
-keep class io.branch.referral.** { *; }
-keep interface io.branch.referral.** { *; }

# Prevent D8 dexing issues
-keepattributes *Annotation*
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Additional rules for Android compatibility
-dontwarn java.lang.instrument.ClassFileTransformer
-dontwarn sun.misc.SignalHandler