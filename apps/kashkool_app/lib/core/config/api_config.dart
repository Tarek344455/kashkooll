import 'package:flutter/foundation.dart';

/// Central place for every backend address the app talks to.
///
/// The Kashkool Savior gateway runs on the developer workstation, so the
/// address that works depends on where the app runs:
///
/// * Web / desktop  → the gateway is on the same machine (`127.0.0.1`).
/// * Android        → `127.0.0.1` is the phone itself, so the build must be
///                    pointed at the workstation's LAN address.
///
/// Override at build time with:
/// `flutter run --dart-define=KASHKOOL_API_BASE=http://192.168.1.103:4000`
class ApiConfig {
  const ApiConfig._();

  /// Compile-time override, empty when not supplied.
  static const String _override =
      String.fromEnvironment('KASHKOOL_API_BASE');

  /// Optional gateway key for requests that arrive from outside loopback.
  ///
  /// Supplied at build/run time (`--dart-define=KASHKOOL_GATEWAY_KEY=...`) and
  /// never committed to the repository.
  static const String gatewayKey =
      String.fromEnvironment('KASHKOOL_GATEWAY_KEY');

  /// Default workstation address used when no override is supplied.
  ///
  /// Android phones cannot reach the host through loopback, so the LAN
  /// address of the development machine is the sane default there.
  static const String _androidDevHost = 'http://192.168.1.103:4000';

  static const String _loopbackHost = 'http://127.0.0.1:4000';

  /// Base URL for the Kashkool Savior gateway and REST calls.
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (kIsWeb) return _loopbackHost;
    if (defaultTargetPlatform == TargetPlatform.android) return _androidDevHost;
    return _loopbackHost;
  }

  /// Model the gateway routes to its strongest healthy upstream.
  static const String saviorModel = 'kashkool-savior';
}
