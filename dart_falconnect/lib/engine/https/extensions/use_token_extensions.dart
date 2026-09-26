import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart' show Extra;

/// Key in `RequestOptions.extra` that turns the auth token off for one
/// request when its value is false.
const String useTokenExtraKey = 'dart_falconnect.auth.useToken';

/// Retrofit annotation: the endpoint sends no token and never refreshes.
///
/// ```dart
/// @GET('/public/news')
/// @noToken
/// Future<List<News>> news();
/// ```
const Extra noToken = Extra({useTokenExtraKey: false});

/// Whether a request carries the auth token, on [RequestOptions].
extension FalconAuthRequestOptionsExtensions on RequestOptions {
  /// Whether the auth interceptors stamp and refresh a token; true unless a
  /// request method was called with `isUseToken: false` or the endpoint
  /// carries [noToken].
  bool get useToken => extra[useTokenExtraKey] != false;
  set useToken(bool value) => extra = {...extra, useTokenExtraKey: value};
}

/// Whether a request carries the auth token, on [Options].
extension FalconAuthOptionsExtensions on Options {
  /// Whether the auth interceptors stamp and refresh a token; true when
  /// unset.
  bool get useToken => extra?[useTokenExtraKey] != false;
  set useToken(bool value) => extra = {...?extra, useTokenExtraKey: value};
}
