import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Default [FirebaseOptions] for the current platform.
class DefaultFirebaseOptions {
  /// Options for the current platform.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'WEB_API_KEY_STUB',
        appId: '1:123456789:web:12345',
        messagingSenderId: '123456789',
        projectId: 'vysion-v2-stub',
        authDomain: 'vysion-v2-stub.firebaseapp.com',
        storageBucket: 'vysion-v2-stub.appspot.com',
        measurementId: 'G-12345',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'ANDROID_API_KEY_STUB',
          appId: '1:123456789:android:12345',
          messagingSenderId: '123456789',
          projectId: 'vysion-v2-stub',
          storageBucket: 'vysion-v2-stub.appspot.com',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'IOS_API_KEY_STUB',
          appId: '1:123456789:ios:12345',
          messagingSenderId: '123456789',
          projectId: 'vysion-v2-stub',
          storageBucket: 'vysion-v2-stub.appspot.com',
          iosBundleId: 'com.vysion.app',
        );
      case TargetPlatform.macOS:
        return const FirebaseOptions(
          apiKey: 'MACOS_API_KEY_STUB',
          appId: '1:123456789:ios:12345',
          messagingSenderId: '123456789',
          projectId: 'vysion-v2-stub',
          storageBucket: 'vysion-v2-stub.appspot.com',
          iosBundleId: 'com.vysion.app',
        );
      case TargetPlatform.windows:
        return const FirebaseOptions(
          apiKey: 'WINDOWS_API_KEY_STUB',
          appId: '1:123456789:windows:12345',
          messagingSenderId: '123456789',
          projectId: 'vysion-v2-stub',
          storageBucket: 'vysion-v2-stub.appspot.com',
        );
      case TargetPlatform.linux:
        return const FirebaseOptions(
          apiKey: 'LINUX_API_KEY_STUB',
          appId: '1:123456789:linux:12345',
          messagingSenderId: '123456789',
          projectId: 'vysion-v2-stub',
          storageBucket: 'vysion-v2-stub.appspot.com',
        );
      case TargetPlatform.fuchsia:
        return const FirebaseOptions(
          apiKey: 'FUCHSIA_API_KEY_STUB',
          appId: '1:123456789:fuchsia:12345',
          messagingSenderId: '123456789',
          projectId: 'vysion-v2-stub',
          storageBucket: 'vysion-v2-stub.appspot.com',
        );
    }
  }
}
