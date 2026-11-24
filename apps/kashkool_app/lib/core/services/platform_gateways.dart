/// Platform Gateways - wraps Egyptian payment gateways (Instapay, Fawry, Vodafone Cash)
/// Minimal stub for compilation; real gateway integration added per provider.
class PlatformGateways {
  PlatformGateways();

  /// Returns whether Instapay is available on this device/platform.
  Future<bool> isInstapayAvailable() async => true;

  /// Returns whether Fawry is available on this device/platform.
  Future<bool> isFawryAvailable() async => true;

  /// Returns whether Vodafone Cash is available on this device/platform.
  Future<bool> isVodafoneCashAvailable() async => true;

  /// Initiates a payment via the given gateway. Returns a transaction reference.
  Future<String> initiatePayment({
    required String gateway,
    required double amountEgp,
    required String referenceId,
    Map<String, dynamic>? metadata,
  }) async {
    // Stub: returns a fake reference. Real implementation calls provider SDK.
    return 'tx_${DateTime.now().millisecondsSinceEpoch}_$gateway';
  }

  /// Verifies a payment status by transaction reference.
  Future<PaymentStatus> verifyPayment(String transactionId) async {
    return PaymentStatus(transactionId: transactionId, status: 'completed');
  }
}

class PaymentStatus {
  final String transactionId;
  final String status; // 'pending', 'completed', 'failed', 'refunded'
  final String? gateway;
  final double? amountEgp;

  PaymentStatus({
    required this.transactionId,
    required this.status,
    this.gateway,
    this.amountEgp,
  });

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}
