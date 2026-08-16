# CLAUDE.md
# Token Optimization & Execution Rules

## Communication Style
- **No Preamble or Postscript:** Never use greetings, conversational filler, or closing statements (skip "Here is the solution", "Let me know").
- **No Explanations:** Output ONLY code or raw data unless explicitly asked for an explanation.
- **Ultra-Concise:** Keep all responses as short as possible.

## Tool Execution & Efficiency
- **Minimal Tool Calls:** Do not run diagnostic commands, directory lists, or tests unless strictly necessary.
- **Direct Edits:** Edit files directly with minimal required changes rather than rewriting entire files.
- **No Unrequested Tests:** Do not run `flutter test` or build commands after making changes unless explicitly requested.
- **No Re-reading Files:** Do not re-read files that are already present in the prompt context.

## Search & File System Restrictions
- **Ignore Generated & Build Artifacts:** Never search, read, or list files inside `build/`, `.dart_tool/`, `android/`, `ios/`, or `node_modules/`.
- **Targeted Searches Only:** Do not perform broad directory searches (e.g., `grep -r .`). Search strictly within `lib/`.
- **No Directory Trees:** Never print directory trees or full `ls -R` outputs.

## Code Generation
- **No Verbose Comments:** Do not write inline comments or documentation unless requested.
- **Surgical Edits Only:** Apply minimal diffs/replacements. Show/edit only changed code blocks.
- **Quiet Command Flags:** Use quiet/silent flags for commands when available (e.g., `flutter pub get --quiet`).



This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application supporting multiple platforms: iOS, Android, macOS, Windows, Linux, and Web. The project uses Dart 3.13.0+ and is in early development with a basic Material Design starter structure.

## Architecture Notes

Currently, all code lives in lib/main.dart with a simple widget hierarchy:
- `MyApp` (root stateless widget) — Configures MaterialApp theme and navigation
- `MyHomePage` (stateful widget) — Demo home page with counter state

As the app grows:
- Extract widgets into separate files (e.g., lib/screens/home_page.dart)
- Consider organizing by feature (lib/features/counter/, lib/features/settings/)
- Use state management as needed (Provider, Riverpod, GetX, etc.)

## Development Notes

- **Hot Reload** is enabled by default and preserves state — useful for rapid iteration on UI
- **Material Design** is the default theme; colors use ColorScheme.fromSeed() for Material 3 compatibility
- **Platform-specific code** should go in respective platform directories (ios/, android/, etc.) or use conditional imports in Dart
- **Tests** should be added to test/ directory and run regularly during development
