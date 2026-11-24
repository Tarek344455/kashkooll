# 🛡️ SKILL: Immutable Financial Ledger
**ID:** `kashkool-financial-ledger-immutable-v1`
**Activation:** AUTOMATIC — Triggers on any financial transaction, correction, audit log, or ledger query in `kashkool_app`, `kashkool_admin`, `packages/kashkool_core/`, `supabase/functions/`
**Enforcement Level:** MANDATORY — Part I Pillar 2 of Supreme Constitution

---

## 🎯 PURPOSE
Enforce **Immutable Financial Ledger** (Part I, Pillar 2): No hard-deletes or silent edits. Corrections via Void/Refund Entry in `/tenants/{tenantId}/audit_logs`. Push alerts on anomalies.

---

## 🔄 AUTO-ACTIVATION TRIGGERS
- Writing to transactions, payments, wallets, installments tables
- Implementing void/refund logic
- Creating audit log entries
- Querying financial reports

---

## 📋 IMMUTABLE LEDGER ARCHITECTURE

### 1. Append-Only Tables (Supabase Postgres)
```typescript
// supabase/functions/models/ledger.ts
interface LedgerEntry {
  id: string;                    // Auto-generated
  tenantId: string;
  type: LedgerEntryType;         // PAYMENT, REFUND, VOID, TOPUP, ADJUSTMENT
  amountPiasters: number;           // Positive for credit, negative for debit
  balanceAfterPiasters: number;     // Running balance
  referenceId: string;           // Idempotency key
  relatedEntryId?: string;       // For void/refund: original entry ID
  metadata: LedgerMetadata;      // User, device, location, reason
  createdAt: Timestamp;          // Server timestamp
  createdBy: string;             // User ID
}

// NEVER update or delete ledger entries
// Corrections = new entries with type VOID/REFUND
```

### 2. Void/Refund Pattern (Corrections Only)
```dart
// kashkool_core/lib/services/ledger_service.dart
class LedgerService {
  // Void: Cancel a payment (full reversal)
  Future<void> voidPayment({
    required String originalEntryId,
    required String reason,
    required String voidedBy,
  }) async {
    final original = await _getEntry(originalEntryId);
    
    // Create void entry (negative of original)
    await _createEntry(LedgerEntry(
      type: LedgerEntryType.VOID,
      amountPiasters: -original.amountPiasters,
      balanceAfterPiasters: original.balanceAfterPiasters - original.amountPiasters,
      relatedEntryId: originalEntryId,
      metadata: LedgerMetadata(
        reason: reason,
        voidedBy: voidedBy,
        originalAmount: original.amountPiasters,
      ),
    ));
    
    // Push alert
    await _pushAlert(VoidAlert(originalEntryId, reason, voidedBy));
  }
  
  // Refund: Partial or full return (new money out)
  Future<void> refundPayment({
    required String originalEntryId,
    required int refundAmountPiasters,
    required String reason,
    required String refundedBy,
  }) async {
    // Validate: refundAmount <= originalAmount - alreadyRefunded
    // Create refund entry
    // Push alert
  }
}
```

### 3. Audit Logs (Separate Collection)
```dart
// /tenants/{tenantId}/audit_logs
@freezed
class AuditLog with _$AuditLog {
  const factory AuditLog({
    required String id,
    required String tenantId,
    required AuditAction action, // CREATE, VOID, REFUND, ADJUST, FREEZE
    required String entityType,  // TRANSACTION, WALLET, INSTALLMENT
    required String entityId,
    required String performedBy,
    required Map<String, dynamic> before,  // State before
    required Map<String, dynamic> after,   // State after
    required String reason,
    required DateTime timestamp,
    required String ipAddress,
    required String deviceFingerprint,
  }) = _AuditLog;
}
```

### 4. Push Alerts on Anomalies
```dart
// Real-time alerts for financial anomalies
class FinancialAlertService {
  // Velocity: >5 transactions/minute from same user
  // Amount: >10x average transaction
  // Geographic: New country/IP
  // Device: New fingerprint
  // Pattern: Round numbers, sequential amounts
  
  Future<void> checkAndAlert(LedgerEntry entry) async {
    final anomalies = <AnomalyType>[];
    
    if (await _checkVelocity(entry)) anomalies.add(AnomalyType.velocity);
    if (await _checkAmount(entry)) anomalies.add(AnomalyType.amount);
    if (await _checkGeographic(entry)) anomalies.add(AnomalyType.geographic);
    if (await _checkDevice(entry)) anomalies.add(AnomalyType.device);
    
    if (anomalies.isNotEmpty) {
      await _sendAlert(FinancialAlert(
        entryId: entry.id,
        anomalies: anomalies,
        severity: _calculateSeverity(anomalies),
        timestamp: DateTime.now(),
      ));
    }
  }
}
```

### 5. Reconciliation Formula (End-of-Day)
```dart
// Multi-center settlement (Part I, Pillar 2)
class SettlementService {
  Future<SettlementResult> reconcileDaily(String tenantId, DateTime date) async {
    // Formula: (Attended × Price) – Split% – Wages = Net Payout
    
    final sessions = await _getSessions(tenantId, date);
    final teachers = await _getTeachers(tenantId);
    
    for (final teacher in teachers) {
      final teacherSessions = sessions.where((s) => s.teacherId == teacher.id);
      final attended = teacherSessions.where((s) => s.status == 'attended').length;
      final price = teacher.sessionPricePiasters;
      final splitPercent = teacher.splitPercent; // e.g., 30%
      final wages = teacher.hourlyWagePiasters * teacher.hoursWorked;
      
      final gross = attended * price;
      final platformShare = (gross * splitPercent) ~/ 100;
      final netPayout = gross - platformShare - wages;
      
      await _createSettlementEntry(SettlementEntry(
        teacherId: teacher.id,
        date: date,
        attendedSessions: attended,
        grossPiasters: gross,
        platformSharePiasters: platformShare,
        wagesPiasters: wages,
        netPayoutPiasters: netPayout,
      ));
    }
  }
}
```

---

## 🔍 VERIFICATION CHECKLIST
```bash
# 1. No delete/update on ledger tables
grep -r "\.delete()\|\.update(" apps/ backend/ --include="*.dart" --include="*.ts" | grep -E "ledger|transaction|payment|wallet" && echo "VIOLATION" || echo "OK"

# 2. Void/Refund pattern implemented
grep -r "LedgerEntryType.VOID\|LedgerEntryType.REFUND" apps/ backend/

# 3. Audit logs for all corrections
grep -r "audit_logs" apps/ backend/ --include="*.dart" --include="*.ts"

# 4. Push alerts on anomalies
grep -r "FinancialAlert\|checkAndAlert" apps/ backend/

# 5. Reconciliation formula
grep -r "reconcileDaily\|SettlementService" apps/ backend/

# 6. RLS policies: ledger/audit_logs write-only for system
cat supabase/migrations/20261123000003_rls.sql | grep -A5 "ledger\|audit_logs"
```

---

## 🛑 VIOLATION RESPONSE
- Hard delete on ledger = **rejected**
- Silent edit (update without audit) = **rejected**
- Correction without void/refund entry = **rejected**
- Missing audit log = **rejected**
- No anomaly alerts = **rejected**
- Float/double for money = **rejected**
- Output includes: exact violation, required pattern

---

## 💡 INTEGRATION WITH SAVIOR CORE
- **OR & Context Pruning**: Filters reconciliation by center, teacher, date range, anomaly severity
- **Pulse-Triggered Routing**: Complex fraud pattern detection escalates to cloud
- **360° Awareness**: Monitors ledger health, reconciliation status, alert volume in real-time
- **Homeostasis**: Auto-flags unreconciled entries, re-triggers failed settlements