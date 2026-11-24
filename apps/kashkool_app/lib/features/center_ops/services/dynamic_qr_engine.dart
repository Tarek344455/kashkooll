import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Rotating, verifiable attendance token for the secretary desk.
///
/// The token is `slot.digest` where `slot` is the 5-second window index and
/// `digest` is a SHA-256 of the session secret, session id and slot. A scanner
/// holding the same session secret can verify a scan offline, and a token is
/// worthless five seconds after it was shown.
class DynamicQrEngine {
  DynamicQrEngine({
    required this.sessionId,
    required this.sessionSecret,
    this.rotation = const Duration(seconds: 5),
  });

  final String sessionId;
  final String sessionSecret;
  final Duration rotation;

  /// Window index for [at] in UTC, so device time zones cannot shift tokens.
  int slotAt(DateTime at) =>
      at.toUtc().millisecondsSinceEpoch ~/ rotation.inMilliseconds;

  String tokenAt(DateTime at) => _tokenForSlot(slotAt(at));

  String get currentToken => tokenAt(DateTime.now());

  /// Seconds until the visible token rotates.
  int secondsRemaining(DateTime at) {
    final windowMs = rotation.inMilliseconds;
    final elapsed = at.toUtc().millisecondsSinceEpoch % windowMs;
    return ((windowMs - elapsed) / 1000).ceil();
  }

  /// Accepts the current window plus [grace] earlier windows, which covers
  /// scan lag and a clock that is a few seconds behind.
  bool verify(String scanned, {DateTime? at, int grace = 1}) {
    final now = at ?? DateTime.now();
    final currentSlot = slotAt(now);
    for (var offset = 0; offset <= grace; offset++) {
      if (scanned == _tokenForSlot(currentSlot - offset)) return true;
    }
    return false;
  }

  String _tokenForSlot(int slot) {
    final digest = sha256.convert(
      utf8.encode('$sessionId|$sessionSecret|$slot'),
    );
    return '$slot.${digest.toString().substring(0, 24)}';
  }
}
