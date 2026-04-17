// Web stub for the small subset of `dart:io` types referenced by
// `exception_extensions.dart`. These `is` checks can never match on web
// (the real classes only exist on the VM), but the file still has to
// compile under dart2js.
//
// Do not add behaviour here — keep these as inert sentinel classes.

class HttpException implements Exception {}

class TlsException implements Exception {}

class HandshakeException extends TlsException {}

class CertificateException extends TlsException {}

class IOException implements Exception {}

class FileSystemException extends IOException {}

class PathNotFoundException extends FileSystemException {}

class SocketException extends IOException {}

