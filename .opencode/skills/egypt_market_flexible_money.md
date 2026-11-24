# 🛡️ SKILL: Egypt Market — Flexible Money Flows
**ID:** `kashkool-egypt-flexible-money-v1`
**Activation:** AUTOMATIC — Triggers on any payment, wallet, installment, or financial transaction in `kashkool_app`, `kashkool_admin`, `packages/kashkool_core/`, `supabase/functions/`
**Enforcement Level:** MANDATORY — Part I Pillar 1 of Supreme Constitution

---

## 🎯 PURPOSE
Enforce **Flexible Money Flows** (Part I, Pillar 1): Full Payment, Partial/Installment, Book Reservation Fees, Teacher Discounts, Cash-to-Wallet Top-ups. All immutable-ledger, idempotent, anti-fraud checked.

---

## 🔄 AUTO-ACTIVATION TRIGGERS
- Creating payment screens/flows
- Adding wallet/top-up logic
- Implementing installment plans
- Writing financial Edge Functions
- Modifying `PaymentMethod`, `Transaction`, `Wallet` models

---

## 📋 MONEY FLOW TYPES (All Required)

### 1. Full Payment (دفع كامل)
```dart
// kashkool_core/lib/models/payment.dart
@freezed
class FullPayment with _$FullPayment implements Payment {
  const factory FullPayment({
    required String id,
    required String studentId,
    required String tenantId,
    required int amountPiasters, // EGP in piasters
    required PaymentMethod method,
    required DateTime paidAt,
    required String referenceId, // idempotency key
    required PaymentStatus status,
  }) = _FullPayment;
}
```

### 2. Partial/Installment (تقسيط / دفع جزئي)
```dart
@freezed
class InstallmentPlan with _$InstallmentPlan {
  const factory InstallmentPlan({
    required String id,
    required String studentId,
    required String tenantId,
    required int totalAmountPiasters,
    required int downPaymentPiasters,
    required int installmentCount,
    required int installmentAmountPiasters,
    required List<InstallmentSchedule> schedule,
    required InstallmentStatus status,
  }) = _InstallmentPlan;
}

@freezed
class InstallmentSchedule with _$InstallmentSchedule {
  const factory InstallmentSchedule({
    required int installmentNumber,
    required DateTime dueDate,
    required int amountPiasters,
    required InstallmentStatus status,
    DateTime? paidAt,
    String? transactionId,
  }) = _InstallmentSchedule;
}
```

### 3. Book Reservation Fees (رسوم حجز كتاب)
```dart
@freezed
class BookReservation with _$BookReservation {
  const factory BookReservation({
    required String id,
    required String studentId,
    required String tenantId,
    required String bookId,
    required int reservationFeePiasters, // Non-refundable or partially refundable
    required DateTime reservedAt,
    required DateTime expiresAt,
    required ReservationStatus status,
  }) = _BookReservation;
}
```

### 4. Teacher Discounts (خصم معلم)
```dart
@freezed
class TeacherDiscount with _$TeacherDiscount {
  const factory TeacherDiscount({
    required String id,
    required String teacherId,
    required String tenantId,
    required DiscountType type, // percentage, fixed_amount, free_month
    required int value, // percentage (0-100) or piasters
    required DateTime validFrom,
    required DateTime validTo,
    required List<String> applicableServices, // lesson_ids, course_ids
    required DiscountStatus status,
  }) = _TeacherDiscount;
}
```

### 5. Cash-to-Wallet Top-ups (شحن محفظة نقدي)
```dart
@freezed
class WalletTopUp with _$WalletTopUp {
  const factory WalletTopUp({
    required String id,
    required String studentId,
    required String tenantId,
    required int amountPiasters,
    required TopUpMethod method, // cash_at_center, card, fawry, etc.
    required String referenceId, // idempotency key
    required TopUpStatus status,
    required DateTime createdAt,
    DateTime? completedAt,
  }) = _WalletTopUp;
}
```

---

## 🔒 IMMUTABLE LEDGER REQUIREMENTS

### No Hard Deletes — Ever
```dart
// ❌ FORBIDDEN: hard-deleting a financial row
await Supabase.instance.client.from('wallet_transactions').delete().eq('id', id);

// ✅ REQUIRED: append a permanent compensating entry via the SQL RPC
await Supabase.instance.client.rpc('void_wallet_transaction', params: {
  'p_tenant_id': tenantId,
  'p_transaction_id': id,
  'p_reason': 'Customer request',
});
```

### Idempotency Keys (Mandatory)
```dart
// Every financial write MUST carry a stable idempotency key.
// The SQL RPC enforces a UNIQUE(idempotency_key) constraint inside one
// transaction; a replay returns the original row instead of charging twice.
await Supabase.instance.client.rpc('record_wallet_transaction', params: {
  'p_id': transactionId,
  'p_tenant_id': tenantId,
  'p_student_id': studentId,
  'p_amount_piasters': amountPiasters,
  'p_kind': 'topup',
  'p_idempotency_key': transactionId,
});
```

### Anti-Fraud Checks
```dart
// Velocity checks
// Duplicate amount/timestamp checks
// Device fingerprinting
// Geographic anomaly detection
// All logged to audit_logs
```

---

## 🔍 VERIFICATION CHECKLIST
```bash
# 1. All money flows have models in kashkool_core
ls packages/kashkool_core/lib/models/ | grep -E "payment|installment|wallet|discount|reservation"

# 2. Immutable ledger: no delete in financial tables
grep -r "\.delete()" apps/ backend/ --include="*.dart" --include="*.ts" | grep -E "transaction|payment|wallet" && echo "VIOLATION" || echo "OK"

# 3. Idempotency keys on all financial writes
grep -r "idempotency" apps/ backend/ --include="*.dart" --include="*.ts"

# 4. Audit logs for all corrections
grep -r "audit_logs" apps/ backend/ --include="*.dart" --include="*.ts"

# 5. RLS policies for financial tables
cat supabase/migrations/20261123000003_rls.sql | grep -E "transactions|wallets|installments|audit_logs"
```

---

## 🛑 VIOLATION RESPONSE
- Hard delete on financial data = **rejected**
- Missing idempotency key = **rejected**
- No audit log for correction = **rejected**
- Float/double for money = **rejected** (MUST use int piasters)
- Output includes: exact violation, required pattern

---

## 💡 INTEGRATION WITH SAVIOR CORE
- **OR & Context Pruning**: Filters payment options by student history, tenant config, available methods
- **Pulse-Triggered Routing**: Complex fraud detection escalates to cloud model
- **360° Awareness**: Monitors financial health, velocity, anomalies in real-time
- **Homeostasis**: Auto-reconciles discrepancies, flags stale installments