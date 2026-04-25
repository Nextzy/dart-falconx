import 'package:dart_faltool/utils/_app_info_web.dart'
    if (dart.library.io) '_app_info_io.dart'
    as impl;

/// Provides access to application metadata read from `pubspec.yaml`.
///
/// Call [init] at application startup before reading [version].
class AppInfo {
  static String _version = '1.0.0';

  /// The current application version string, defaulting to `'1.0.0'`.
  static String get version => _version;

  /// Initializes app info by reading version from pubspec.yaml at [path].
  ///
  /// Defaults to `'pubspec.yaml'` in the current working directory.
  /// On web this is a no-op — browsers have no filesystem.
  static void init([String path = 'pubspec.yaml']) {
    final loaded = impl.loadVersion(path);
    if (loaded != null) _version = loaded;
  }
}
