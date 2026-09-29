// Reads the pubspec files of this repository from disk.
@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// The URL apps use for this repository. Pub treats two spellings of one
/// repository as two different sources, so sibling dependencies use it as is.
const _repositoryUrl = 'https://github.com/Nextzy/dart-falconx';

const _packages = [
  'dart_falconnect',
  'dart_falconx',
  'dart_falmodel',
  'dart_faltool',
];

Map<dynamic, dynamic> _pubspec(String path) =>
    loadYaml(File(path).readAsStringSync()) as Map<dynamic, dynamic>;

Map<dynamic, dynamic> _dependencies(String package) =>
    (_pubspec('../$package/pubspec.yaml')['dependencies']
        as Map<dynamic, dynamic>?) ??
    const {};

void main() {
  final version = _pubspec('../pubspec.yaml')['version'] as String;

  for (final package in _packages) {
    group(package, () {
      test('carries the repository version', () {
        expect(_pubspec('../$package/pubspec.yaml')['version'], version);
      });

      final siblings = _dependencies(package).keys
          .whereType<String>()
          .where(_packages.contains);

      for (final sibling in siblings) {
        // A path dependency reaches apps as a commit hash, which conflicts
        // with the tag an app writes for the same package.
        test('pins $sibling to the release tag of this version', () {
          final dependency = _dependencies(package)[sibling];
          expect(dependency, isA<Map<dynamic, dynamic>>());
          final git = (dependency as Map<dynamic, dynamic>)['git'];
          expect(git, isA<Map<dynamic, dynamic>>(), reason: 'not a git dep');
          final gitMap = git as Map<dynamic, dynamic>;
          expect(gitMap['url'], _repositoryUrl);
          expect(gitMap['ref'], version);
          expect(gitMap['path'], sibling);
        });
      }
    });
  }

  test('dart_faltool depends on no other package in this repository', () {
    final siblings = _dependencies('dart_faltool').keys
        .where(_packages.contains);
    expect(siblings, isEmpty);
  });
}
