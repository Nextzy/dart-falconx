/// Whether [key] is a bare host exactly as `Uri.host` returns it:
/// lowercase, with no port, brackets, or spaces.
///
/// Shared by the interceptors that take per-host settings, so a key they
/// accept always matches `options.uri.host`.
bool isHostKey(String key) {
  if (key.isEmpty) {
    return false;
  }
  try {
    return Uri(scheme: 'http', host: key).host == key;
  } on FormatException {
    return false;
  }
}
