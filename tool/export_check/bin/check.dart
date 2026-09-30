import 'dart:io';

import 'package:export_check/export_check.dart';

/// A workspace member; its package config resolves every package and every
/// `dart:` library in this repository.
const _workspace = '../../dart_falconx';

/// This tool's own directory, whose package config resolves `dart_frog`.
const _tool = '.';

const List<LibraryRef> _subjects = [
  (uri: 'package:dart_falconx/dart_falconx.dart', root: _workspace),
  (uri: 'package:dart_falconnect/dart_falconnect.dart', root: _workspace),
  (uri: 'package:dart_falmodel/dart_falmodel.dart', root: _workspace),
  (uri: 'package:dart_faltool/dart_faltool.dart', root: _workspace),
];

const List<LibraryRef> _targets = [
  (uri: 'dart:async', root: _workspace),
  (uri: 'dart:collection', root: _workspace),
  (uri: 'dart:convert', root: _workspace),
  (uri: 'dart:core', root: _workspace),
  (uri: 'dart:developer', root: _workspace),
  (uri: 'dart:ffi', root: _workspace),
  (uri: 'dart:io', root: _workspace),
  (uri: 'dart:isolate', root: _workspace),
  (uri: 'dart:js_interop', root: _workspace),
  (uri: 'dart:js_interop_unsafe', root: _workspace),
  (uri: 'dart:math', root: _workspace),
  (uri: 'dart:typed_data', root: _workspace),
  (uri: 'package:dart_frog/dart_frog.dart', root: _tool),
];

const _retrofitHttpResponse =
    "Retrofit's HttpResponse; code that Retrofit generates for a method "
    'returning HttpResponse<T> needs it. Server apps hide it in their '
    'app-level barrel.';
const _dartFrogName =
    "dio's or Retrofit's name; dart_frog apps hide it in their app-level "
    'barrel.';

const Map<AllowlistKey, String> _allowlist = {
  (subject: 'package:dart_falconx/dart_falconx.dart', name: 'HttpResponse'):
      _retrofitHttpResponse,
  (subject: 'package:dart_falconx/dart_falconx.dart', name: 'Response'):
      _dartFrogName,
  (subject: 'package:dart_falconx/dart_falconx.dart', name: 'FormData'):
      _dartFrogName,
  (subject: 'package:dart_falconx/dart_falconx.dart', name: 'HttpMethod'):
      _dartFrogName,
  (
    subject: 'package:dart_falconnect/dart_falconnect.dart',
    name: 'HttpResponse',
  ): _retrofitHttpResponse,
  (subject: 'package:dart_falconnect/dart_falconnect.dart', name: 'Response'):
      _dartFrogName,
  (subject: 'package:dart_falconnect/dart_falconnect.dart', name: 'FormData'):
      _dartFrogName,
  (subject: 'package:dart_falconnect/dart_falconnect.dart', name: 'HttpMethod'):
      _dartFrogName,
};

Future<void> main() async {
  exitCode = await runCheck(
    subjects: _subjects,
    targets: _targets,
    allowlist: _allowlist,
  );
}
