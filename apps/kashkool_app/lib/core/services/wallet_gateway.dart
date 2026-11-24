/// Wallet Gateway - wraps wallet/payout operations for sync engine.
/// Minimal stub; real implementation connects to payment provider SDKs.
class WalletGateway {
  WalletGateway();

  /// Records a wallet transaction idempotently.
  Future<void> recordTransaction({
    required String transactionId,
    required double amountEgp,
    required String accountId,
    required String type, // 'deposit', 'payout', 'refund'
  }) async {
    // Stub: no-op. Real implementation persists to ledger.
  }

  /// Verifies a wallet transaction status.
  Future<bool> verifyTransaction(String transactionId) async {
    return true;
  }

  /// Tops up a wallet (used by SyncEngine for wallet sync).
  Future<void> topUpWallet({
    required String userId,
    required double amount,
    required String channel,
    required String transactionId,
  }) async {
    // Stub: no-op. Real implementation persists to ledger.
    await recordTransaction(
      transactionId: transactionId,
      amountEgp: amount,
      accountId: userId,
      type: 'deposit',
    );
  }
}
