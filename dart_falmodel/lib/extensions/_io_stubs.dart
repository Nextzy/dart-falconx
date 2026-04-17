// Web stub for the small subset of `dart:io` types referenced by
// `exception_extensions.dart`. These `is` checks can never match on web
// (the real classes only exist on the VM), but the file still has to
// compile under dart2js.
//
// Do not add behaviour here — keep these as inert sentinel classes.

class HttpException implements Exception {}

class HandshakeException implements Exception {}

class CertificateException implements Exception {}

class FileSystemException implements Exception {}

class IOException implements Exception {}

class SocketException implements Exception {}

class TlsException implements Exception {}

class PathNotFoundException implements Exception {}
