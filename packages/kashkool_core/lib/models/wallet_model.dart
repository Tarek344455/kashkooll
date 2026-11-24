import '../enums/platform_enums.dart';

/// Financial ledger, cash-to-wallet top-ups & invoices.

class WalletModel {
  final String userId;
  final double balance;
  final List<TransactionModel> transactions;

  const WalletModel({
    required this.userId,
    required this.balance,
    required this.transactions,
  });
}

class TransactionModel {
  final String transactionId;
  final double amount;
  final PaymentChannel channel;
  final DateTime timestamp;
  final String description;

  const TransactionModel({
    required this.transactionId,
    required this.amount,
    required this.channel,
    required this.timestamp,
    required this.description,
  });
}
