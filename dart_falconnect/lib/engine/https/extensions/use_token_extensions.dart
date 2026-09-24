import 'package:dio/dio.dart';

const String _useTokenKey = 'dart_falconnect.auth.useToken';

/// Whether a request carries the auth token, on [RequestOptions].
extension FalconAuthRequestOptionsExtensions on RequestOptions {
  /// Whether an auth interceptor should attach the token; true unless a
  /// request method was called with `isUseToken: false`.
  bool get useToken => extra[_useTokenKey] != false;
  set useToken(bool value) => extra = {...extra, _useTokenKey: value};
}

/// Whether a request carries the auth token, on [Options].
extension FalconAuthOptionsExtensions on Options {
  /// Whether an auth interceptor should attach the token; true when unset.
  bool get useToken => extra?[_useTokenKey] != false;
  set useToken(bool value) => extra = {...?extra, _useTokenKey: value};
}
