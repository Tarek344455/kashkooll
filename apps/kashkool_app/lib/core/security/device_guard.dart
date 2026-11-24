import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Raised when the account is opened on hardware it was not bound to.
class DeviceSecurityException implements Exception {
  const DeviceSecurityException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Hardware device fingerprinting and FLAG_SECURE enforcement.
///
/// The fingerprint is a SHA-256 digest of stable platform identifiers. It is
/// what the backend compares against `students/{uid}.boundDeviceId`, so two
/// different phones can never produce the same value.
class DeviceGuard {
  static const MethodChannel _secureChannel = MethodChannel('kashkool/secure');

  static String? _cachedFingerprint;

  /// Digest of the current hardware. Cheap to call: computed once per run.
  static Future<String> currentFingerprint() async {
    final cached = _cachedFingerprint;
    if (cached != null) return cached;

    if (kIsWeb) {
      throw const DeviceSecurityException(
        'Device binding requires the installed app, not the browser.',
      );
    }

    final plugin = DeviceInfoPlugin();
    final parts = <String>[];

    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      parts.addAll(<String>[
        'android',
        info.id,
        info.board,
        info.brand,
        info.device,
        info.manufacturer,
        info.model,
        info.product,
        info.fingerprint,
        info.isPhysicalDevice.toString(),
      ]);
    } else if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      parts.addAll(<String>[
        'ios',
        info.identifierForVendor ?? '',
        info.model,
        info.utsname.machine,
        info.isPhysicalDevice.toString(),
      ]);
    } else {
      parts.addAll(<String>[
        Platform.operatingSystem,
        Platform.localHostname,
        Platform.operatingSystemVersion,
      ]);
    }

    final digest = sha256.convert(utf8.encode(parts.join('|')));
    _cachedFingerprint = digest.toString();
    return _cachedFingerprint!;
  }

  /// Compares the live hardware against the fingerprint stored on the account.
  static Future<String> verifyHardwareBinding(String storedFingerprint) async {
    final current = await currentFingerprint();
    if (current != storedFingerprint) {
      throw const DeviceSecurityException(
        'This account is locked to another device. Contact your centre.',
      );
    }
    return current;
  }

  /// Enables FLAG_SECURE so screenshots and screen recording are blocked.
  ///
  /// Returns false when the platform has no implementation (desktop/web), so
  /// callers can decide whether to warn instead of assuming protection.
  static Future<bool> enableSecureMode() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final enabled = await _secureChannel.invokeMethod<bool>('enableSecure');
      return enabled ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
