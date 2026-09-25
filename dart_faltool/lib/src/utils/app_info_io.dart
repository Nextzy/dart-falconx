import 'package:universal_io/io.dart';
import 'package:yaml/yaml.dart';

/// VM implementation: reads the `version:` field from a pubspec file on disk.
///
/// Returns `null` when the file does not exist or has no `version` field.
String? loadVersion(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;
  final yaml = loadYaml(file.readAsStringSync()) as YamlMap;
  return yaml['version'] as String?;
}
