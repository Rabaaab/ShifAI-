import 'platform_helper_stub.dart' if (dart.library.io) 'platform_helper_io.dart' as impl;

/// True on Android/iOS, false everywhere else (web, desktop).
/// Camera + on-device OCR (Google ML Kit) only ship native implementations
/// for Android/iOS, so this gates the scan flow to platforms that actually
/// support it, and safely compiles on web too (no dart:io import there).
bool get isMobilePlatform => impl.isMobilePlatformImpl;
