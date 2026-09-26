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
