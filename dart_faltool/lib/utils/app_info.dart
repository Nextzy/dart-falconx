import 'package:dart_faltool/lib.dart';

class AppInfo {
  static String _version = '1.0.0';

  static String get version => _version;

  /// Initializes app info by reading version from pubspec.yaml at [path].
  ///
  /// Defaults to `'pubspec.yaml'` in the current working directory.
  static void init([String path = 'pubspec.yaml']) {
    final file = File(path);
    if (file.existsSync()) {
      final yaml = loadYaml(file.readAsStringSync()) as YamlMap;
      _version = yaml['version'] as String? ?? _version;
    }
  }
}
