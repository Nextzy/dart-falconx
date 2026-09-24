# dart_falconx

- `lib/dart_falconx.dart` holds only three `export` lines, one per sibling package; all code lives in the siblings.
- Have consumers import `package:dart_falconx/dart_falconx.dart` and depend on no sibling package directly.
- Add a re-export only when a new sibling package appears; every symbol a sibling package exports reaches consumers with no edit here.
- Keep every `@freezed` or `@JsonSerializable` class in a sibling package; this package declares no generator and no `build.yaml`.
