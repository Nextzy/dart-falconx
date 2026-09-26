# HTTP Platform Adapter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let one `HttpClientConfig` set the dart:io connection limit, idle timeout, proxy, and certificate pins, and the web's `withCredentials`, without the app importing `dart:io`.

**Architecture:** Two freezed boxes, `ioAdapter` and `webAdapter`, sit on `HttpClientConfig`. A private conditional export picks one platform file. On dart:io it wraps dio's `IOHttpClientAdapter` around an `HttpClient` whose `connectionFactory` runs TLS itself and checks the leaf certificate's SPKI pin before `HttpClient` writes the request. `BaseHttpClient.configure` builds the adapter beside the interceptors, closes a replaced one with `force: false`, and restores the app's original adapter when the box returns to null.

**Tech Stack:** Dart 3.13, dio 5.11.1 with dio_web_adapter 2.2.2 (through `package:dio/browser.dart`), freezed 3, hashlib (through `dart_faltool`), package:test, melos.

**Spec:** `docs/superpowers/specs/2026-09-25-http-platform-adapter-design.md`

## Global Constraints

- Version 2.2.0, released together with the header provider, request ID, and token auth. Every change adds API; nothing breaks. This plan never bumps the version, pushes, merges, or tags.
- Every package stays pure Dart. `dart:io` and `package:dio/io.dart` appear only in `lib/src/engine/https/adapter/platform_adapter_io.dart`, and `package:dio/browser.dart` only in `platform_adapter_web.dart`, both reached through the conditional export in `platform_adapter.dart`.
- Every model is freezed: `IoAdapterConfig` and `WebAdapterConfig`. `CertificatePinningException` is a plain exception class, as spec section 16 item 5 rules.
- Defaults: `ioAdapter` and `webAdapter` null; `maxConnectionsPerHost` null; `idleTimeout` 3 seconds; `proxy` null; `pins` empty; `debugTrustAnyCertificate` false; `withCredentials` false.
- A pin is `sha256/` plus the base64 SHA-256 of the leaf certificate's SubjectPublicKeyInfo. Pin hosts compare lowercase, with no wildcards.
- A pinned host fails with `PinFailure.proxied` through any proxy and with `PinFailure.plainHttp` over `http`. With `proxy` set, a pinned host gets `PROXY host:port` and every other host `PROXY host:port; DIRECT`.
- The debug switch takes effect only while assertions are enabled, and pins still apply while it does.
- `configure` validates `ioAdapter` on every platform during its dry run. It closes a replaced adapter with `force: false`, never closes an adapter it did not build, and restores the original adapter when the box returns to null; `dispose` does the same.
- Diagnostics carry the prefix `[ioAdapter]` and print after the new configuration is in place.
- No new dependency.
- Commit with `git add <paths>` then `git commit -m "..." -- <paths>`. No `Co-Authored-By` or AI attribution.
- A public API change updates `skills/dart-falconx-package/` on the same branch (Task 5).

## Review Focus

1. **A pin copied without its base64 padding**, since some tools strip the `=`. Expected: `validate` accepts it and it matches at connect time. Task 1 test "canonicalPin pads a bare pin and rejects a short one"; Task 3 test "a pin without base64 padding matches".
2. **An unpinned `https` host on a client that pins another host** goes through the connection factory, which runs TLS itself. Expected: its chain is still validated against the platform roots. Task 3 test "an unpinned https host still has its chain validated".
3. **A pin host written in a different case from the URL** (`LocalHost` against `localhost`). Expected: it matches. Task 3 test "a host is matched without regard to case".
4. **A server whose environment sets `HTTPS_PROXY` while it pins a host.** Expected: `PinFailure.proxied`, never a silent direct connection. dart:io reads the environment only in `findProxy`, so the factory branch is the one `proxy` exercises; Task 3 test "a pinned host through a proxy fails before any connect" covers it.
5. **An app that set its own adapter before the first box.** Expected: the client never closes it, and puts it back when the box returns to null and on `dispose`. Task 3 tests "a box replaces the app adapter; null restores it unclosed" and "dispose closes the built adapter and restores the app one".

## Provenance

Every code block below comes from a throwaway prototype cut from `develop` at `dec303e`, then replayed task by task on a second throwaway branch by a script that applies this plan's own blocks; each task compiled and passed its tests on its own, and the replay matched the prototype with zero diff lines, generated files included. Final gates on the replay: `melos run analyze` and `format` clean; `melos run build_runner:check` clean; VM tests falconnect 422 (1 skip, baseline 362), faltool 771, falmodel 71, falconx 1; `melos run test:platforms` passes, with falconnect at 399 under both dart2js and dart2wasm in Chrome (baseline 366). Mutation checks, each failing a named test: returning the socket without the pin check; adding `DIRECT` for a pinned host; dropping the assertions condition of the debug switch; closing the original adapter; closing with `force: true`; skipping the `configure` validation. Both throwaway branches are deleted.

Prototype rulings, for owner review:

1. `buildPlatformAdapter(Object box)` takes no `logPrint`. A third function, `adapterDiagnostics(config, adapterBuilt: ...)`, returns the messages, and `configure` prints them after the new configuration is in place. Spec section 4 is amended to match.
2. A pin host must pass the existing `isHostKey` rule once lowercased (no port, brackets, or spaces): `pin host "<host>" must be a bare host name`. A host with an empty set fails with `pin host "<host>" has no pin`. Spec section 3.1 is amended to match.
3. A pin without base64 padding is accepted and compared in padded form, through the private `canonicalPin` in `spki.dart`.
4. `CertificatePinningException.toString()` has one text per failure; the mismatch text is `CertificatePinningException: <host> presented <pin>, expected one of <pins>`.
5. The three diagnostics read `[ioAdapter] maxConnectionsPerHost <n> is below the concurrency limit <m>: requests past <n> wait inside HttpClient and count toward connectTimeout`, `[ioAdapter] debugTrustAnyCertificate is in effect: every certificate chain is trusted`, and `[ioAdapter] <host> has one pin: add a backup pin`.
6. A chain that fails platform validation arrives as a `DioException` whose `error` is a `HandshakeException`, as it does today; the tests pin this for both the default and the factory path.
7. The fixture certificate and key are written out in Task 1, so every replay is byte-identical. Regenerate them only together with `localhost_certificate.dart`, using the command in spec section 13.
8. `references/http.md` said a `perHost` above 6 "changes nothing on the web". It now says that the browser's queue time counts toward `connectTimeout`, as `dio_web_adapter` measures it.

## Execution setup

```bash
cd "/Users/nonthawit/Data/NTD OS/projects/FalconX/dart-falconx"
git worktree add -b feature/platform-adapter .claude/worktrees/platform-adapter develop
cd .claude/worktrees/platform-adapter
dart pub get
```

Run every `dart` command below from `dart_falconnect/` inside the worktree unless a step says otherwise, and every `melos` or `git` command from the worktree root. The `https` tests bind loopback ports; they need no network.

## File map

| File | Task | Responsibility |
|---|---|---|
| `dart_falconnect/lib/src/engine/https/adapter/spki.dart` | 1 | `spkiPin` from DER, `canonicalPin` |
| `dart_falconnect/test/fixtures/localhost.crt.pem`, `localhost.key.pem`, `localhost_certificate.dart` | 1 | self-signed `localhost` certificate, its key, its DER and pin as constants |
| `dart_falconnect/lib/engine/https/config/io_adapter_config.dart`, `web_adapter_config.dart` | 2 | the two boxes; `IoAdapterConfig.validate` |
| `dart_falconnect/lib/engine/https/certificate_pinning_exception.dart` | 2 | `PinFailure`, `CertificatePinningException` |
| `dart_falconnect/lib/engine/https/config/http_client_config.dart`, `config/config.dart`, `https.dart` | 2 | `ioAdapter` and `webAdapter` fields; exports |
| `dart_falconnect/lib/engine/https/http_client.dart` | 2, 3 | validation in the dry run; adapter build, swap, diagnostics, `dispose` |
| `dart_falconnect/lib/src/engine/https/adapter/platform_adapter.dart`, `_stub.dart`, `_io.dart`, `_web.dart` | 3 | platform selection; the dart:io adapter, connector, and diagnostics; the browser adapter |
| `dart_falconnect/test/web/compile_smoke.dart` | 4 | both boxes and the exception in the compile gate |
| `skills/dart-falconx-package/`, `dart_falconnect/CLAUDE.md` | 5 | consumer skill and agent docs |

---

### Task 1: SPKI pin reader and the test certificate

**Files:**
- Create: `dart_falconnect/lib/src/engine/https/adapter/spki.dart`
- Create: `dart_falconnect/test/fixtures/localhost.crt.pem`, `dart_falconnect/test/fixtures/localhost.key.pem`, `dart_falconnect/test/fixtures/localhost_certificate.dart`
- Test: `dart_falconnect/test/engine/https/adapter/spki_test.dart`

**Interfaces:**
- Consumes: `sha256` from hashlib, re-exported by `package:dart_faltool/dart_faltool.dart`.
- Produces: `String spkiPin(List<int> der)`, which throws `FormatException` on input it cannot read; `String? canonicalPin(String pin)`, which returns `sha256/<padded base64>` or null; the constants `localhostCertificateDer` (base64 DER) and `localhostPin` in `test/fixtures/localhost_certificate.dart`; the PEM files that Task 3's loopback server loads.

- [ ] **Step 1: Add the test certificate**

The certificate is self-signed for `localhost` and `127.0.0.1`, valid until 2126, and serves only these tests.

<!-- file: dart_falconnect/test/fixtures/localhost.crt.pem -->
```text
-----BEGIN CERTIFICATE-----
MIIDJzCCAg+gAwIBAgIUYekrmGRFtZY9+fm80gTWnCDkYnwwDQYJKoZIhvcNAQEL
BQAwFDESMBAGA1UEAwwJbG9jYWxob3N0MCAXDTI2MDkyNDE3MTA1NFoYDzIxMjYw
ODMxMTcxMDU0WjAUMRIwEAYDVQQDDAlsb2NhbGhvc3QwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQCyBCGADoh+0hd1RF3XYmAUwB5G2gguNhSqbqlSdrAJ
oe+Jb3LgJL7n9k/SWXa6ht75V+kQidsO/5/CelsTJdkIQY4XNTzRzzMw0BwgxEHq
dwqNypCNNeaxNZ2D4gYkoZo38pwVtfjUOpNC8qYw6El31Jlkwv2K2kEOz6D9Ovqs
V2pdsIwxp/QHe1mBArSHR9CpLuXazZo+YMIOIm/yXPWOyc1oVQXyB8E+h23DUGQ1
cubJQP0DD/TiIwi4Iuhqq2uYN6zb7aL69skzllafKagpHD5bgGVJxKxGOpS7QV0/
Sk5LhPMe337c+uh+yA6FkrH6Cr57HiX8wStHzhkDfT+/AgMBAAGjbzBtMB0GA1Ud
DgQWBBT4lBzdP+f/KGw4MyY2zs6N8L9UbjAfBgNVHSMEGDAWgBT4lBzdP+f/KGw4
MyY2zs6N8L9UbjAPBgNVHRMBAf8EBTADAQH/MBoGA1UdEQQTMBGCCWxvY2FsaG9z
dIcEfwAAATANBgkqhkiG9w0BAQsFAAOCAQEAPIyW4F2IAsJyMU/wJo8IhG7d55U/
O+bBex1R1MKJbLjyFeDqbuCBCE+mOKIJa/H3+InAV4sSszW/pTlu3foEDEnNmPCW
67Jl1W18VgYa6MinkQslADleAaclyggMpap9kd0R9C+KDX/LMnnL5PADWxQv7D73
5CV8GHG2wXko/X425uszS9vWBQXpsAVmscVK657zlr1gaVWNHDVUlqnv3gdhtTW8
z8w3PFj/wVWh/qEI/4OAqmqdcXJqzPgkyIZMEDk4n17ccTEhLV0q8wK694ARpMhK
jUYUah9Wu93DToUJQpkFOSix1ghranCH025DPOzAWb9LxOzMqQZYbBJXsw==
-----END CERTIFICATE-----
```

<!-- file: dart_falconnect/test/fixtures/localhost.key.pem -->
```text
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCyBCGADoh+0hd1
RF3XYmAUwB5G2gguNhSqbqlSdrAJoe+Jb3LgJL7n9k/SWXa6ht75V+kQidsO/5/C
elsTJdkIQY4XNTzRzzMw0BwgxEHqdwqNypCNNeaxNZ2D4gYkoZo38pwVtfjUOpNC
8qYw6El31Jlkwv2K2kEOz6D9OvqsV2pdsIwxp/QHe1mBArSHR9CpLuXazZo+YMIO
Im/yXPWOyc1oVQXyB8E+h23DUGQ1cubJQP0DD/TiIwi4Iuhqq2uYN6zb7aL69skz
llafKagpHD5bgGVJxKxGOpS7QV0/Sk5LhPMe337c+uh+yA6FkrH6Cr57HiX8wStH
zhkDfT+/AgMBAAECggEAT5D6Gj8ksi6cTo1WtljhohS206tLYcBJX14j71heWYfY
RWEbguTZsVtOFTJol3mF+wPYh8xeLaeC1E2VHItbpM2MQYJJo2uNsWErWVfvMGmx
vWuPTZaMfKN+un5RiZjzkdMuAaQ6yj0+KfvD3XNNtzI+t6NR6PihgIm8JsNwXIvc
0TCjfrX+x8pMw3gqbbZlSqcLlXgYj2CUDOC75LN+0I9+BSje7iECUf5h2Eq4kjwj
Dv50zx54H9IeFq+GE85GjtCdSCHpW/G/uvADjx7HgDx0umPQkEtkvtSYmKjrwlfB
a/qk/95VsjMPOODVd2/WMvx0UV6BR4H3wfU9GgKWtQKBgQDf6pv0LrWRicrwA6lI
tZC5SzLo+32YaVIu+29Frv0U2+XGPMjnFYAPSOp8MXDz8dCaut2ZSai5pmC8rgJg
oMg1qpGhzms3LiRTHPWzsGwyn8Mrth56X1KYeP1OqECBkQbrWLbkUFk7fVU6rM2+
ypOCw+7GSdfyo9MqpcqYJZLqVQKBgQDLhd7hLM8OPYPEJDiDgi3Z+f01kJ79VOjK
SOq3B6ZxtjjeqVbjSgA0JpvkVjeBzfx30nmSbDoqEi3RsqhMt0PcfhM3JB3fucKt
JA7QiKbYQu4npNTfS7dHvhu/+D0Zi35FQi9Fa1wInRwC/JGmN8sYnxhEBHOBKKsZ
iVr680S9wwKBgQC/EaAgXlc7KHyOEGG8lIo5QwzfN/K1QnIJey45JRf6W6YXYbkB
Txxmbo8AiOPclaSu0/PSIMOkH2/+sPGAaNJO0QzSKKTegjYm4dhbi5jYHfHZ897Q
B1UgnGVyYCojJZDk9F+kNVffZpR6rAgo3Q3AkNbIRyzJdLf1dWGKMM3LvQKBgQCW
5QRgkuZZOoaNUAWOi2APcuenZThbvy5xfCp51XQ0btQvUgIXtm/8OnvuiXXSCbUb
6bM1OoTNWHkcNofNiTsJKXh5s49qpsGNuWQ6fHandMg6IF2ryOl0iaDtbdFvNRtD
olSF9Zlg0YtJM5WRVWCBOsO0+k/g/RQOdOY9lUvsHQKBgCIpI4Rl/hWyOdGCtytA
VQY1Ke/21oxIHGE+zuSDWkHjfFDSNvWNBSygZ8DuzNEFrdf0+IpdV/tZ5nX5OVnu
MFBXMXU0sTFgx4HQjmV56FJ2590VG4PoPGoDzxlCFYqL6T+NL73yCzGKYpjzS7u0
MZKZ5YRz+ySphsoceOMBlb0p
-----END PRIVATE KEY-----
```

<!-- file: dart_falconnect/test/fixtures/localhost_certificate.dart -->
```dart
// The test certificate of localhost.crt.pem, for tests that cannot read
// files, such as the SPKI tests in Chrome. Regenerate both together.

/// The certificate in DER form, base64-encoded.
const localhostCertificateDer =
    'MIIDJzCCAg+gAwIBAgIUYekrmGRFtZY9+fm80gTWnCDkYnwwDQYJKoZIhvcNAQEL'
    'BQAwFDESMBAGA1UEAwwJbG9jYWxob3N0MCAXDTI2MDkyNDE3MTA1NFoYDzIxMjYw'
    'ODMxMTcxMDU0WjAUMRIwEAYDVQQDDAlsb2NhbGhvc3QwggEiMA0GCSqGSIb3DQEB'
    'AQUAA4IBDwAwggEKAoIBAQCyBCGADoh+0hd1RF3XYmAUwB5G2gguNhSqbqlSdrAJ'
    'oe+Jb3LgJL7n9k/SWXa6ht75V+kQidsO/5/CelsTJdkIQY4XNTzRzzMw0BwgxEHq'
    'dwqNypCNNeaxNZ2D4gYkoZo38pwVtfjUOpNC8qYw6El31Jlkwv2K2kEOz6D9Ovqs'
    'V2pdsIwxp/QHe1mBArSHR9CpLuXazZo+YMIOIm/yXPWOyc1oVQXyB8E+h23DUGQ1'
    'cubJQP0DD/TiIwi4Iuhqq2uYN6zb7aL69skzllafKagpHD5bgGVJxKxGOpS7QV0/'
    'Sk5LhPMe337c+uh+yA6FkrH6Cr57HiX8wStHzhkDfT+/AgMBAAGjbzBtMB0GA1Ud'
    'DgQWBBT4lBzdP+f/KGw4MyY2zs6N8L9UbjAfBgNVHSMEGDAWgBT4lBzdP+f/KGw4'
    'MyY2zs6N8L9UbjAPBgNVHRMBAf8EBTADAQH/MBoGA1UdEQQTMBGCCWxvY2FsaG9z'
    'dIcEfwAAATANBgkqhkiG9w0BAQsFAAOCAQEAPIyW4F2IAsJyMU/wJo8IhG7d55U/'
    'O+bBex1R1MKJbLjyFeDqbuCBCE+mOKIJa/H3+InAV4sSszW/pTlu3foEDEnNmPCW'
    '67Jl1W18VgYa6MinkQslADleAaclyggMpap9kd0R9C+KDX/LMnnL5PADWxQv7D73'
    '5CV8GHG2wXko/X425uszS9vWBQXpsAVmscVK657zlr1gaVWNHDVUlqnv3gdhtTW8'
    'z8w3PFj/wVWh/qEI/4OAqmqdcXJqzPgkyIZMEDk4n17ccTEhLV0q8wK694ARpMhK'
    'jUYUah9Wu93DToUJQpkFOSix1ghranCH025DPOzAWb9LxOzMqQZYbBJXsw==';

/// The certificate's pin, from `openssl x509 -pubkey | openssl pkey -pubin
/// -outform der | openssl dgst -sha256 -binary | base64`.
const localhostPin = 'sha256/QqpXzCTGTZNjvpITlKLoKPESRb8C33BVNBPi3mSWk+s=';
```

- [ ] **Step 2: Write the failing test**

<!-- file: dart_falconnect/test/engine/https/adapter/spki_test.dart -->
```dart
import 'dart:convert';

import 'package:dart_falconnect/src/engine/https/adapter/spki.dart';
import 'package:dart_faltool/dart_faltool.dart' show sha256;
import 'package:test/test.dart';

import '../../../fixtures/localhost_certificate.dart';

/// One DER element with a short-form length.
List<int> _tlv(int tag, List<int> content) => [tag, content.length, ...content];

void main() {
  test('the fixture pin matches the openssl value', () {
    expect(spkiPin(base64Decode(localhostCertificateDer)), localhostPin);
  });

  test('reads a certificate without the version element', () {
    final spki = _tlv(0x30, _tlv(0x03, [0, 1, 2, 3]));
    final der = _tlv(0x30, [
      ..._tlv(0x30, [
        ..._tlv(0x02, [1]), // serialNumber
        ..._tlv(0x30, []), // signature
        ..._tlv(0x30, []), // issuer
        ..._tlv(0x30, []), // validity
        ..._tlv(0x30, []), // subject
        ...spki,
      ]),
    ]);

    expect(spkiPin(der), 'sha256/${base64Encode(sha256.convert(spki).bytes)}');
  });

  test('rejects a truncated certificate', () {
    final der = base64Decode(localhostCertificateDer);

    expect(() => spkiPin(der.sublist(0, 100)), throwsFormatException);
  });

  test('rejects a length of 4 bytes', () {
    expect(() => spkiPin([0x30, 0x84, 0, 0, 0, 1, 0]), throwsFormatException);
  });

  test('canonicalPin pads a bare pin and rejects a short one', () {
    expect(canonicalPin(localhostPin.replaceAll('=', '')), localhostPin);
    expect(canonicalPin(localhostPin), localhostPin);
    expect(canonicalPin('sha256/AAAA'), isNull);
    expect(canonicalPin('sha1/${localhostPin.substring(7)}'), isNull);
  });

  test('rejects empty input', () {
    expect(() => spkiPin(const []), throwsFormatException);
  });

  test('rejects a certificate whose fields end before the key', () {
    final der = _tlv(0x30, [
      ..._tlv(0x30, [
        ..._tlv(0x02, [1]),
      ]),
    ]);

    expect(() => spkiPin(der), throwsFormatException);
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `dart test test/engine/https/adapter/spki_test.dart`
Expected: FAIL to load, with `Error when reading 'lib/src/engine/https/adapter/spki.dart': No such file or directory`.

- [ ] **Step 4: Write the reader**

<!-- file: dart_falconnect/lib/src/engine/https/adapter/spki.dart -->
```dart
import 'dart:convert';

import 'package:dart_faltool/dart_faltool.dart' show sha256;

/// The pin of the DER certificate [der]: `sha256/` and the base64
/// SHA-256 of its SubjectPublicKeyInfo element, tag and length included.
///
/// Throws [FormatException] when [der] is not an X.509 certificate this
/// reader understands.
String spkiPin(List<int> der) {
  final certificate = _Element.at(der, 0, 'Certificate');
  final tbs = _Element.at(der, certificate.contentStart, 'tbsCertificate');
  var field = _Element.at(der, tbs.contentStart, 'serialNumber');
  if (field.tag == _versionTag) {
    field = _Element.at(der, field.end, 'serialNumber');
  }
  // serialNumber, signature, issuer, validity, subject.
  for (var skipped = 0; skipped < 5; skipped++) {
    field = _Element.at(der, field.end, 'subjectPublicKeyInfo');
  }
  if (field.tag != _sequenceTag || field.end > tbs.end) {
    throw const FormatException('No subjectPublicKeyInfo in certificate');
  }
  final digest = sha256.convert(der.sublist(field.start, field.end)).bytes;
  return '$_pinPrefix${base64Encode(digest)}';
}

/// [pin] in the form [spkiPin] returns, `sha256/` and padded base64, or
/// null when it is not `sha256/` followed by base64 of 32 bytes.
String? canonicalPin(String pin) {
  if (!pin.startsWith(_pinPrefix)) return null;
  try {
    final digest = base64.normalize(pin.substring(_pinPrefix.length));
    return base64Decode(digest).length == 32 ? '$_pinPrefix$digest' : null;
  } on FormatException {
    return null;
  }
}

const _pinPrefix = 'sha256/';

const _sequenceTag = 0x30;
const _versionTag = 0xA0;

/// One DER element: its tag, and where its bytes start and end in the
/// certificate.
class _Element {
  const new(this.tag, this.start, this.contentStart, this.end);

  /// Reads the element at [start] of [der]. [name] names it in errors.
  ///
  /// Lengths are combined by multiplication, never a shift, so the result
  /// is the same on the web, where `int` shifts truncate to 32 bits.
  factory at(List<int> der, int start, String name) {
    if (start + 2 > der.length) {
      throw FormatException('Certificate ends before $name');
    }
    final tag = der[start];
    if (tag & 0x1F == 0x1F) {
      throw FormatException('Unsupported multi-byte tag at $name');
    }
    final first = der[start + 1];
    var length = first;
    var contentStart = start + 2;
    if (first >= 0x80) {
      final count = first & 0x7F;
      if (count == 0 || count > 3) {
        throw FormatException('Unsupported length form at $name');
      }
      if (contentStart + count > der.length) {
        throw FormatException('Certificate ends inside the length of $name');
      }
      length = 0;
      for (var i = 0; i < count; i++) {
        length = length * 256 + der[contentStart + i];
      }
      contentStart += count;
    }
    final end = contentStart + length;
    if (end > der.length) {
      throw FormatException('Certificate ends inside $name');
    }
    return _Element(tag, start, contentStart, end);
  }

  final int tag;
  final int start;
  final int contentStart;
  final int end;
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `dart test test/engine/https/adapter/spki_test.dart && dart test -p chrome test/engine/https/adapter/spki_test.dart`
Expected: PASS, 7 tests on the VM and 7 in Chrome. The Chrome run proves the length arithmetic on 32-bit web integers.

- [ ] **Step 6: Analyze, format, and commit**

```bash
dart analyze && dart format --set-exit-if-changed .
cd .. && git add dart_falconnect/lib/src/engine/https/adapter/spki.dart dart_falconnect/test/fixtures dart_falconnect/test/engine/https/adapter/spki_test.dart
git commit -m "feat(dart_falconnect): read the SPKI pin of a DER certificate" -- dart_falconnect/lib/src/engine/https/adapter/spki.dart dart_falconnect/test/fixtures dart_falconnect/test/engine/https/adapter/spki_test.dart
```

### Task 2: Adapter config boxes, `CertificatePinningException`, and validation

**Files:**
- Create: `dart_falconnect/lib/engine/https/config/io_adapter_config.dart`, `dart_falconnect/lib/engine/https/config/web_adapter_config.dart`
- Create: `dart_falconnect/lib/engine/https/certificate_pinning_exception.dart`
- Modify: `dart_falconnect/lib/engine/https/config/http_client_config.dart` (imports and two fields), `dart_falconnect/lib/engine/https/config/config.dart`, `dart_falconnect/lib/engine/https/https.dart`, `dart_falconnect/lib/engine/https/http_client.dart` (the dry run)
- Test: `dart_falconnect/test/engine/https/config/adapter_config_test.dart`

**Interfaces:**
- Consumes: `canonicalPin` (Task 1); `isHostKey` from `lib/src/engine/https/interceptors/host_key.dart`; `localhostPin` (Task 1); `ScriptedAdapter`, `reply`, `FoldingTransformer` from `test/engine/https/interceptors/_scripted_adapter.dart`.
- Produces: `IoAdapterConfig({int? maxConnectionsPerHost, Duration idleTimeout, String? proxy, Map<String, Set<String>> pins, bool debugTrustAnyCertificate})` with `void validate()`; `WebAdapterConfig({bool withCredentials})`; `HttpClientConfig.ioAdapter` and `.webAdapter`; `enum PinFailure { mismatch, proxied, plainHttp, unreadableCertificate }`; `CertificatePinningException({required String host, required PinFailure failure, required Set<String> expected, String? presented})`. All public, through `package:dart_falconnect/dart_falconnect.dart`.

- [ ] **Step 1: Write the failing test**

<!-- file: dart_falconnect/test/engine/https/config/adapter_config_test.dart -->
```dart
import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:test/test.dart';

import '../../../fixtures/localhost_certificate.dart';
import '../interceptors/_scripted_adapter.dart';

class _Client extends BaseHttpClient {
  new(HttpClientAdapter adapter)
    : super(
        dio: Dio()
          ..httpClientAdapter = adapter
          ..transformer = FoldingTransformer(),
      );
}

Matcher _argumentError(String message) =>
    throwsA(isA<ArgumentError>().having((e) => e.message, 'message', message));

void main() {
  group('defaults', () {
    test('leave both adapters alone', () {
      const config = HttpClientConfig();

      expect(config.ioAdapter, isNull);
      expect(config.webAdapter, isNull);
    });

    test('match what dio does without a box', () {
      const io = IoAdapterConfig();
      const web = WebAdapterConfig();

      expect(io.maxConnectionsPerHost, isNull);
      expect(io.idleTimeout, const Duration(seconds: 3));
      expect(io.proxy, isNull);
      expect(io.pins, isEmpty);
      expect(io.debugTrustAnyCertificate, isFalse);
      expect(web.withCredentials, isFalse);
    });

    test('boxes with equal pins are equal', () {
      const a = IoAdapterConfig(
        pins: {
          'api.example.com': {localhostPin},
        },
      );
      const b = IoAdapterConfig(
        pins: {
          'api.example.com': {localhostPin},
        },
      );

      expect(a, b);
    });
  });

  group('validate', () {
    test('accepts a host name or IPv4 proxy and padded or bare pins', () {
      final unpadded = localhostPin.replaceAll('=', '');

      expect(
        () => IoAdapterConfig(
          maxConnectionsPerHost: 1,
          idleTimeout: Duration.zero,
          proxy: '192.168.1.10:9090',
          pins: {
            'API.Example.com': {localhostPin, unpadded},
          },
        ).validate(),
        returnsNormally,
      );
      expect(
        () => const IoAdapterConfig(proxy: 'proxy.local:65535').validate(),
        returnsNormally,
      );
    });

    test('rejects a connection limit below 1', () {
      expect(
        () => const IoAdapterConfig(maxConnectionsPerHost: 0).validate(),
        _argumentError('maxConnectionsPerHost must be at least 1'),
      );
    });

    test('rejects a negative idle timeout', () {
      expect(
        () =>
            const IoAdapterConfig(idleTimeout: Duration(seconds: -1))
                .validate(),
        _argumentError('idleTimeout must not be negative'),
      );
    });

    for (final proxy in [
      'http://p:8080',
      'p',
      ':8080',
      'p:0',
      'p:65536',
      'p:80a',
      '[::1]:8080',
      '::1:8080',
      'p:8080/path',
    ]) {
      test('rejects the proxy "$proxy"', () {
        expect(
          () => IoAdapterConfig(proxy: proxy).validate(),
          _argumentError('proxy "$proxy" must be host:port'),
        );
      });
    }

    test('rejects an empty pin host', () {
      expect(
        () => const IoAdapterConfig(
          pins: {
            '': {localhostPin},
          },
        ).validate(),
        _argumentError('pin host "" is empty'),
      );
    });

    test('rejects a pin host with a port', () {
      expect(
        () => const IoAdapterConfig(
          pins: {
            'api.example.com:443': {localhostPin},
          },
        ).validate(),
        _argumentError(
          'pin host "api.example.com:443" must be a bare host name',
        ),
      );
    });

    test('rejects a pin host with no pin', () {
      expect(
        () =>
            const IoAdapterConfig(pins: {'api.example.com': <String>{}})
                .validate(),
        _argumentError('pin host "api.example.com" has no pin'),
      );
    });

    for (final pin in [
      'AAAA',
      'sha1/QqpXzCTGTZNjvpITlKLoKPESRb8C33BVNBPi3mSWk+s=',
      'sha256/not base64!',
      'sha256/AAAA',
    ]) {
      test('rejects the pin "$pin"', () {
        expect(
          () => IoAdapterConfig(
            pins: {
              'api.example.com': {pin},
            },
          ).validate(),
          _argumentError(
            'pin "$pin" for api.example.com must be "sha256/" followed by '
            'base64 of 32 bytes',
          ),
        );
      });
    }
  });

  test('configure throws on a bad pin and keeps the configuration', () {
    final adapter = ScriptedAdapter([reply(200)]);
    final client = _Client(adapter);
    const before = HttpClientConfig(baseUrl: 'https://before.test');
    client.configure(before);

    expect(
      () => client.configure(
        const HttpClientConfig(
          baseUrl: 'https://after.test',
          ioAdapter: IoAdapterConfig(
            pins: {
              'after.test': {'AAAA'},
            },
          ),
        ),
      ),
      throwsArgumentError,
    );
    expect(client.currentConfig, before);
    expect(client.baseUrl, 'https://before.test');
    expect(client.dio.httpClientAdapter, same(adapter));
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `dart test test/engine/https/config/adapter_config_test.dart`
Expected: FAIL to load, with `Method not found: 'IoAdapterConfig'` and `No named parameter with the name 'ioAdapter'`.

- [ ] **Step 3: Add the boxes and the exception**

<!-- file: dart_falconnect/lib/engine/https/config/io_adapter_config.dart -->
```dart
import 'package:dart_falconnect/src/engine/https/adapter/spki.dart';
import 'package:dart_falconnect/src/engine/https/interceptors/host_key.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/io_adapter_config.freezed.dart';

/// Settings of the dart:io adapter that a `BaseHttpClient` builds; a
/// non-null box replaces the adapter on Android, iOS, macOS, Windows,
/// Linux, and servers. The web ignores this box.
@freezed
abstract class IoAdapterConfig with _$IoAdapterConfig {
  /// Creates dart:io adapter settings.
  const factory({
    /// Most open connections to one host; null means no limit. Requests
    /// past the limit wait inside `HttpClient`, and that wait counts
    /// toward `connectTimeout`: keep it at or above any per-host limit of
    /// `ConcurrencyConfig`.
    int? maxConnectionsPerHost,

    /// How long an idle connection stays open for reuse. The default is
    /// the value dio uses.
    @Default(Duration(seconds: 3)) Duration idleTimeout,

    /// Proxy for every request, as `host:port`; null keeps the dart:io
    /// default, which reads `https_proxy`, `http_proxy`, and `no_proxy`
    /// (either case) from the environment. A request that cannot reach
    /// the proxy goes direct, except to a pinned host.
    String? proxy,

    /// Certificate pins keyed by host. Each pin is `sha256/` followed by
    /// the base64 SHA-256 of the leaf certificate's SubjectPublicKeyInfo.
    /// A request to a listed host succeeds only when the leaf matches one
    /// pin, and fails when it goes through a proxy or over plain `http`.
    /// List a backup pin for every host.
    @Default(<String, Set<String>>{}) Map<String, Set<String>> pins,

    /// Trusts every certificate chain, for a debugging proxy such as
    /// Proxyman. It takes effect only while assertions are enabled:
    /// Flutter debug builds, `dart test`, and `dart run --enable-asserts`.
    /// Release builds and `dart compile exe` ignore it. Pins still apply.
    @Default(false) bool debugTrustAnyCertificate,
  }) = _IoAdapterConfig;

  const new _();

  /// Throws [ArgumentError] when a field is malformed.
  void validate() {
    final max = maxConnectionsPerHost;
    if (max != null && max < 1) {
      throw ArgumentError('maxConnectionsPerHost must be at least 1');
    }
    if (idleTimeout.isNegative) {
      throw ArgumentError('idleTimeout must not be negative');
    }
    final proxy = this.proxy;
    if (proxy != null && !_isProxy(proxy)) {
      throw ArgumentError('proxy "$proxy" must be host:port');
    }
    for (final MapEntry(key: host, value: hostPins) in pins.entries) {
      if (host.isEmpty) {
        throw ArgumentError('pin host "" is empty');
      }
      if (!isHostKey(host.toLowerCase())) {
        throw ArgumentError('pin host "$host" must be a bare host name');
      }
      if (hostPins.isEmpty) {
        throw ArgumentError('pin host "$host" has no pin');
      }
      for (final pin in hostPins) {
        if (canonicalPin(pin) == null) {
          throw ArgumentError(
            'pin "$pin" for $host must be "sha256/" followed by base64 '
            'of 32 bytes',
          );
        }
      }
    }
  }

  /// Whether [proxy] is a host name or IPv4 address, a colon, and a port
  /// from 1 to 65535.
  static bool _isProxy(String proxy) {
    final colon = proxy.lastIndexOf(':');
    if (colon <= 0) return false;
    final host = proxy.substring(0, colon);
    final port = proxy.substring(colon + 1);
    if (host.contains(':') || !isHostKey(host.toLowerCase())) return false;
    if (!RegExp(r'^\d{1,5}$').hasMatch(port)) return false;
    final number = int.parse(port);
    return number >= 1 && number <= 65535;
  }
}
```

<!-- file: dart_falconnect/lib/engine/https/config/web_adapter_config.dart -->
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'generated/web_adapter_config.freezed.dart';

/// Settings of the browser adapter that a `BaseHttpClient` builds; a
/// non-null box replaces the adapter on the web. dart:io platforms ignore
/// this box.
@freezed
abstract class WebAdapterConfig with _$WebAdapterConfig {
  /// Creates browser adapter settings.
  const factory({
    /// Whether cross-site requests send cookies and authorization headers.
    /// A request's `extra['withCredentials']` overrides it.
    @Default(false) bool withCredentials,
  }) = _WebAdapterConfig;
}
```

<!-- file: dart_falconnect/lib/engine/https/certificate_pinning_exception.dart -->
```dart
/// Why a request to a pinned host failed.
enum PinFailure {
  /// The leaf certificate matches none of the host's pins.
  mismatch,

  /// The request would go through a proxy, where no pin can be checked.
  proxied,

  /// The request uses plain `http`, which has no certificate.
  plainHttp,

  /// The connection has no certificate, or its certificate cannot be read.
  unreadableCertificate,
}

/// A request to a pinned host failed before any of it was sent.
///
/// `BaseHttpClient` delivers it as the `error` of a `DioException` whose
/// type is `badCertificate`, which `RetryInterceptor` never retries.
class CertificatePinningException implements Exception {
  /// Creates a pinning failure for [host].
  const new({
    required this.host,
    required this.failure,
    required this.expected,
    this.presented,
  });

  /// The lowercase host of the request.
  final String host;

  /// Why the request failed.
  final PinFailure failure;

  /// The host's pins.
  final Set<String> expected;

  /// The pin of the certificate the server presented, when one was read.
  final String? presented;

  @override
  String toString() {
    final pins = expected.join(', ');
    return switch (failure) {
      PinFailure.mismatch =>
        'CertificatePinningException: $host presented $presented, '
            'expected one of $pins',
      PinFailure.proxied =>
        'CertificatePinningException: $host is pinned and cannot be '
            'reached through a proxy',
      PinFailure.plainHttp =>
        'CertificatePinningException: $host is pinned and cannot be '
            'reached over plain http',
      PinFailure.unreadableCertificate =>
        'CertificatePinningException: $host presented no readable '
            'certificate, expected one of $pins',
    };
  }
}
```

- [ ] **Step 4: Add the two fields to `HttpClientConfig`**

<!-- replace: dart_falconnect/lib/engine/https/config/http_client_config.dart -->
```dart
import 'package:dart_falconnect/engine/https/config/concurrency_config.dart';
```

with:

<!-- with -->
```dart
import 'package:dart_falconnect/engine/https/config/concurrency_config.dart';
import 'package:dart_falconnect/engine/https/config/io_adapter_config.dart';
```

<!-- replace: dart_falconnect/lib/engine/https/config/http_client_config.dart -->
```dart
import 'package:dart_falconnect/engine/https/config/retry_config.dart';
```

with:

<!-- with -->
```dart
import 'package:dart_falconnect/engine/https/config/retry_config.dart';
import 'package:dart_falconnect/engine/https/config/web_adapter_config.dart';
```

<!-- replace: dart_falconnect/lib/engine/https/config/http_client_config.dart -->
```dart
    /// Access token and 401 refresh; null turns them off.
    AuthConfig? auth,
  }) = _HttpClientConfig;
```

with:

<!-- with -->
```dart
    /// Access token and 401 refresh; null turns them off.
    AuthConfig? auth,

    /// Transport settings on dart:io platforms; null leaves the adapter
    /// alone. The web ignores this box.
    IoAdapterConfig? ioAdapter,

    /// Transport settings on the web; null leaves the adapter alone.
    /// dart:io platforms ignore this box.
    WebAdapterConfig? webAdapter,
  }) = _HttpClientConfig;
```

- [ ] **Step 5: Export the new files**

<!-- replace: dart_falconnect/lib/engine/https/config/config.dart -->
```dart
export 'http_client_config.dart';
```

with:

<!-- with -->
```dart
export 'http_client_config.dart';
export 'io_adapter_config.dart';
```

<!-- replace: dart_falconnect/lib/engine/https/config/config.dart -->
```dart
export 'retry_config.dart';
```

with:

<!-- with -->
```dart
export 'retry_config.dart';
export 'web_adapter_config.dart';
```

<!-- replace: dart_falconnect/lib/engine/https/https.dart -->
```dart
export 'config/config.dart';
```

with:

<!-- with -->
```dart
export 'certificate_pinning_exception.dart';
export 'config/config.dart';
```

- [ ] **Step 6: Validate the box in the `configure` dry run**

<!-- replace: dart_falconnect/lib/engine/https/http_client.dart -->
```dart
  /// Throws, and keeps the current configuration, when an interceptor
  /// cannot be built from [config] or dio rejects one of its options.
  void configure(HttpClientConfig config) {
    // A dry run on a scratch Dio: dio checks options in its setters, so a
    // value it rejects throws here, before this client changes.
    config.applyTo(Dio());
```

with:

<!-- with -->
```dart
  /// Throws, and keeps the current configuration, when an interceptor
  /// cannot be built from [config], dio rejects one of its options, or
  /// its `ioAdapter` box is malformed.
  void configure(HttpClientConfig config) {
    // A dry run on a scratch Dio: dio checks options in its setters, so a
    // value it rejects throws here, before this client changes.
    config.applyTo(Dio());
    // Checked on every platform, so a web build reports a bad pin too.
    config.ioAdapter?.validate();
```

- [ ] **Step 7: Generate the freezed code**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: writes `lib/engine/https/config/generated/io_adapter_config.freezed.dart`, `web_adapter_config.freezed.dart`, and a new `http_client_config.freezed.dart`.

- [ ] **Step 8: Run the test to verify it passes**

Run: `dart test test/engine/https/config/adapter_config_test.dart && dart test -p chrome test/engine/https/config/adapter_config_test.dart`
Expected: PASS, 23 tests on the VM and 23 in Chrome.

- [ ] **Step 9: Run the package suite, analyze, format, and commit**

```bash
dart test && dart analyze && dart format --set-exit-if-changed .
cd .. && git add dart_falconnect/lib/engine/https dart_falconnect/test/engine/https/config/adapter_config_test.dart
git commit -m "feat(dart_falconnect): add the ioAdapter and webAdapter config boxes" -- dart_falconnect/lib/engine/https dart_falconnect/test/engine/https/config/adapter_config_test.dart
```

### Task 3: The dart:io adapter and the swap in `BaseHttpClient`

**Files:**
- Create: `dart_falconnect/lib/src/engine/https/adapter/platform_adapter.dart`, `platform_adapter_stub.dart`, `platform_adapter_io.dart`, `platform_adapter_web.dart`
- Modify: `dart_falconnect/lib/engine/https/http_client.dart` (import, docs, two fields, build, swap, diagnostics, `dispose`)
- Test: `dart_falconnect/test/engine/https/adapter/io_adapter_test.dart`, `dart_falconnect/test/engine/https/adapter/adapter_swap_test.dart`

**Interfaces:**
- Consumes: `spkiPin`, `canonicalPin`, the fixtures (Task 1); `IoAdapterConfig`, `WebAdapterConfig`, `CertificatePinningException`, `PinFailure`, `HttpClientConfig.ioAdapter` and `.webAdapter` (Task 2).
- Produces, in each platform file: `Object? platformAdapterBox(HttpClientConfig config)`, `HttpClientAdapter buildPlatformAdapter(Object box)`, `List<String> adapterDiagnostics(HttpClientConfig config, {required bool adapterBuilt})`. In `platform_adapter_io.dart` only: `class PinningIoAdapter implements HttpClientAdapter`, `HttpClient createIoHttpClient(IoAdapterConfig box, {required bool trustAny})`, `bool trustsAnyCertificate(IoAdapterConfig box, {required bool assertionsEnabled})`. `BaseHttpClient` gains no public member.

- [ ] **Step 1: Write the failing tests**

<!-- file: dart_falconnect/test/engine/https/adapter/io_adapter_test.dart -->
```dart
@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falconnect/src/engine/https/adapter/platform_adapter_io.dart';
import 'package:test/test.dart';

import '../../../fixtures/localhost_certificate.dart';

const _wrongPin = 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';

/// A loopback server that counts the requests it receives and answers
/// each with 200 once [gate] completes.
class _Server {
  new _(this.server) {
    server.listen((request) async {
      requests.add(request.uri);
      await gate?.future;
      request.response.write('{"ok":true}');
      await request.response.close();
    });
  }

  static Future<_Server> https() async {
    final context = SecurityContext()
      ..useCertificateChain('test/fixtures/localhost.crt.pem')
      ..usePrivateKey('test/fixtures/localhost.key.pem');
    return _Server._(
      await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, context),
    );
  }

  static Future<_Server> http() async =>
      _Server._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer server;
  final List<Uri> requests = [];
  Completer<void>? gate;

  int get port => server.port;

  Future<void> close() => server.close(force: true);
}

class _Client extends BaseHttpClient {
  new(HttpClientConfig config) : super(dio: Dio(), config: config);
}

/// Counts the attempts that pass the custom slot.
class _AttemptCounter extends Interceptor {
  int attempts = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    attempts++;
    handler.next(options);
  }
}

Future<Response<Object?>> _get(BaseHttpClient client, String url) =>
    client.dio.get<Object?>(
      url,
      options: Options(headers: {'Authorization': 'Bearer secret-token'}),
    );

Matcher _pinFailure(PinFailure failure, {String? presented}) => throwsA(
  isA<DioException>()
      .having((e) => e.type, 'type', DioExceptionType.badCertificate)
      .having(
        (e) => e.error,
        'error',
        isA<CertificatePinningException>()
            .having((e) => e.failure, 'failure', failure)
            .having((e) => e.host, 'host', 'localhost')
            .having((e) => e.presented, 'presented', presented),
      ),
);

void main() {
  late _Server tls;

  setUp(() async => tls = await _Server.https());
  tearDown(() => tls.close());

  String tlsUrl() => 'https://localhost:${tls.port}/me';

  // The fixture is self-signed, so every pin test also sets the debug
  // switch, which works under `dart test` because assertions are on.
  IoAdapterConfig pinned(Set<String> pins, {String? proxy}) => IoAdapterConfig(
    pins: {'localhost': pins},
    proxy: proxy,
    debugTrustAnyCertificate: true,
  );

  group('pins', () {
    test('a matching pin sends the request', () async {
      final client = _Client(
        HttpClientConfig(ioAdapter: pinned({localhostPin})),
      );

      final response = await _get(client, tlsUrl());

      expect(response.statusCode, 200);
      expect(tls.requests, hasLength(1));
      client.dispose();
    });

    test('a backup pin sends the request', () async {
      final client = _Client(
        HttpClientConfig(ioAdapter: pinned({_wrongPin, localhostPin})),
      );

      expect((await _get(client, tlsUrl())).statusCode, 200);
      client.dispose();
    });

    test('a wrong pin fails before the server receives anything', () async {
      final client = _Client(HttpClientConfig(ioAdapter: pinned({_wrongPin})));

      await expectLater(
        _get(client, tlsUrl()),
        _pinFailure(PinFailure.mismatch, presented: localhostPin),
      );
      expect(tls.requests, isEmpty);
      client.dispose();
    });

    test('the error names the presented pin', () async {
      final client = _Client(HttpClientConfig(ioAdapter: pinned({_wrongPin})));

      try {
        await _get(client, tlsUrl());
        fail('the request should fail');
      } on DioException catch (e) {
        expect(
          '${e.error}',
          'CertificatePinningException: localhost presented $localhostPin, '
              'expected one of $_wrongPin',
        );
      }
      client.dispose();
    });

    test('a pin without base64 padding matches', () async {
      final client = _Client(
        HttpClientConfig(ioAdapter: pinned({localhostPin.replaceAll('=', '')})),
      );

      expect((await _get(client, tlsUrl())).statusCode, 200);
      client.dispose();
    });

    test('an unpinned https host still has its chain validated', () async {
      final client = _Client(
        const HttpClientConfig(
          ioAdapter: IoAdapterConfig(
            pins: {
              'pinned.example': {localhostPin},
            },
          ),
        ),
      );

      await expectLater(
        _get(client, tlsUrl()),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<HandshakeException>(),
          ),
        ),
      );
      expect(tls.requests, isEmpty);
      client.dispose();
    });

    test('an unpinned https host passes with the debug switch', () async {
      final client = _Client(
        const HttpClientConfig(
          ioAdapter: IoAdapterConfig(
            pins: {
              'pinned.example': {localhostPin},
            },
            debugTrustAnyCertificate: true,
          ),
        ),
      );

      expect((await _get(client, tlsUrl())).statusCode, 200);
      client.dispose();
    });

    test('a host is matched without regard to case', () async {
      final client = _Client(
        const HttpClientConfig(
          ioAdapter: IoAdapterConfig(
            pins: {
              'LocalHost': {_wrongPin},
            },
            debugTrustAnyCertificate: true,
          ),
        ),
      );

      await expectLater(
        _get(client, tlsUrl()),
        _pinFailure(PinFailure.mismatch, presented: localhostPin),
      );
      client.dispose();
    });

    test('a pinned host through a proxy fails before any connect', () async {
      final proxy = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      var proxyConnections = 0;
      proxy.listen((socket) {
        proxyConnections++;
        socket.destroy();
      });
      addTearDown(proxy.close);
      final client = _Client(
        HttpClientConfig(
          ioAdapter: pinned({localhostPin}, proxy: 'localhost:${proxy.port}'),
        ),
      );

      await expectLater(
        _get(client, tlsUrl()),
        _pinFailure(PinFailure.proxied),
      );
      expect(proxyConnections, 0);
      expect(tls.requests, isEmpty);
      client.dispose();
    });

    test('a pinned host over plain http fails before any connect', () async {
      final plain = await _Server.http();
      addTearDown(plain.close);
      final client = _Client(
        HttpClientConfig(ioAdapter: pinned({localhostPin})),
      );

      await expectLater(
        _get(client, 'http://localhost:${plain.port}/me'),
        _pinFailure(PinFailure.plainHttp),
      );
      expect(plain.requests, isEmpty);
      client.dispose();
    });

    test('RetryInterceptor makes one attempt on a pin failure', () async {
      final counter = _AttemptCounter();
      final client = _Client(
        HttpClientConfig(
          interceptors: [counter],
          retry: const RetryConfig(delay: Duration.zero),
          ioAdapter: pinned({_wrongPin}),
        ),
      );

      await expectLater(
        _get(client, tlsUrl()),
        _pinFailure(PinFailure.mismatch, presented: localhostPin),
      );
      expect(counter.attempts, 1);
      client.dispose();
    });
  });

  group('debug switch', () {
    test('without it, a self-signed server fails its handshake', () async {
      final client = _Client(
        const HttpClientConfig(ioAdapter: IoAdapterConfig()),
      );

      await expectLater(
        _get(client, tlsUrl()),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<HandshakeException>(),
          ),
        ),
      );
      expect(tls.requests, isEmpty);
      client.dispose();
    });

    test('with it, a self-signed server answers', () async {
      final client = _Client(
        const HttpClientConfig(
          ioAdapter: IoAdapterConfig(debugTrustAnyCertificate: true),
        ),
      );

      expect((await _get(client, tlsUrl())).statusCode, 200);
      client.dispose();
    });

    test('takes effect only while assertions are enabled', () {
      const on = IoAdapterConfig(debugTrustAnyCertificate: true);
      const off = IoAdapterConfig();

      expect(trustsAnyCertificate(on, assertionsEnabled: true), isTrue);
      expect(trustsAnyCertificate(on, assertionsEnabled: false), isFalse);
      expect(trustsAnyCertificate(off, assertionsEnabled: true), isFalse);
    });
  });

  group('proxy', () {
    late _Server origin;
    late _Server proxy;

    setUp(() async {
      origin = await _Server.http();
      proxy = await _Server.http();
    });
    tearDown(() async {
      await origin.close();
      await proxy.close();
    });

    // Pins on another host keep the connection factory in the path.
    for (final pins in <Map<String, Set<String>>>[
      {},
      {
        'pinned.example': {localhostPin},
      },
    ]) {
      final label = pins.isEmpty ? 'without pins' : 'with a factory';

      test('$label, an unpinned request goes through the proxy', () async {
        final client = _Client(
          HttpClientConfig(
            ioAdapter: IoAdapterConfig(
              proxy: '127.0.0.1:${proxy.port}',
              pins: pins,
            ),
          ),
        );

        final response = await _get(
          client,
          'http://127.0.0.1:${origin.port}/me',
        );

        expect(response.statusCode, 200);
        expect(proxy.requests.single.path, '/me');
        expect(origin.requests, isEmpty);
        client.dispose();
      });

      test('$label, a closed proxy falls back to direct', () async {
        final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final port = closed.port;
        await closed.close();
        final client = _Client(
          HttpClientConfig(
            ioAdapter: IoAdapterConfig(proxy: '127.0.0.1:$port', pins: pins),
          ),
        );

        final response = await _get(
          client,
          'http://127.0.0.1:${origin.port}/me',
        );

        expect(response.statusCode, 200);
        expect(origin.requests, hasLength(1));
        client.dispose();
      });
    }
  });

  group('HttpClient', () {
    test('takes the idle timeout and the connection limit', () {
      final client = createIoHttpClient(
        const IoAdapterConfig(
          maxConnectionsPerHost: 2,
          idleTimeout: Duration(seconds: 9),
        ),
        trustAny: false,
      );

      expect(client.idleTimeout, const Duration(seconds: 9));
      expect(client.maxConnectionsPerHost, 2);
      client.close(force: true);
    });

    test('opens one connection at a time when the limit is 1', () async {
      final origin = await _Server.http();
      addTearDown(origin.close);
      origin.gate = Completer<void>();
      final client = _Client(
        const HttpClientConfig(
          ioAdapter: IoAdapterConfig(maxConnectionsPerHost: 1),
        ),
      );
      final url = 'http://127.0.0.1:${origin.port}/me';

      final first = _get(client, url);
      final second = _get(client, url);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(origin.requests, hasLength(1));
      expect(origin.server.connectionsInfo().total, 1);
      origin.gate!.complete();
      expect((await first).statusCode, 200);
      expect((await second).statusCode, 200);
      expect(origin.requests, hasLength(2));
      client.dispose();
    });
  });

  group('diagnostics', () {
    test('warn when the connection limit is below a concurrency limit', () {
      const config = HttpClientConfig(
        concurrency: ConcurrencyConfig(perHost: 4, hosts: {'a.test': 8}),
        ioAdapter: IoAdapterConfig(maxConnectionsPerHost: 2),
      );

      const message =
          '[ioAdapter] maxConnectionsPerHost 2 is below the concurrency limit '
          '8: requests past 2 wait inside HttpClient and count toward '
          'connectTimeout';

      expect(adapterDiagnostics(config, adapterBuilt: false), [message]);
    });

    test('stay quiet when the connection limit covers concurrency', () {
      const config = HttpClientConfig(
        concurrency: ConcurrencyConfig(perHost: 4),
        ioAdapter: IoAdapterConfig(maxConnectionsPerHost: 4),
      );

      expect(adapterDiagnostics(config, adapterBuilt: true), isEmpty);
    });

    test('name the debug switch and a host with one pin', () {
      final config = HttpClientConfig(ioAdapter: pinned({localhostPin}));

      const trusted =
          '[ioAdapter] debugTrustAnyCertificate is in effect: every '
          'certificate chain is trusted';

      expect(adapterDiagnostics(config, adapterBuilt: true), [
        trusted,
        '[ioAdapter] localhost has one pin: add a backup pin',
      ]);
      expect(adapterDiagnostics(config, adapterBuilt: false), isEmpty);
    });

    test('print through the log box when configure builds', () {
      final lines = <String>[];
      final client = _Client(
        HttpClientConfig(
          log: LogConfig(logPrint: (line) => lines.add('$line')),
          concurrency: const ConcurrencyConfig(perHost: 4),
          ioAdapter: const IoAdapterConfig(maxConnectionsPerHost: 2),
        ),
      );
      expect(
        lines.where((line) => line.startsWith('[ioAdapter]')),
        hasLength(1),
      );

      client.configure(
        client.currentConfig.copyWith(
          concurrency: const ConcurrencyConfig(perHost: 6),
        ),
      );
      expect(
        lines.where((line) => line.startsWith('[ioAdapter]')),
        hasLength(2),
      );

      client.configure(
        client.currentConfig.copyWith(baseUrl: 'https://x.test'),
      );
      expect(
        lines.where((line) => line.startsWith('[ioAdapter]')),
        hasLength(2),
      );
      client.dispose();
    });
  });
}
```

<!-- file: dart_falconnect/test/engine/https/adapter/adapter_swap_test.dart -->
```dart
@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dart_falconnect/src/engine/https/adapter/platform_adapter_io.dart';
import 'package:test/test.dart';

/// A loopback HTTP server that records each request's path and answers
/// once [gate] completes.
class _Server {
  new _(this.server) {
    server.listen((request) async {
      paths.add(request.uri.path);
      arrived.add(null);
      await gate?.future;
      request.response.write('{"ok":true}');
      await request.response.close();
    });
  }

  static Future<_Server> start() async =>
      _Server._(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));

  final HttpServer server;
  final List<String> paths = [];
  final StreamController<void> arrived = StreamController<void>.broadcast();
  Completer<void>? gate;

  String url(String path) => 'http://127.0.0.1:${server.port}$path';

  Future<void> close() => server.close(force: true);
}

/// An adapter the app set itself; records whether it was closed.
class _AppAdapter implements HttpClientAdapter {
  int closes = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString('{"app":true}', 200);

  @override
  void close({bool force = false}) => closes++;
}

class _Client extends BaseHttpClient {
  new(Dio dio, [HttpClientConfig config = const HttpClientConfig()])
    : super(dio: dio, config: config);
}

Future<void> _expectClosed(HttpClientAdapter adapter) => expectLater(
  adapter.fetch(RequestOptions(path: 'http://127.0.0.1:9/'), null, null),
  throwsStateError,
);

void main() {
  late _Server origin;

  setUp(() async => origin = await _Server.start());
  tearDown(() => origin.close());

  test('a box replaces the app adapter; null restores it unclosed', () {
    final app = _AppAdapter();
    final client = _Client(
      Dio()..httpClientAdapter = app,
      const HttpClientConfig(ioAdapter: IoAdapterConfig()),
    );
    expect(client.dio.httpClientAdapter, isA<PinningIoAdapter>());

    client.configure(const HttpClientConfig());
    expect(client.dio.httpClientAdapter, same(app));
    expect(app.closes, 0);
  });

  test('an equal box keeps the adapter', () {
    final client = _Client(
      Dio(),
      const HttpClientConfig(ioAdapter: IoAdapterConfig(proxy: 'p.test:1')),
    );
    final built = client.dio.httpClientAdapter;

    client.configure(
      const HttpClientConfig(
        baseUrl: 'https://other.test',
        ioAdapter: IoAdapterConfig(proxy: 'p.test:1'),
      ),
    );

    expect(client.dio.httpClientAdapter, same(built));
  });

  test('a webAdapter box leaves the dart:io adapter alone', () {
    final app = _AppAdapter();
    final client = _Client(
      Dio()..httpClientAdapter = app,
      const HttpClientConfig(
        webAdapter: WebAdapterConfig(withCredentials: true),
      ),
    );

    expect(client.dio.httpClientAdapter, same(app));
  });

  test('a changed box lets a running request finish, then closes', () async {
    final client = _Client(
      Dio(),
      const HttpClientConfig(ioAdapter: IoAdapterConfig()),
    );
    final old = client.dio.httpClientAdapter;
    origin.gate = Completer<void>();

    final running = client.dio.get<Object?>(origin.url('/running'));
    await origin.arrived.stream.first;
    client.configure(
      const HttpClientConfig(
        ioAdapter: IoAdapterConfig(idleTimeout: Duration(seconds: 1)),
      ),
    );
    origin.gate!.complete();

    expect((await running).statusCode, 200);
    expect(client.dio.httpClientAdapter, isNot(same(old)));
    await _expectClosed(old);
    client.dispose();
  });

  test('a request waiting in a limiter goes through the new adapter', () async {
    final proxy = await _Server.start();
    addTearDown(proxy.close);
    const concurrency = ConcurrencyConfig(global: 1);
    final client = _Client(
      Dio(),
      const HttpClientConfig(
        concurrency: concurrency,
        ioAdapter: IoAdapterConfig(),
      ),
    );
    origin.gate = Completer<void>();

    final first = client.dio.get<Object?>(origin.url('/first'));
    await origin.arrived.stream.first;
    final second = client.dio.get<Object?>(origin.url('/second'));
    client.configure(
      HttpClientConfig(
        concurrency: concurrency,
        ioAdapter: IoAdapterConfig(proxy: '127.0.0.1:${proxy.server.port}'),
      ),
    );
    origin.gate!.complete();

    expect((await first).statusCode, 200);
    expect((await second).statusCode, 200);
    expect(origin.paths, ['/first']);
    expect(proxy.paths, ['/second']);
    client.dispose();
  });

  test('dispose closes the built adapter and restores the app one', () async {
    final app = _AppAdapter();
    final client = _Client(
      Dio()..httpClientAdapter = app,
      const HttpClientConfig(ioAdapter: IoAdapterConfig()),
    );
    final built = client.dio.httpClientAdapter;

    client.dispose();

    expect(client.dio.httpClientAdapter, same(app));
    expect(app.closes, 0);
    await _expectClosed(built);

    client.configure(client.currentConfig);
    expect(client.dio.httpClientAdapter, isA<PinningIoAdapter>());
    expect(client.dio.httpClientAdapter, isNot(same(built)));
    client.dispose();
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `dart test test/engine/https/adapter/io_adapter_test.dart test/engine/https/adapter/adapter_swap_test.dart`
Expected: FAIL to load, with `Error when reading 'lib/src/engine/https/adapter/platform_adapter_io.dart': No such file or directory`.

- [ ] **Step 3: Add platform selection**

<!-- file: dart_falconnect/lib/src/engine/https/adapter/platform_adapter.dart -->
```dart
/// Builds the platform's HTTP adapter from the box of `HttpClientConfig`
/// that the platform reads: `ioAdapter` on dart:io, `webAdapter` on the
/// web, and none elsewhere.
library;

export 'platform_adapter_stub.dart'
    if (dart.library.io) 'platform_adapter_io.dart'
    if (dart.library.js_interop) 'platform_adapter_web.dart';
```

<!-- file: dart_falconnect/lib/src/engine/https/adapter/platform_adapter_stub.dart -->
```dart
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
```

<!-- file: dart_falconnect/lib/src/engine/https/adapter/platform_adapter_web.dart -->
```dart
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
```

- [ ] **Step 4: Add the dart:io adapter**

The connector runs TLS itself for a pinned host and checks the leaf before it hands the socket to `HttpClient`, so no request byte leaves on a mismatch. Every other connection opens as `HttpClient` would open it.

<!-- file: dart_falconnect/lib/src/engine/https/adapter/platform_adapter_io.dart -->
```dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_falconnect/engine/https/certificate_pinning_exception.dart';
import 'package:dart_falconnect/engine/https/config/http_client_config.dart';
import 'package:dart_falconnect/engine/https/config/io_adapter_config.dart';
import 'package:dart_falconnect/src/engine/https/adapter/spki.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// The box dart:io reads from [config].
Object? platformAdapterBox(HttpClientConfig config) => config.ioAdapter;

/// An adapter built from [box], an [IoAdapterConfig].
HttpClientAdapter buildPlatformAdapter(Object box) => PinningIoAdapter(
  box as IoAdapterConfig,
  trustAny: trustsAnyCertificate(box, assertionsEnabled: _assertionsEnabled),
);

/// Diagnostics about [config]'s `ioAdapter` box. All of them when
/// [adapterBuilt], else only the connection-limit one.
List<String> adapterDiagnostics(
  HttpClientConfig config, {
  required bool adapterBuilt,
}) {
  final box = config.ioAdapter;
  if (box == null) return const [];
  final messages = <String>[];
  final max = box.maxConnectionsPerHost;
  final concurrency = config.concurrency;
  if (max != null && concurrency != null) {
    final limits = [
      concurrency.perHost,
      ...concurrency.hosts.values,
    ].whereType<int>().where((limit) => limit > max);
    if (limits.isNotEmpty) {
      final highest = limits.reduce((a, b) => a > b ? a : b);
      messages.add(
        '[ioAdapter] maxConnectionsPerHost $max is below the concurrency '
        'limit $highest: requests past $max wait inside HttpClient and '
        'count toward connectTimeout',
      );
    }
  }
  if (!adapterBuilt) return messages;
  if (trustsAnyCertificate(box, assertionsEnabled: _assertionsEnabled)) {
    messages.add(
      '[ioAdapter] debugTrustAnyCertificate is in effect: every '
      'certificate chain is trusted',
    );
  }
  for (final MapEntry(key: host, value: pins) in box.pins.entries) {
    if (pins.length == 1) {
      messages.add('[ioAdapter] $host has one pin: add a backup pin');
    }
  }
  return messages;
}

/// Whether [box] trusts every certificate chain: only when its switch is
/// on and [assertionsEnabled], so a release build never does.
bool trustsAnyCertificate(
  IoAdapterConfig box, {
  required bool assertionsEnabled,
}) => box.debugTrustAnyCertificate && assertionsEnabled;

bool get _assertionsEnabled {
  var enabled = false;
  assert(enabled = true, 'assert runs only when assertions are enabled');
  return enabled;
}

/// A new `HttpClient` configured by [box].
HttpClient createIoHttpClient(IoAdapterConfig box, {required bool trustAny}) {
  final pins = _canonicalPins(box.pins);
  final client = HttpClient()
    ..idleTimeout = box.idleTimeout
    ..maxConnectionsPerHost = box.maxConnectionsPerHost;
  final proxy = box.proxy;
  if (proxy != null) {
    // A pinned host gets no DIRECT entry, so it fails instead of going
    // around the proxy unseen.
    client.findProxy = (uri) => pins.containsKey(uri.host.toLowerCase())
        ? 'PROXY $proxy'
        : 'PROXY $proxy; DIRECT';
  }
  if (trustAny) {
    client.badCertificateCallback = (certificate, host, port) => true;
  }
  if (pins.isNotEmpty) {
    client.connectionFactory = _PinningConnector(
      pins,
      trustAny: trustAny,
    ).connect;
  }
  return client;
}

/// [pins] with lowercase hosts and canonical pins; hosts that differ only
/// in case share one set.
Map<String, Set<String>> _canonicalPins(Map<String, Set<String>> pins) {
  final canonical = <String, Set<String>>{};
  for (final MapEntry(key: host, value: hostPins) in pins.entries) {
    canonical
        .putIfAbsent(host.toLowerCase(), () => {})
        .addAll(hostPins.map((pin) => canonicalPin(pin) ?? pin));
  }
  return canonical;
}

/// Opens every connection of a pinned `HttpClient`, and checks the leaf
/// certificate of a pinned host before `HttpClient` writes the request.
class _PinningConnector {
  new(this.pins, {required this.trustAny});

  final Map<String, Set<String>> pins;
  final bool trustAny;

  bool Function(X509Certificate certificate)? get _onBadCertificate =>
      trustAny ? (certificate) => true : null;

  Future<ConnectionTask<Socket>> connect(
    Uri uri,
    String? proxyHost,
    int? proxyPort,
  ) async {
    final host = uri.host.toLowerCase();
    final expected = pins[host];
    final secure = uri.isScheme('https');
    if (expected == null) {
      if (proxyHost != null) {
        // HttpClient runs the CONNECT tunnel and its TLS itself.
        return Socket.startConnect(proxyHost, proxyPort!);
      }
      return secure
          ? SecureSocket.startConnect(
              uri.host,
              uri.port,
              onBadCertificate: _onBadCertificate,
            )
          : Socket.startConnect(uri.host, uri.port);
    }
    if (proxyHost != null || !secure) {
      throw CertificatePinningException(
        host: host,
        failure: proxyHost != null ? PinFailure.proxied : PinFailure.plainHttp,
        expected: expected,
      );
    }
    final task = await SecureSocket.startConnect(
      uri.host,
      uri.port,
      onBadCertificate: _onBadCertificate,
    );
    return ConnectionTask.fromSocket(
      task.socket.then((socket) => _check(socket, host, expected)),
      task.cancel,
    );
  }

  /// [socket] when its leaf certificate matches one of [expected];
  /// otherwise destroys it, before any request byte is written, and
  /// throws [CertificatePinningException].
  SecureSocket _check(SecureSocket socket, String host, Set<String> expected) {
    final certificate = socket.peerCertificate;
    String? presented;
    if (certificate != null) {
      try {
        presented = spkiPin(certificate.der);
      } on FormatException {
        presented = null;
      }
    }
    if (presented != null && expected.contains(presented)) return socket;
    socket.destroy();
    throw CertificatePinningException(
      host: host,
      failure: presented == null
          ? PinFailure.unreadableCertificate
          : PinFailure.mismatch,
      expected: expected,
      presented: presented,
    );
  }
}

/// dio's `IOHttpClientAdapter` on an `HttpClient` from
/// [createIoHttpClient], reporting a pin failure as a `badCertificate`
/// `DioException`, which `RetryInterceptor` never retries.
class PinningIoAdapter implements HttpClientAdapter {
  /// Creates an adapter configured by [box].
  new(IoAdapterConfig box, {required bool trustAny})
    : _inner = IOHttpClientAdapter(
        createHttpClient: () => createIoHttpClient(box, trustAny: trustAny),
      );

  final IOHttpClientAdapter _inner;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    try {
      return await _inner.fetch(options, requestStream, cancelFuture);
    } on CertificatePinningException catch (error, stackTrace) {
      throw DioException.badCertificate(
        requestOptions: options,
        error: error,
      ).copyWith(stackTrace: stackTrace);
    }
  }

  @override
  void close({bool force = false}) => _inner.close(force: force);
}
```

- [ ] **Step 5: Build, swap, and report the adapter in `BaseHttpClient`**

<!-- replace: dart_falconnect/lib/engine/https/http_client.dart -->
```dart
import 'package:dart_falconnect/lib.dart';
```

with:

<!-- with -->
```dart
import 'package:dart_falconnect/lib.dart';
import 'package:dart_falconnect/src/engine/https/adapter/platform_adapter.dart';
```

<!-- replace: dart_falconnect/lib/engine/https/http_client.dart -->
```dart
/// whose box is unchanged are kept, with their state.
///
/// A subclass passes its configuration to the super constructor.
```

with:

<!-- with -->
```dart
/// whose box is unchanged are kept, with their state.
///
/// The config's `ioAdapter` box, on dart:io, or `webAdapter` box, on the
/// web, replaces [dio]'s adapter while it is set; a null box leaves the
/// adapter alone, and a box that returns to null restores the adapter
/// [dio] had before. [configure] closes an adapter it replaces with
/// `force: false`, so requests already running on it finish, and never
/// closes an adapter it did not build.
///
/// A subclass passes its configuration to the super constructor.
```

<!-- replace: dart_falconnect/lib/engine/https/http_client.dart -->
```dart
  /// those are replaced; the adapter and every other option stay.
```

with:

<!-- with -->
```dart
  /// those are replaced; every other option stays, and so does the adapter
  /// unless the platform's adapter box is set.
```

<!-- replace: dart_falconnect/lib/engine/https/http_client.dart -->
```dart
  RetryInterceptor? _retry;

```

with:

<!-- with -->
```dart
  RetryInterceptor? _retry;
  HttpClientAdapter? _builtAdapter;
  HttpClientAdapter? _originalAdapter;

```

<!-- replace: dart_falconnect/lib/engine/https/http_client.dart -->
```dart
      (box) => RetryInterceptor(config: box, dio: _dio, logPrint: _diagnostic),
    );

```

with:

<!-- with -->
```dart
      (box) => RetryInterceptor(config: box, dio: _dio, logPrint: _diagnostic),
    );
    final adapterBox = platformAdapterBox(config);
    final adapterBuilt =
        adapterBox != null &&
        (_builtAdapter == null ||
            previous == null ||
            platformAdapterBox(previous) != adapterBox);
    final adapter = adapterBuilt
        ? buildPlatformAdapter(adapterBox)
        : adapterBox == null
        ? null
        : _builtAdapter;

```

<!-- replace: dart_falconnect/lib/engine/https/http_client.dart -->
```dart
        config.exceptionHandler ?? _defaultExceptionHandler,
      ]);
    _config = config;
```

with:

<!-- with -->
```dart
        config.exceptionHandler ?? _defaultExceptionHandler,
      ]);
    _swapAdapter(adapter);
    _config = config;
```

<!-- replace: dart_falconnect/lib/engine/https/http_client.dart -->
```dart
    _retry = retry;
  }

```

with:

<!-- with -->
```dart
    _retry = retry;
    if (adapterBox != null &&
        (adapterBuilt || previous?.concurrency != config.concurrency)) {
      adapterDiagnostics(
        config,
        adapterBuilt: adapterBuilt,
      ).forEach(_diagnostic);
    }
  }

```

<!-- replace: dart_falconnect/lib/engine/https/http_client.dart -->
```dart
  /// Disposes the stateful interceptors of the current configuration.
  ///
  /// Needed at the end of a test or a CLI; a Flutter app never calls it.
  /// A later [configure] builds new limiters instead of keeping these.
```

with:

<!-- with -->
```dart
  /// Disposes the stateful interceptors of the current configuration, and
  /// closes the adapter this client built with `force: false`, restoring
  /// the adapter [dio] had before.
  ///
  /// Needed at the end of a test or a CLI; a Flutter app never calls it.
  /// A later [configure] builds new limiters and a new adapter instead of
  /// keeping these.
```

<!-- replace: dart_falconnect/lib/engine/https/http_client.dart -->
```dart
    _rateLimit = null;
    _concurrency = null;
  }

```

with:

<!-- with -->
```dart
    _rateLimit = null;
    _concurrency = null;
    _swapAdapter(null);
  }

```

<!-- replace: dart_falconnect/lib/engine/https/http_client.dart -->
```dart
  /// [box], carrying the current cache's memory store when only settings
```

with:

<!-- with -->
```dart
  /// Puts [next] on [dio], or the adapter [dio] had before this client
  /// built one when [next] is null, and closes the adapter this client
  /// built before, letting its running requests finish.
  void _swapAdapter(HttpClientAdapter? next) {
    final built = _builtAdapter;
    if (identical(next, built)) return;
    if (built == null) _originalAdapter = _dio.httpClientAdapter;
    _dio.httpClientAdapter = next ?? _originalAdapter!;
    built?.close();
    _builtAdapter = next;
    if (next == null) _originalAdapter = null;
  }

  /// [box], carrying the current cache's memory store when only settings
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `dart test test/engine/https/adapter/io_adapter_test.dart test/engine/https/adapter/adapter_swap_test.dart`
Expected: PASS, 24 and 6 tests.

- [ ] **Step 7: Run the package suite on the VM and in Chrome, analyze, format, and commit**

```bash
dart test && dart test -p chrome && dart analyze && dart format --set-exit-if-changed .
cd .. && git add dart_falconnect/lib dart_falconnect/test/engine/https/adapter
git commit -m "feat(dart_falconnect): build the platform adapter and pin certificates during the handshake" -- dart_falconnect/lib dart_falconnect/test/engine/https/adapter
```

### Task 4: The web adapter test and the compile gate

**Files:**
- Test: `dart_falconnect/test/engine/https/adapter/web_adapter_test.dart`
- Modify: `dart_falconnect/test/web/compile_smoke.dart`

**Interfaces:**
- Consumes: `BrowserHttpClientAdapter` from `package:dio/browser.dart`; everything from Tasks 2 and 3.
- Produces: no new API.

- [ ] **Step 1: Write the Chrome test**

<!-- file: dart_falconnect/test/engine/https/adapter/web_adapter_test.dart -->
```dart
@TestOn('browser')
library;

import 'package:dart_falconnect/dart_falconnect.dart';
import 'package:dio/browser.dart';
import 'package:test/test.dart';

import '../../../fixtures/localhost_certificate.dart';

class _Client extends BaseHttpClient {
  new(Dio dio, HttpClientConfig config) : super(dio: dio, config: config);
}

void main() {
  test('webAdapter sets withCredentials on a browser adapter', () {
    final client = _Client(
      Dio(),
      const HttpClientConfig(
        webAdapter: WebAdapterConfig(withCredentials: true),
      ),
    );

    expect(
      client.dio.httpClientAdapter,
      isA<BrowserHttpClientAdapter>().having(
        (a) => a.withCredentials,
        'withCredentials',
        isTrue,
      ),
    );
  });

  test('an ioAdapter box leaves the browser adapter alone', () {
    final dio = Dio();
    final original = dio.httpClientAdapter;
    _Client(
      dio,
      const HttpClientConfig(
        ioAdapter: IoAdapterConfig(
          maxConnectionsPerHost: 2,
          proxy: 'localhost:9090',
          pins: {
            'api.example.com': {localhostPin},
          },
          debugTrustAnyCertificate: true,
        ),
      ),
    );

    expect(dio.httpClientAdapter, same(original));
  });

  test('a webAdapter box that returns to null restores the adapter', () {
    final dio = Dio();
    final original = dio.httpClientAdapter;
    final client = _Client(
      dio,
      const HttpClientConfig(
        webAdapter: WebAdapterConfig(withCredentials: true),
      ),
    );
    expect(dio.httpClientAdapter, isNot(same(original)));

    client.configure(const HttpClientConfig());
    expect(dio.httpClientAdapter, same(original));
  });
}
```

- [ ] **Step 2: Run it in Chrome under both compilers**

Run: `dart test -p chrome test/engine/https/adapter/web_adapter_test.dart && dart test -p chrome -c dart2wasm test/engine/https/adapter/web_adapter_test.dart`
Expected: PASS, 3 tests under each. The code exists since Task 3, so this test passes at once; mutate `platform_adapter_web.dart` to pass `withCredentials: false` and confirm "webAdapter sets withCredentials on a browser adapter" fails, then restore it.

- [ ] **Step 3: Put both boxes and the exception in the compile gate**

<!-- replace: dart_falconnect/test/web/compile_smoke.dart -->
```dart
  _sink(const HttpClientConfig(log: LogConfig.json()));
  _sink(DefaultNetworkExceptionHandlerInterceptor());
```

with:

<!-- with -->
```dart
  _sink(const HttpClientConfig(log: LogConfig.json()));
  _sink(
    StubHttpClient(dio: dio)..configure(
      const HttpClientConfig(
        ioAdapter: IoAdapterConfig(
          maxConnectionsPerHost: 4,
          proxy: 'localhost:9090',
          pins: {
            'example.test': {
              'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
            },
          },
          debugTrustAnyCertificate: true,
        ),
        webAdapter: WebAdapterConfig(withCredentials: true),
      ),
    ),
  );
  _sink(
    const CertificatePinningException(
      host: 'example.test',
      failure: PinFailure.mismatch,
      expected: {},
    ),
  );
  _sink(DefaultNetworkExceptionHandlerInterceptor());
```

- [ ] **Step 4: Run the compile gate**

Run from the worktree root: `melos run test:compile`
Expected: SUCCESS; `dart compile js`, `dart compile wasm`, and `dart compile exe` each exit 0.

- [ ] **Step 5: Analyze, format, and commit**

```bash
cd dart_falconnect && dart analyze && dart format --set-exit-if-changed . && cd ..
git add dart_falconnect/test/engine/https/adapter/web_adapter_test.dart dart_falconnect/test/web/compile_smoke.dart
git commit -m "test(dart_falconnect): cover the web adapter and compile both adapter boxes" -- dart_falconnect/test/engine/https/adapter/web_adapter_test.dart dart_falconnect/test/web/compile_smoke.dart
```

### Task 5: Consumer skill, package docs, and final gates

**Files:**
- Modify: `skills/dart-falconx-package/SKILL.md`, `skills/dart-falconx-package/references/http.md`, `dart_falconnect/CLAUDE.md`

**Interfaces:**
- Consumes: the public API of Tasks 2 and 3.
- Produces: no code.

- [ ] **Step 1: Add the transport row and rule to `SKILL.md`**

<!-- replace: skills/dart-falconx-package/SKILL.md -->
```markdown
| Client configuration                            | `HttpClientConfig` boxes (`LogConfig`, or `LogConfig.json` for a server), `configure`, `currentConfig`, `setupBaseUrl`                                                                                                                                                                                                                                                                                     | dart_falconnect             | `references/http.md`        |
```

with:

<!-- with -->
```markdown
| Client configuration                            | `HttpClientConfig` boxes (`LogConfig`, or `LogConfig.json` for a server), `configure`, `currentConfig`, `setupBaseUrl`                                                                                                                                                                                                                                                                                     | dart_falconnect             | `references/http.md`        |
| Transport: pool, proxy, pins, web credentials   | `HttpClientConfig(ioAdapter: IoAdapterConfig(...), webAdapter: WebAdapterConfig(...))`; a pin failure is a `CertificatePinningException`                                                                                                                                                                                                                                                                   | dart_falconnect             | `references/http.md`        |
```

<!-- replace: skills/dart-falconx-package/SKILL.md -->
```markdown
- Never `import 'dart:io'`; the packages compile to web. Use `package:universal_io/io.dart`, added to your own pubspec (it is not re-exported).
```

with:

<!-- with -->
```markdown
- Never `import 'dart:io'`; the packages compile to web. Use `package:universal_io/io.dart`, added to your own pubspec (it is not re-exported).
- Never build an `IOHttpClientAdapter` or `BrowserHttpClientAdapter` yourself for a connection limit, idle timeout, proxy, certificate pins, or `withCredentials`: set `ioAdapter` and `webAdapter`, which compile on every platform.
```

- [ ] **Step 2: Document the boxes in `references/http.md`**

Add both boxes to the box table:

<!-- replace: skills/dart-falconx-package/references/http.md -->
```markdown
| `AuthConfig`                                                     | the token step of `RequestStampInterceptor`, plus `TokenRefreshInterceptor`                        | `Authorization: Bearer <token>`                                                                                                                                                      |
```

with:

<!-- with -->
```markdown
| `AuthConfig`                                                     | the token step of `RequestStampInterceptor`, plus `TokenRefreshInterceptor`                        | `Authorization: Bearer <token>`                                                                                                                                                      |
| `IoAdapterConfig`                                                | a dart:io adapter in place of `dio.httpClientAdapter` (see "Transport options"); the web ignores it | no connection limit, 3 s idle timeout, environment proxy, no pins                                                                                                                    |
| `WebAdapterConfig`                                               | a browser adapter in place of `dio.httpClientAdapter`; dart:io ignores it                          | `withCredentials: false`                                                                                                                                                             |
```

Say that `configure` leaves the adapter alone without a box:

<!-- replace: skills/dart-falconx-package/references/http.md -->
```markdown
- `configure` owns `baseUrl`, the three timeouts, `contentType`, redirects, `validateStatus` (null means dio's default, 2xx only), and the header keys of `headers` and `userAgent`. Other `dio.options` fields, and headers you set by hand, survive it.
```

with:

<!-- with -->
```markdown
- `configure` owns `baseUrl`, the three timeouts, `contentType`, redirects, `validateStatus` (null means dio's default, 2xx only), and the header keys of `headers` and `userAgent`. Other `dio.options` fields, and headers you set by hand, survive it. So does `dio.httpClientAdapter`, unless the platform's adapter box is set.
```

Add the "Transport options" section before "Custom client":

<!-- replace: skills/dart-falconx-package/references/http.md -->
````markdown
## Custom client: subclass `BaseHttpClient`
````

with:

<!-- with -->
````markdown
## Transport options

Two boxes set what the platform's HTTP adapter does. Both fit in one config: dart:io platforms (Android, iOS, macOS, Windows, Linux, servers) read only `ioAdapter`, and the web reads only `webAdapter`, so the app never imports `dart:io` or `package:dio/io.dart`.

```dart
DefaultHttpClient.instance.configure(
  HttpClientConfig(
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
  ),
);
```

| `IoAdapterConfig` field | Effect | Default |
|---|---|---|
| `maxConnectionsPerHost` | most open connections to one host; requests past it wait inside `HttpClient`, and the wait counts toward `connectTimeout` | no limit |
| `idleTimeout` | how long an idle connection stays open for reuse | 3 s, as dio uses |
| `proxy` | `host:port` for every request; a request that cannot reach the proxy goes direct, except to a pinned host | the `https_proxy`, `http_proxy`, and `no_proxy` environment variables |
| `pins` | certificate pins per host, `sha256/<base64>` of the leaf's SubjectPublicKeyInfo | none |
| `debugTrustAnyCertificate` | trusts every certificate chain while assertions are enabled (Flutter debug, `dart test`, `dart run --enable-asserts`); release builds and `dart compile exe` ignore it | off |

**Certificate pinning**

- The leaf certificate is checked during the TLS handshake, before any byte of the request, token included, leaves. A mismatch fails with a `DioException` of type `badCertificate` whose `error` is a `CertificatePinningException`; `RetryInterceptor` never retries it.
- `CertificatePinningException.failure` says why: `mismatch`, `proxied` (a pinned host through any proxy, the environment's included, since no pin can be checked there), `plainHttp` (a pinned host over `http`), or `unreadableCertificate`. On a mismatch, `presented` holds the pin the server sent.
- Get a host's pin:

  ```bash
  openssl s_client -connect api.example.com:443 -servername api.example.com </dev/null \
    | openssl x509 -pubkey -noout \
    | openssl pkey -pubin -outform der \
    | openssl dgst -sha256 -binary | base64
  ```

- The pin follows the server's key, not its certificate. It survives a renewal only when the server keeps its key: `certbot` makes a new key on every renewal unless you pass `--reuse-key`. Ship a backup pin for the next key in every release, or installed apps stop connecting when the key changes.
- Only the leaf can be pinned; Dart exposes no certificate chain. Hosts match exactly, ignoring case, with no wildcards.
- `configure` throws `ArgumentError` on a malformed pin or `proxy`, on every platform, the web included.

**Debugging with Proxyman on Android**

Set `proxy` to the Mac's address and `debugTrustAnyCertificate: true`, and drop the pins in debug builds, as the example above does: pins still apply with the switch on, so a pinned host rejects Proxyman's certificate. Hosts without a pin show in Proxyman, and fall back to direct when Proxyman is closed.

**Swapping and ownership**

- A box builds a new adapter when it changes; an equal box keeps the adapter. The replaced adapter closes with `force: false`, so requests already running on it finish. Requests still waiting in a limiter, and retries, go out through the new adapter.
- While a box is set, the client owns `dio.httpClientAdapter`. A box that returns to null, and `dispose()`, put back the adapter `dio` had before, which the client never closes.
- `withCredentials` on the web makes cross-site requests send cookies and authorization headers; a request's `extra['withCredentials']` overrides it.

## Custom client: subclass `BaseHttpClient`
````

Correct the web connection note, and add the server rule:

<!-- replace: skills/dart-falconx-package/references/http.md -->
```markdown
- Chrome opens at most 6 connections per host over HTTP/1.1, so a `perHost` above 6 changes nothing on the web.
```

with:

<!-- with -->
```markdown
- Chrome opens at most 6 connections per host over HTTP/1.1 and queues the rest itself. That queue time counts toward `connectTimeout`, so keep `perHost` at 6 or less on the web, and the queue stays in `ConcurrencyLimitInterceptor`, where you can see and cancel it.
```

<!-- replace: skills/dart-falconx-package/references/http.md -->
```markdown
- Build the client once per process (see "Refill timers and `dispose()`").
```

with:

<!-- with -->
```markdown
- Build the client once per process (see "Refill timers and `dispose()`").
- Keep `IoAdapterConfig.maxConnectionsPerHost` at or above every per-host limit of `ConcurrencyConfig`; the client prints a diagnostic when it is lower.
```

- [ ] **Step 3: Update `dart_falconnect/CLAUDE.md`**

<!-- replace: dart_falconnect/CLAUDE.md -->
```markdown
A `requestId` box, a `headerProvider` function, or an `auth` box builds `RequestStampInterceptor`; an `auth` box also builds an `AuthSession`, kept while the box is equal, and `TokenRefreshInterceptor`.
```

with:

<!-- with -->
```markdown
A `requestId` box, a `headerProvider` function, or an `auth` box builds `RequestStampInterceptor`; an `auth` box also builds an `AuthSession`, kept while the box is equal, and `TokenRefreshInterceptor`. An `ioAdapter` box on dart:io, or a `webAdapter` box on the web, replaces `dio.httpClientAdapter`; `configure` closes an adapter it replaces with `force: false`, never closes one it did not build, and restores the original when the box returns to null.
```

<!-- replace: dart_falconnect/CLAUDE.md -->
```markdown
the auth bookkeeping in `extra` in `lib/src/engine/https/interceptors/auth_extra.dart`, and `watchCancel` in `lib/src/engine/https/cancel_watch.dart`.
```

with:

<!-- with -->
```markdown
the auth bookkeeping in `extra` in `lib/src/engine/https/interceptors/auth_extra.dart`, `watchCancel` in `lib/src/engine/https/cancel_watch.dart`, and the platform adapters, the pinning connector, and the SPKI reader in `lib/src/engine/https/adapter/`.
```

<!-- replace: dart_falconnect/CLAUDE.md -->
```markdown
- Leave Dio's `httpClientAdapter` on its auto factory so web resolves `BrowserHttpClientAdapter`; never import `package:dio/io.dart` or set `IOHttpClientAdapter`.
```

with:

<!-- with -->
```markdown
- Import `package:dio/io.dart` only in `lib/src/engine/https/adapter/platform_adapter_io.dart` and `package:dio/browser.dart` only in `platform_adapter_web.dart`, both behind the conditional export of `platform_adapter.dart`; everywhere else, leave `httpClientAdapter` to `configure`.
- `dio_web_adapter` counts the time a request waits in the browser's own connection queue toward `connectTimeout`.
```

- [ ] **Step 4: Run every gate from the worktree root**

```bash
melos run analyze
melos run format
melos run build_runner:check
melos run test
melos run test:platforms
```

Expected: each prints SUCCESS. VM: falconnect 422 (1 skip), faltool 771, falmodel 71, falconx 1. Chrome: falconnect 399 under dart2js and under dart2wasm.

- [ ] **Step 5: Check the skill against the code**

Confirm by reading that every public name in the "Transport options" section exists in `dart_falconnect/lib/`: `IoAdapterConfig`, its five fields, `WebAdapterConfig.withCredentials`, `CertificatePinningException` and its four fields, and the four `PinFailure` values.

- [ ] **Step 6: Commit**

```bash
git add skills/dart-falconx-package/SKILL.md skills/dart-falconx-package/references/http.md dart_falconnect/CLAUDE.md
git commit -m "docs: document the ioAdapter and webAdapter transport options" -- skills/dart-falconx-package/SKILL.md skills/dart-falconx-package/references/http.md dart_falconnect/CLAUDE.md
```

- [ ] **Step 7: Hand over the device check**

The owner runs spec section 11's device check before release: on one iOS and one Android device, a build with the real host's pins succeeds, a build with one wrong pin fails with `PinFailure.mismatch`, and a debug build with the switch and `proxy` set to Proxyman shows traffic for a host without pins. Do not merge, push, or tag.
