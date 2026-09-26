import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dio/dio.dart';

/// The box this platform reads from [config]: none, since the platform
/// has neither dart:io nor the browser.
Object? platformAdapterBox(HttpClientConfig config) => null;

/// Never called, because [platformAdapterBox] returns null.
HttpClientAdapter buildPlatformAdapter(Object box) =>
    throw UnsupportedError('No HTTP adapter for this platform');

/// Diagnostics about [config]'s adapter box: none on this platform.
List<String> adapterDiagnostics(
  HttpClientConfig config, {
  required bool adapterBuilt,
}) => const [];
