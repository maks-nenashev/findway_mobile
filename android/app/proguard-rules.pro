# =============================================================================
# FILE: android/app/proguard-rules.pro
# RESPONSIBILITY: R8 / ProGuard Obfuscation & Shrinking Protection Rules
# =============================================================================

# 1. Flutter Engine & Plugins Protection
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# 2. Suppress missing Google Play Core Deferred Components warnings (Fixes R8 Build Error)
-dontwarn com.google.android.play.core.**

# 3. Preserve Annotations & Reflection Attributes
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# 4. Preserve FindWay Data Models, DTOs & JSON Serialization
-keep class com.findway.findway_mobile.features.**.data.models.** { *; }
-keepclassmembers class com.findway.findway_mobile.features.**.data.models.** { *; }

# 5. Preserve Network Stack (Dio, OkHttp, Okio)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }