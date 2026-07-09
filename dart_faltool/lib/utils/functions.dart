import 'package:dart_faltool/lib.dart';

DateTime get nowUtc => DateTime.now().toUtc();

/// Cryptographically secure random number generator shared across utilities.
final Random _secureRandom = Random.secure();

/// Executes [execute] and wraps any thrown exception into a [Result.failure].
///
/// [CommonException] instances are wrapped directly; all other exceptions are
/// converted via `toException()` before wrapping.
Future<Result<T>> runCatching<T>(
  Future<Result<T>> Function() execute,
) async {
  try {
    return await execute();
  } on CommonException catch (e) {
    return Result.failure(e);
  } on Object catch (e) {
    return Result.failure(e.toException());
  }
}

/// Constant-time string comparison to prevent timing side-channel attacks.
///
/// Returns `true` if [a] and [b] are equal, using a bitwise OR accumulator
/// so that the comparison time does not vary with the position of the first
/// differing character.
bool constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var result = 0;
  for (var i = 0; i < a.length; i++) {
    result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return result == 0;
}

/// Introduces a random delay to prevent timing oracle attacks.
///
/// Adds a delay between [minMs] and [maxMs] milliseconds (default 100–300ms)
/// using a cryptographically secure random number generator, making it
/// infeasible for attackers to infer server-side branching from response times.
Future<void> randomDelay({
  int minMs = 100,
  int maxMs = 300,
}) {
  assert(minMs >= 0, 'minMs must be non-negative');
  assert(maxMs > minMs, 'maxMs must be greater than minMs');
  return Future<void>.delayed(
    Duration(milliseconds: minMs + _secureRandom.nextInt(maxMs - minMs)),
  );
}
