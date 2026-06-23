// Web stub for the small subset of `dart:io` types referenced by
// `exception_extensions.dart`. These `is` checks can never match on web
// (the real classes only exist on the VM), but the file still has to
// compile under dart2js.
//
// Do not add behaviour here — keep these as inert sentinel classes.

/// Web stub for `dart:io` [HttpException].
class HttpException implements Exception {}

/// Web stub for `dart:io` [TlsException].
class TlsException implements Exception {}

/// Web stub for `dart:io` [HandshakeException].
class HandshakeException extends TlsException {}

/// Web stub for `dart:io` [CertificateException].
class CertificateException extends TlsException {}

/// Web stub for `dart:io` [IOException].
class IOException implements Exception {}

/// Web stub for `dart:io` [FileSystemException].
class FileSystemException extends IOException {}

/// Web stub for `dart:io` [PathNotFoundException].
class PathNotFoundException extends FileSystemException {}

/// Web stub for `dart:io` [SocketException].
class SocketException extends IOException {}
