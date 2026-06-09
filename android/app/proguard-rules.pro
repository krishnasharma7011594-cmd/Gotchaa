# Gotchaa ProGuard Rules

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Networking (Dio)
-keep class com.dio.** { *; }
-dontwarn com.dio.**

# Video Player
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# WebRTC
-keep class org.webrtc.** { *; }

# Image handling
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**

# Cryptography
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# ML Kit
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Google Play Core
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.gms.tasks.**

# AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# JNI
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve classes and members annotated with @Keep
-keep @androidx.annotation.Keep class * { *; }
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <methods>;
}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep <fields>;
}

# ── flutter_secure_storage ────────────────────────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# ── just_audio / ExoPlayer ────────────────────────────────────────────────────
-keep class com.ryanheise.just_audio.** { *; }
-dontwarn com.ryanheise.just_audio.**
-keep class com.ryanheise.** { *; }
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# ── record (audio recording) ──────────────────────────────────────────────────
-keep class com.llfbandit.record.** { *; }
-dontwarn com.llfbandit.record.**

# ── camera ────────────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.camera.** { *; }
-dontwarn io.flutter.plugins.camera.**

# ── geolocator ────────────────────────────────────────────────────────────────
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# ── permission_handler ────────────────────────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ── connectivity_plus ─────────────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-dontwarn dev.fluttercommunity.plus.connectivity.**

# ── share_plus ────────────────────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# ── sensors_plus ──────────────────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.sensors.** { *; }
-dontwarn dev.fluttercommunity.plus.sensors.**

# ── package_info_plus ─────────────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.packageinfo.** { *; }
-dontwarn dev.fluttercommunity.plus.packageinfo.**

# ── device_info_plus ──────────────────────────────────────────────────────────
-keep class dev.fluttercommunity.plus.device_info.** { *; }
-dontwarn dev.fluttercommunity.plus.device_info.**

# ── image_picker ──────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**

# ── url_launcher ──────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**

# ── path_provider ─────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# ── shared_preferences ────────────────────────────────────────────────────────
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-dontwarn io.flutter.plugins.sharedpreferences.**

# ── video_compress ────────────────────────────────────────────────────────────
-keep class com.example.videocompress.** { *; }
-dontwarn com.example.videocompress.**
-keep class com.tcubedstudios.flutter_video_compress.** { *; }
-dontwarn com.tcubedstudios.flutter_video_compress.**

# ── flutter_inappwebview ──────────────────────────────────────────────────────
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-dontwarn com.pichillilorenzo.flutter_inappwebview.**

# ── google_sign_in ────────────────────────────────────────────────────────────
-keep class com.google.android.libraries.identity.googleid.** { *; }
-dontwarn com.google.android.libraries.identity.googleid.**

# ── firebase_messaging (FCM) ──────────────────────────────────────────────────
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# ── Serialization / Reflection ────────────────────────────────────────────────
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes SourceFile,LineNumberTable

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <fields>;
    !private <methods>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# OkHttp (used by some Firebase SDKs)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
