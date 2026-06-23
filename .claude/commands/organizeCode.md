---
argument-hint: [file-path-or-paste-code]
description: Reorganize Kotlin code following project standards
---
# Organize Kotlin/Java Code

Organize and refactor: **$ARGUMENTS**

## Reference
Follow the code organization standards in `@documents/CODE_ORGANIZATION.md`

## Task
Reorganize the code with this section order:
1. Companion Object
2. Public Fields
3. Private Fields
4. Override Android Methods
5. Override Base Methods
6. Private Methods

## Requirements
- Add section markers (`// MARK: [Section Name]`)
- Add Dart document for public/complex methods
- Preserve all functionality
- Output the complete reorganized code