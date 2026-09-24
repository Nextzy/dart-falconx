# HTTP platform adapter options

**Date:** 2026-09-25
**Packages:** `dart_falconnect`
**Version:** 2.2.0, released together with the header provider, request ID, and token auth. Every change adds API; nothing breaks.
**Builds on:** the client-config core (`2026-09-24-default-http-client-config-design.md`), which defines `HttpClientConfig`, `configure`, and the diagnostic printer; and the header and auth spec (`2026-09-24-http-header-auth-design.md`), which puts the access token on every request.
**Roadmap:** the second and last spec of the `dart-falconx-client-extensions` phase.

## 1. Context

The config core removed three fields that nothing read (`maxConnectionsPerHost`, `idleConnectionTimeout`, and `validateCertificates`) and left transport options to this phase. `BaseHttpClient.configure` writes only the options its config owns and never touches `dio.httpClientAdapter`. Today an app that needs a connection limit, a proxy, or certificate pinning builds its own `IOHttpClientAdapter`. That code imports `dart:io` and `package:dio/io.dart`, so the app must also write a conditional import, or its web build stops compiling.

Seven facts from the dio 5.11.1 and Dart 3.13 sources shape this design:

1. dio's `IOHttpClientAdapter.validateCertificate` runs after `request.close()` returns the response (`io_adapter.dart`). The request line, the headers, including `Authorization`, and the body have left the device before the check runs. A pin checked there does not keep the token from a man in the middle.
2. dio reads `httpClientAdapter` in `_dispatchRequest` (`dio_mixin.dart`, line 607), after every `onRequest` handler has run. A request that waits in a limiter, and every retry, goes out through the adapter that is current when it is dispatched.
3. When `HttpClient.connectionFactory` is set, `HttpClient` uses the socket the factory returns for a direct connection as it is (`http_impl.dart`, `cf(uri, null, null)`), so a factory that runs TLS itself sees the certificate before any HTTP byte is written. A proxied HTTPS connection goes through `createProxyTunnel`, which calls `SecureSocket.secure` itself and offers no hook to inspect the certificate.
4. Dart exposes the leaf certificate only (`SecureSocket.peerCertificate`); no API returns the chain.
5. `HttpClient.findProxy` defaults to `findProxyFromEnvironment`, which reads `HTTPS_PROXY`. When a proxy entry fails to connect, `_getConnection` tries the next entry, so `PROXY host:port; DIRECT` falls back to a direct connection.
6. `HttpClient` queues requests past `maxConnectionsPerHost` in `_pending`, inside `openUrl`, and dio's `connectTimeout` wraps `openUrl`, so time in that queue counts toward the connect timeout. dio's own `HttpClient` sets `idleTimeout` to 3 seconds; the dart:io default is 15.
7. `dart_falconnect/CLAUDE.md` forbids importing `package:dio/io.dart`. This spec replaces that rule with a narrower one (section 12).

## 2. Goals and non-goals

**Goals**

- One `HttpClientConfig` value sets the connection limit, the idle timeout, the proxy, and certificate pins on `dart:io` platforms, and `withCredentials` on the web. The same value compiles under dart2js, dart2wasm, and the native compiler, and runs on the VM, Flutter mobile and desktop, servers, and the web.
- The app never imports `dart:io` or `package:dio/io.dart` to use any of these options.
- A pin failure stops the request before its first byte leaves the device.
- An Android developer points the app at Proxyman through config alone, and a release build never trusts every certificate, even when the switch is left on.
- An app that sets neither box keeps its adapter and sends the same requests as before.

**Non-goals**

- `native_dio_adapter`, which needs the Flutter SDK, and `dio_http2_adapter`.
- Pinning a host that is reached through a proxy. Such a request fails (section 5.2). Tunnelling `CONNECT` inside the library can come later with no config change.
- Pinning an intermediate or root certificate, since Dart exposes the leaf only.
- Trusted private certificate authorities, client certificates (mTLS), and `enableCORSWarning`.
- Proxy authentication, IPv6 literal proxy hosts, and wildcard pin hosts.
- New per-request options. A request's `extra['withCredentials']` already overrides the web default.
- The WebSocket engine.

## 3. Configuration API

`HttpClientConfig` gains two fields. Each defaults to null, and a null box leaves that platform's adapter alone.

```dart
@freezed
abstract class HttpClientConfig with _$HttpClientConfig {
  const factory({
    // ... the fields of 2.2.0, unchanged ...

    /// Transport settings on dart:io platforms (Android, iOS, macOS,
    /// Windows, Linux, and servers); null leaves the adapter alone. The
    /// web ignores this box.
    IoAdapterConfig? ioAdapter,

    /// Transport settings on the web; null leaves the adapter alone.
    /// dart:io platforms ignore this box.
    WebAdapterConfig? webAdapter,
  }) = _HttpClientConfig;
}
```

```dart
/// Settings of the dart:io adapter that a `BaseHttpClient` builds.
@freezed
abstract class IoAdapterConfig with _$IoAdapterConfig {
  const factory({
    /// Most open connections to one host; null means no limit. Requests
    /// past the limit wait inside `HttpClient`, and that wait counts
    /// toward `connectTimeout`: keep it at or above any per-host limit of
    /// `ConcurrencyConfig`.
    int? maxConnectionsPerHost,

    /// How long an idle connection stays open for reuse. The default is
    /// the value dio uses today.
    @Default(Duration(seconds: 3)) Duration idleTimeout,

    /// Proxy for every request, as `host:port`; null keeps the dart:io
    /// default, which reads `https_proxy`, `http_proxy`, and `no_proxy`
    /// (either case) from the environment. A request that
    /// cannot reach the proxy goes direct, except to a pinned host.
    String? proxy,

    /// Certificate pins keyed by host. Each pin is `sha256/` followed by
    /// the base64 SHA-256 of the leaf certificate's SubjectPublicKeyInfo.
    /// A request to a listed host succeeds only when the leaf matches one
    /// pin. List a backup pin for every host.
    @Default(<String, Set<String>>{}) Map<String, Set<String>> pins,

    /// Trusts every certificate chain, for a debugging proxy such as
    /// Proxyman. It takes effect only while assertions are enabled: Flutter
    /// debug builds, `dart test`, and `dart run --enable-asserts`. Release
    /// builds and `dart compile exe` ignore it. Pins still apply.
    @Default(false) bool debugTrustAnyCertificate,
  }) = _IoAdapterConfig;

  const new _();

  /// Throws [ArgumentError] when a field breaks a rule of section 3.1.
  void validate() {
    // Applies the rules of section 3.1 in table order.
  }
}
```

```dart
/// Settings of the browser adapter that a `BaseHttpClient` builds.
@freezed
abstract class WebAdapterConfig with _$WebAdapterConfig {
  const factory({
    /// Whether cross-site requests send cookies and authorization headers.
    /// A request's `extra['withCredentials']` overrides it.
    @Default(false) bool withCredentials,
  }) = _WebAdapterConfig;
}
```

An app sets both boxes in one config:

```dart
DefaultHttpClient.instance.configure(HttpClientConfig(
  baseUrl: 'https://api.example.com',
  ioAdapter: IoAdapterConfig(
    maxConnectionsPerHost: 6,
    proxy: kDebugMode ? '192.168.1.10:9090' : null,
    pins: kDebugMode
        ? const {}
        : const {
            'api.example.com': {
              'sha256/AAAA...=', // current key
              'sha256/BBBB...=', // backup key
            },
          },
    debugTrustAnyCertificate: true,
  ),
  webAdapter: const WebAdapterConfig(withCredentials: true),
));
```

### 3.1 Validation

`configure` calls `ioAdapter?.validate()` on every platform, during its existing dry run, before it changes anything. A web build therefore reports a bad pin as early as a mobile build does.

| Field | Rule | Error message example |
|---|---|---|
| `proxy` | A host name or IPv4 address, a colon, and a port from 1 to 65535; no scheme, no path | `proxy "http://p:8080" must be host:port` |
| `pins` key | A non-empty bare host name, lowercased before the check (no port, brackets, or spaces); compared without regard to case | `pin host "" is empty`, `pin host "api.example.com:443" must be a bare host name` |
| `pins` value | A non-empty set; each pin is `sha256/` plus base64, padded or not, that decodes to 32 bytes | `pin host "api.example.com" has no pin`, `pin "AAAA" for api.example.com must be "sha256/" followed by base64 of 32 bytes` |
| `maxConnectionsPerHost` | Null or at least 1 | `maxConnectionsPerHost must be at least 1` |
| `idleTimeout` | Not negative | `idleTimeout must not be negative` |

## 4. Platform selection

Four private files under `lib/src/engine/https/adapter/`:

| File | Imports | Role |
|---|---|---|
| `platform_adapter.dart` | the three files below, conditionally | The one entry point `BaseHttpClient` uses |
| `platform_adapter_stub.dart` | pure Dart | Any platform without `dart:io` or `dart:js_interop`: no box applies, so the adapter stays |
| `platform_adapter_io.dart` | `dart:io`, `package:dio/io.dart` | Builds the adapter of section 5 from `ioAdapter` |
| `platform_adapter_web.dart` | `package:dio/browser.dart` | Builds the adapter of section 7 from `webAdapter` |

```dart
// platform_adapter.dart
export 'platform_adapter_stub.dart'
    if (dart.library.io) 'platform_adapter_io.dart'
    if (dart.library.js_interop) 'platform_adapter_web.dart';
```

Each implementation exposes the same three functions. The stub's `platformAdapterBox` returns null, so `configure` never calls its `buildPlatformAdapter`, which throws `UnsupportedError`. The stub and the web return no diagnostics.

```dart
/// The box this platform reads from [config], or null.
Object? platformAdapterBox(HttpClientConfig config);

/// A new adapter built from [box], which [platformAdapterBox] returned.
HttpClientAdapter buildPlatformAdapter(Object box);

/// The diagnostics of section 10 for [config]: all of them when
/// [adapterBuilt], else only the connection-limit one.
List<String> adapterDiagnostics(
  HttpClientConfig config, {
  required bool adapterBuilt,
});
```

`spki.dart` in the same directory is pure Dart. It computes the pin of a DER certificate (section 6) and brings a pin to its padded form, so its tests run on every platform.

## 5. The IO adapter

`buildPlatformAdapter` on `dart:io` returns a private `PinningIoAdapter` that wraps dio's `IOHttpClientAdapter(createHttpClient: ...)`. dio keeps its own request, timeout, redirect, and response code; the library configures only the `HttpClient` that dio asks for.

### 5.1 `HttpClient` settings

| `HttpClient` member | Value |
|---|---|
| `idleTimeout` | `idleTimeout` |
| `maxConnectionsPerHost` | `maxConnectionsPerHost` |
| `findProxy` | Section 5.3, when `proxy` is set; otherwise the dart:io default |
| `badCertificateCallback` | Accepts every certificate when the debug switch is in effect (section 5.4); otherwise null |
| `connectionFactory` | Section 5.2, when `pins` is not empty; otherwise null |

`HttpClient.context` stays null, so TLS validates the chain against the platform's trusted roots before any pin check.

### 5.2 Connection factory

The factory receives the request URI and, for a proxied connection, the proxy host and port. It lowercases the URI host and looks it up in `pins`.

| Request | Factory action |
|---|---|
| Pinned host, `https`, direct | `SecureSocket.startConnect(host, port, onBadCertificate: ...)`, then the pin check below |
| Pinned host, any proxy (the app's or `HTTPS_PROXY`) | Throws `CertificatePinningException` with `PinFailure.proxied`, before any connection opens |
| Pinned host, `http` | Throws `CertificatePinningException` with `PinFailure.plainHttp`, before any connection opens |
| Other host, `https`, direct | `SecureSocket.startConnect(host, port, onBadCertificate: ...)` |
| Other host, `http`, direct | `Socket.startConnect(host, port)` |
| Other host, any proxy | `Socket.startConnect(proxyHost, proxyPort)`; `HttpClient` runs the tunnel and its TLS as it does today |

The pin check waits for the handshake, reads `peerCertificate`, and computes its pin (section 6). A match returns the socket to `HttpClient`, which then writes the request. Otherwise the factory destroys the socket and throws `CertificatePinningException`: with `PinFailure.unreadableCertificate` when the socket has no certificate or the parser rejects it, and with `PinFailure.mismatch` when the pin is outside the host's set. The factory returns `ConnectionTask.fromSocket(checked, task.cancel)`, so a cancelled request still cancels the connect.

`HttpClient` applies `connectionTimeout`, which dio sets from `connectTimeout` for each request, to the factory's socket future. The handshake and the pin check therefore count toward `connectTimeout`, as the handshake does today.

`HttpClient` keeps a pinned connection idle for reuse, and a reused connection needs no second check, since its TLS session is the one that passed.

### 5.3 Proxy

When `proxy` is `host:port`, `findProxy` returns:

- `PROXY host:port; DIRECT` for a host missing from `pins`, so a closed Proxyman falls back to a direct connection;
- `PROXY host:port` for a pinned host, so the request fails with `PinFailure.proxied` instead of going direct unseen by the proxy.

When `proxy` is null, `findProxy` stays `HttpClient.findProxyFromEnvironment`, and a pinned host that the environment sends through a proxy fails with `PinFailure.proxied`.

### 5.4 Debug switch

The switch is in effect only when `debugTrustAnyCertificate` is true and assertions are enabled:

```dart
var assertionsEnabled = false;
assert(assertionsEnabled = true);
final trustAny = box.debugTrustAnyCertificate && assertionsEnabled;
```

When it is in effect, `HttpClient.badCertificateCallback` and the factory's `onBadCertificate` both accept every certificate, so a direct connection and a proxy tunnel both accept Proxyman's certificate. The pin check of section 5.2 still runs, so a pinned host still rejects Proxyman; an app that wants to see a pinned host in Proxyman drops its pins in debug builds, as the example in section 3 does.

### 5.5 Error mapping

`PinningIoAdapter.fetch` delegates to the inner adapter and turns a `CertificatePinningException` into `DioException.badCertificate(requestOptions: options, error: exception)`. `RetryInterceptor` never retries `badCertificate` (`retry_interceptor.dart`, line 209). Every other error passes unchanged. `close` delegates to the inner adapter.

### 5.6 `CertificatePinningException`

A public, pure-Dart class in `lib/engine/https/certificate_pinning_exception.dart`, exported from `https.dart`, so an app checks for it with `is` on every platform:

```dart
/// Why a pinned request failed.
enum PinFailure { mismatch, proxied, plainHttp, unreadableCertificate }

/// A request to a pinned host failed before it was sent.
class CertificatePinningException implements Exception {
  const CertificatePinningException({
    required this.host,
    required this.failure,
    required this.expected,
    this.presented,
  });

  final String host;
  final PinFailure failure;
  final Set<String> expected;

  /// The pin of the certificate the server presented, when one was read.
  final String? presented;
}
```

`toString` names the host, the failure, the expected pins, and the presented pin, for example `CertificatePinningException: api.example.com presented sha256/XYZ...=, expected one of sha256/AAAA...=, sha256/BBBB...=`. A developer copies the presented pin into the config after a planned key change.

## 6. SPKI pin

`spki.dart` extracts the SubjectPublicKeyInfo element from a DER certificate and returns `sha256/` plus the base64 of its SHA-256:

1. Read the outer `Certificate` SEQUENCE, then the `tbsCertificate` SEQUENCE inside it.
2. Skip the optional `[0]` version element (tag `0xA0`), then `serialNumber`, `signature`, `issuer`, `validity`, and `subject`.
3. Take the next element, `subjectPublicKeyInfo`, whole: its tag, its length bytes, and its content.
4. Hash those bytes with `sha256` from hashlib, which `dart_faltool` re-exports, and encode the digest with `base64Encode`.

The reader accepts DER lengths in short form and in long form with at most 3 length bytes, and combines length bytes with multiplication, never a shift, so it gives the same result on the web. Any other shape throws `FormatException`, which the pin check reports as `PinFailure.unreadableCertificate`. The result matches this command, which the documentation gives developers:

```bash
openssl s_client -connect api.example.com:443 -servername api.example.com </dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary | base64
```

## 7. The web adapter

`buildPlatformAdapter` on the web returns `BrowserHttpClientAdapter(withCredentials: box.withCredentials)`. It sets nothing else, so dio's CORS warning keeps its default.

## 8. `configure`, swap, and `dispose`

`BaseHttpClient` keeps two adapter references: `_builtAdapter`, the adapter it built, and `_originalAdapter`, the adapter `dio` held before the client first replaced it.

| Box before, after | Action |
|---|---|
| null, null | Nothing |
| null, set | Store `dio.httpClientAdapter` in `_originalAdapter`, build an adapter, and set it on `dio`. The original is never closed. |
| set, equal box | Keep the built adapter |
| set, different box | Build an adapter, set it on `dio`, and close the previous built adapter with `force: false` |
| set, null | Set `_originalAdapter` back on `dio`, and close the built adapter with `force: false` |

- The box is the one `platformAdapterBox` returns, so on the web only `webAdapter` changes the adapter, and on `dart:io` only `ioAdapter` does. Equality is freezed equality, which compares `pins` deeply.
- `configure` builds the new adapter before it changes anything, next to the interceptors it builds, and sets it at the point where it swaps the interceptor list. If validation or the build throws, the current configuration stays.
- A request already inside `fetch` finishes on the old adapter: `IOHttpClientAdapter.close(force: false)` lets `HttpClient` finish its active connections, and `BrowserHttpClientAdapter.close(force: false)` aborts nothing. A request still waiting in a limiter, and every retry, goes through the new adapter (fact 2 of section 1).
- While a box is set, the client owns `dio.httpClientAdapter`. If the app replaces the adapter by hand, the next `configure` that changes the box sets the new built adapter over it and does not close the app's adapter.
- `dispose()` closes the built adapter with `force: false`, sets `_originalAdapter` back, and clears both references, so a CLI or a test ends without waiting for idle connections. A later `configure` with a box builds a new adapter, as it builds new limiters today.

## 9. Errors seen by the caller

| Situation | Error | Retried |
|---|---|---|
| The leaf does not match any pin | `DioException`, type `badCertificate`, `error` a `CertificatePinningException` with `PinFailure.mismatch` | No |
| A pinned host is reached through a proxy | The same, with `PinFailure.proxied` | No |
| A pinned host is called over `http` | The same, with `PinFailure.plainHttp` | No |
| The certificate cannot be read | The same, with `PinFailure.unreadableCertificate` | No |
| The chain fails platform validation | Unchanged from today | Unchanged |
| A malformed `proxy` or pin | `configure` throws `ArgumentError` | Not applicable |

The exception handler at the end of the chain receives the `badCertificate` error as it receives any other `DioException`.

## 10. Diagnostics

Printed through the client's diagnostic printer, so they appear only when the log box enables diagnostics, and as JSON lines in JSON mode. Each is printed after the new configuration is in place, never once per request: all three when `configure` builds a new IO adapter, and the first also when `configure` changes the `concurrency` box while an IO adapter box is set.

- `maxConnectionsPerHost` is lower than `ConcurrencyConfig.perHost` or a value in `ConcurrencyConfig.hosts`: requests past the connection limit wait inside `HttpClient` and count toward `connectTimeout`.
- The debug switch is in effect: the adapter trusts every certificate chain.
- A pinned host has one pin: no backup pin is listed for it.

## 11. Testing plan

TDD. The test certificate is a committed, self-signed fixture: an RSA 2048 key and a certificate for `localhost` with `subjectAltName` `DNS:localhost` and `IP:127.0.0.1`, valid for 100 years, generated once with `openssl`. Its pin is computed once with the command of section 6 and recorded as a constant.

| File | Contents |
|---|---|
| `test/fixtures/localhost.crt.pem`, `test/fixtures/localhost.key.pem` | The certificate and key, for `HttpServer.bindSecure` |
| `test/fixtures/localhost_certificate.dart` | The certificate DER as a base64 constant and its expected pin, so the SPKI tests run in Chrome |

**Every platform (VM and Chrome)**

- `spki_test.dart`: the fixture's pin equals the recorded `openssl` value; a certificate without the version element parses; truncated input and a 4-byte length throw `FormatException`.
- `adapter_config_test.dart`: each rule of section 3.1 throws with its message; `configure` with a bad pin throws and keeps the previous configuration.

**VM only (`@TestOn('vm')`), against a loopback `HttpServer.bindSecure` that counts the requests it receives**

The fixture is self-signed, so platform validation rejects it. Every pin test sets `debugTrustAnyCertificate`, which works under `dart test` because assertions are on; the pin check then decides alone, and the tests also prove that pins apply while the switch is in effect.

- A matching pin succeeds; a backup pin succeeds.
- A wrong pin fails with `badCertificate`, the error names the presented pin, and the server received 0 requests. The request carries an `Authorization` header, so this proves the token never left.
- A pinned host with `proxy` set fails with `PinFailure.proxied`, and neither the proxy nor the server received a request.
- A pinned host over `http` fails with `PinFailure.plainHttp`.
- A host without a pin goes through `proxy`, which a loopback server records; with the proxy port closed, the same request reaches the origin directly.
- The debug switch: under `dart test`, assertions are on, so a client with the switch reaches the self-signed server and a client without it gets a handshake error. The `trustAny` rule is a function of the switch and an `assertionsEnabled` flag, unit-tested with the flag false.
- `maxConnectionsPerHost: 1` with two gated concurrent requests: the server never sees more than one open connection.
- The `HttpClient` builder sets `idleTimeout` and `maxConnectionsPerHost`.
- `RetryInterceptor` in the chain makes one attempt on a pin failure.
- Swap: a gated request on the old adapter finishes after `configure` changes the box; a later fetch on the old adapter throws `StateError`, which proves it was closed; a queued request uses the new adapter.
- A recording adapter the app set before the first box is back on `dio` after the box returns to null, and its `close` was never called; `dispose` closes the built adapter and restores the original.

**Chrome only (`@TestOn('browser')`)**

- `webAdapter: WebAdapterConfig(withCredentials: true)` sets a `BrowserHttpClientAdapter` whose `withCredentials` is true.
- A config with only `ioAdapter` leaves the adapter identical to the one before.
- A box that returns to null restores the original adapter.

**Compile gate:** `test/web/compile_smoke.dart` builds a config with both boxes and a `CertificatePinningException`, so `melos run test:compile` covers them under dart2js, dart2wasm, and the native compiler.

**Mutation checks**, each of which must fail a named test: return the socket without the pin check; add `DIRECT` for a pinned host; drop the `assertionsEnabled` condition; close the original adapter; close with `force: true`; skip the `configure` dry-run validation.

**Device check before release**, run by the owner, since `SecureSocket.peerCertificate` on iOS and Android cannot be tested on macOS: on one iOS device and one Android device, a debug build with the real host's pins succeeds, a build with one wrong pin fails with `PinFailure.mismatch`, and a debug build with the switch and `proxy` set to Proxyman shows traffic for a host without pins.

## 12. Documentation

Per the skill maintenance rule, in the same change:

| File | Change |
|---|---|
| `skills/dart-falconx-package/references/http.md` | A "Transport options" section: both boxes, the platform each applies to, the pin format and the `openssl` command, backup pins and `certbot --reuse-key`, the Proxyman recipe of section 3, the proxy fallback rule, `perHost` of 6 or less on the web, and `maxConnectionsPerHost` at or above `perHost` |
| `skills/dart-falconx-package/SKILL.md` | The client-configuration row gains `ioAdapter` and `webAdapter`; the exception list gains `CertificatePinningException` |
| `dart_falconnect/CLAUDE.md` | The "Web caveats" rule becomes: import `package:dio/io.dart` only in `platform_adapter_io.dart` and `package:dio/browser.dart` only in `platform_adapter_web.dart`; everywhere else, leave `httpClientAdapter` to `configure` |

## 13. Implementation logistics

- Prototype first in a throwaway worktree, then write the plan from the prototype and replay it task by task, as the header and auth plan did.
- Execute in a git worktree on branch `feature/platform-adapter` from the `develop` commit that holds this spec.
- Run `dart run build_runner build --delete-conflicting-outputs` in `dart_falconnect` after changing the freezed boxes.
- Generate the fixture once:

  ```bash
  openssl req -x509 -newkey rsa:2048 -nodes -days 36500 \
    -keyout localhost.key.pem -out localhost.crt.pem \
    -subj "/CN=localhost" -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
  ```

- hashlib's `sha256` comes through `dart_faltool`; no new dependency. `package:dio/io.dart` and `package:dio/browser.dart` ship with dio.
- Export new public files from the barrels in alphabetical order.
- Commit with `git commit -- <paths>`. No `Co-Authored-By` or AI attribution.
- Do not push or tag. The owner releases 2.2.0 with both specs.

## 14. Risks

| Risk | Mitigation |
|---|---|
| `peerCertificate` behaves differently on iOS or Android | The device check of section 11 before release |
| A server renews its certificate with a new key, and every installed app stops connecting | Backup pins, the single-pin diagnostic, and the `certbot --reuse-key` note in the docs |
| The debug switch ships in a release build | It depends on assertions, which release builds and `dart compile exe` disable; a unit test covers the flag-false path |
| A pinned request goes around the configured proxy unseen | A pinned host gets no `DIRECT` entry and fails instead |
| A hidden `HttpClient` queue turns into `connectionTimeout` errors | The diagnostic of section 10 and the docs |
| A swap closes a connection that a request still uses | `force: false` and the gated swap test |
| The library closes an adapter the app owns | The ownership rule of section 8 and its test |
| The DER reader breaks on the web through 32-bit integer operations | Multiplication instead of shifts, and the SPKI tests in Chrome |
| The committed test key triggers a secret-scanning alert | The key serves only `localhost` in tests; the fixture file names say so |

## 15. Success criteria

- An app sets both boxes in one `HttpClientConfig`, imports neither `dart:io` nor `package:dio/io.dart`, and builds for the web, Android, iOS, macOS, and a server.
- A request to a pinned host with a wrong pin fails with `badCertificate` before the server receives it.
- A debug build reaches Proxyman on Android with `proxy` and the switch; a release build with the switch left on validates certificates exactly as a build without the switch does.
- `maxConnectionsPerHost`, `idleTimeout`, `proxy`, and `withCredentials` reach the platform clients.
- An app that sets neither box keeps its adapter and sends the same requests as before.
- `melos run analyze`, `melos run test`, `melos run build_runner:check`, and `melos run test:platforms` pass.
- Every file in section 12 matches the code.

## 16. Details decided in this spec, for owner review

The brainstorm settled scope, shape, pin mechanism and format, the debug switch, the proxy API, swap semantics, the test certificate, the approach, and the four design sections. These points were chosen while writing and are open to change at review.

1. `idleTimeout` defaults to 3 seconds, the value dio uses today, so a box set only for pins changes nothing else.
2. Pin hosts match exactly, without regard to case, with no wildcards.
3. `configure` validates `ioAdapter` on every platform, including the web.
4. One pin per host is accepted, with a diagnostic.
5. `CertificatePinningException` is a plain exception class, like `CommonException`, not a freezed model, and it lives in `dart_falconnect`, not `dart_falmodel`, because it belongs to the transport.
6. Pins still apply while the debug switch is in effect.
7. A pinned host over plain `http` fails.
8. A pinned host gets `PROXY host:port` with no `DIRECT` fallback.
9. While a box is set, the client owns `dio.httpClientAdapter`; `dispose` closes the built adapter and restores the original.
10. `proxy` accepts a host name or an IPv4 address; IPv6 literals are out.
11. The DER reader accepts at most 3 length bytes, which covers certificates up to 16 MB.
12. The three diagnostics print when an adapter is built, not per request.
13. The private files live in `lib/src/engine/https/adapter/`, and the public exception in `lib/engine/https/certificate_pinning_exception.dart`.
