import 'dart:convert';
import 'package:crypto/crypto.dart';

class AegisQrEngine {
  static const String _sessionId = 'sess-nokhba-today';
  static const String _secret = 'kashkool-local-session-hmac-secret-2026';
  static const int windowSeconds = 30;

  static int secondsRemaining(DateTime now) {
    final epoch = now.millisecondsSinceEpoch ~/ 1000;
    return windowSeconds - (epoch % windowSeconds);
  }

  static String studentTokenAt(String studentId, DateTime now) {
    final slot = (now.millisecondsSinceEpoch ~/ 1000) ~/ windowSeconds;
    final raw = '$_sessionId|$studentId|$slot';
    final sig = Hmac(sha256, utf8.encode(_secret))
        .convert(utf8.encode(raw))
        .toString()
        .substring(0, 12);
    return 'KSH|$studentId|$slot|$sig';
  }
}
