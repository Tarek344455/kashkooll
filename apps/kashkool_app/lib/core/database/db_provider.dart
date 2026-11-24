import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_db.dart';
import '../services/feature_flag_service.dart';
import '../services/network_client.dart';
import '../services/platform_gateways.dart';
import '../services/wallet_gateway.dart';

/// Single Drift instance for the app. Closed when the provider is disposed.
final localDbProvider = Provider<LocalDb>((ref) {
  final db = LocalDb();
  ref.onDispose(db.close);
  return db;
});

/// Platform gateways provider
final platformGatewaysProvider = Provider<PlatformGateways>((ref) {
  return PlatformGateways();
});

/// Wallet gateway provider
final walletGatewayProvider = Provider<WalletGateway>((ref) {
  return WalletGateway();
});

/// Feature flag service provider
final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  return FeatureFlagService(
    localDb: ref.read(localDbProvider),
    networkClient: ref.read(billingNetworkClientProvider),
    platformGateways: ref.read(platformGatewaysProvider),
  );
});
