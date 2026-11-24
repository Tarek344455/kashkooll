/// Enumerations used across the Kashkool Core package.

enum UserRole {
  supervisor,
  centerAdmin,
  teacher,
  secretary,
  student,
  parent,
}

enum TenantType {
  center,
  teacher,
}

enum SyncPriority {
  critical,
  high,
  normal,
}

enum SyncStatus {
  pending,
  processing,
  completed,
  failed,
}

enum SessionType {
  offline,
  online,
}

enum PaymentChannel {
  cashToWallet,
  fawry,
  vodafoneCash,
  instaPay,
}

enum QuestionDifficulty {
  easy,
  medium,
  hard,
}
