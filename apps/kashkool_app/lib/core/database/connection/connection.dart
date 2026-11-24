// Platform-aware drift connection factory.
//
// Native (Android/iOS/desktop) opens a real SQLite file through `dart:ffi`;
// the web build opens drift's WASM worker instead. Keeping the two behind a
// conditional export means neither platform sees an import it cannot compile.
export 'native.dart' if (dart.library.js_interop) 'web.dart';
