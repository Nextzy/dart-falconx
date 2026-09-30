import 'package:dart_falmodel/dart_falmodel.dart';
import 'package:test/test.dart';

void main() {
  group('RemoteErrorBody', () {
    test('fromData reads a JSON map', () {
      final body = RemoteErrorBody.fromData(<String, dynamic>{
        'code': 42,
        'message': 'broken',
        'userMessage': 'Try again',
        'developerMessage': 'upstream timeout',
      });

      expect(
        body,
        const RemoteErrorBody(
          code: 42,
          message: 'broken',
          userMessage: 'Try again',
          developerMessage: 'upstream timeout',
        ),
      );
    });

    test('fromData turns any other value into the message', () {
      expect(
        RemoteErrorBody.fromData(404),
        const RemoteErrorBody(message: '404'),
      );
    });

    test('toJson round-trips through fromJson', () {
      const body = RemoteErrorBody(code: 1, message: 'm');

      expect(RemoteErrorBody.fromJson(body.toJson()), body);
    });
  });
}
