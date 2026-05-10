# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.location.** { *; }

# Google Play Core (deferred components / split install)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Supabase / GoTrue / Realtime
-dontwarn io.supabase.**
-keep class io.supabase.** { *; }

# Camera / Image Picker
-keep class androidx.camera.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Mobile Scanner (QR)
-keep class com.google.zxing.** { *; }
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Freezed / json_serializable / annotations — reflection 대상 보호
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keep @interface freezed.** { *; }
-keep @interface json_annotation.** { *; }
-keepclassmembers class * {
  @json_annotation.JsonKey *;
  @json_annotation.JsonValue *;
}

# Gson (Supabase 내부 의존성에서 사용 가능)
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Kotlin Reflection (Supabase functions 등에서 사용)
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# OkHttp / Retrofit (Supabase HTTP layer)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
