import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/engine/https/config/web_adapter_config.dart';
import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// The box the web reads from [config].
Object? platformAdapterBox(HttpClientConfig config) => config.webAdapter;

/// A browser adapter built from [box], a [WebAdapterConfig].
HttpClientAdapter buildPlatformAdapter(Object box) => BrowserHttpClientAdapter(
  withCredentials: (box as WebAdapterConfig).withCredentials,
);

/// Diagnostics about [config]'s adapter box: none on the web.
List<String> adapterDiagnostics(
  HttpClientConfig config, {
  required bool adapterBuilt,
}) => const [];
