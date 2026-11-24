# 🛡️ SKILL: Instant Multi-Center Settlement
**ID:** `kashkool-multi-center-settlement-v1`
**Activation:** AUTOMATIC — Triggers on end-of-day reconciliation, teacher payout, center settlement in `kashkool_admin`, `supabase/functions/`
**Enforcement Level:** MANDATORY — Part I Pillar 2 of Supreme Constitution

---

## 🎯 PURPOSE
Enforce **Instant Multi-Center Settlement** (Part I, Pillar 2): 1-tap end-of-day reconciliation formula: (Attended × Price) – Split% – Wages = Net Payout.

---

## 🔄 AUTO-ACTIVATION TRIGGERS
- Running daily reconciliation
- Calculating teacher payouts
- Generating settlement reports
- Processing center-level settlements

---

## 📋 SETTLEMENT FORMULA & IMPLEMENTATION

### Core Formula
```
Net Payout = (Attended Sessions × Session Price) – Platform Split% – Teacher Wages
```

### 1. Data Model
```dart
// kashkool_core/lib/models/settlement.dart
@freezed
class DailySettlement with _$DailySettlement {
  const factory DailySettlement({
    required String id,
    required String tenantId,
    required String centerId,
    required DateTime date,
    required List<TeacherSettlement> teachers,
    required int totalGrossPiasters,
    required int totalPlatformSharePiasters,
    required int totalWagesPiasters,
    required int totalNetPayoutPiasters,
    required SettlementStatus status, // DRAFT, CONFIRMED, PAID
    required DateTime createdAt,
    DateTime? confirmedAt,
    String? confirmedBy,
  }) = _DailySettlement;
}

@freezed
class TeacherSettlement with _$TeacherSettlement {
  const factory TeacherSettlement({
    required String teacherId,
    required String teacherName,
    required int attendedSessions,
    required int sessionPricePiasters,
    required int splitPercent,        // e.g., 30
    required int hourlyWagePiasters,
    required int hoursWorked,
    required int grossPiasters,
    required int platformSharePiasters,
    required int wagesPiasters,
    required int netPayoutPiasters,
  }) = _TeacherSettlement;
}
```

### 2. One-Tap Reconciliation Service
```dart
// kashkool_admin/lib/services/settlement_service.dart
class SettlementService {
  // One-tap: generates draft → preview → confirm
  Future<DailySettlement> generateDraft({
    required String tenantId,
    required String centerId,
    required DateTime date,
  }) async {
    // 1. Fetch all sessions for date/center
    final sessions = await _sessionRepo.getByCenterAndDate(centerId, date);
    
    // 2. Group by teacher
    final byTeacher = _groupByTeacher(sessions);
    
    // 3. Calculate per teacher
    final teachers = <TeacherSettlement>[];
    for (final (teacherId, teacherSessions) in byTeacher.entries) {
      final teacher = await _teacherRepo.get(teacherId);
      final attended = teacherSessions.where((s) => s.status == 'attended').length;
      
      final gross = attended * teacher.sessionPricePiasters;
      final platformShare = (gross * teacher.splitPercent) ~/ 100;
      final wages = teacher.hourlyWagePiasters * _calculateHours(teacherSessions);
      final net = gross - platformShare - wages;
      
      teachers.add(TeacherSettlement(
        teacherId: teacherId,
        teacherName: teacher.name,
        attendedSessions: attended,
        sessionPricePiasters: teacher.sessionPricePiasters,
        splitPercent: teacher.splitPercent,
        hourlyWagePiasters: teacher.hourlyWagePiasters,
        hoursWorked: _calculateHours(teacherSessions),
        grossPiasters: gross,
        platformSharePiasters: platformShare,
        wagesPiasters: wages,
        netPayoutPiasters: net,
      ));
    }
    
    // 4. Create draft settlement
    return DailySettlement(
      id: 'settlement_${centerId}_${date.toIso8601String()}',
      tenantId: tenantId,
      centerId: centerId,
      date: date,
      teachers: teachers,
      totalGrossPiasters: teachers.fold(0, (a, b) => a + b.grossPiasters),
      totalPlatformSharePiasters: teachers.fold(0, (a, b) => a + b.platformSharePiasters),
      totalWagesPiasters: teachers.fold(0, (a, b) => a + b.wagesPiasters),
      totalNetPayoutPiasters: teachers.fold(0, (a, b) => a + b.netPayoutPiasters),
      status: SettlementStatus.draft,
      createdAt: DateTime.now(),
    );
  }
  
  // Confirm and create ledger entries
  Future<void> confirmAndPost(DailySettlement draft, String confirmedBy) async {
    // 1. Verify all teachers have valid bank details
    // 2. Create ledger entries for each teacher payout
    // 3. Update settlement status to CONFIRMED
    // 4. Trigger payout process (bank transfer, wallet, etc.)
  }
}
```

### 3. Secretary/Admin UI — One Tap
```dart
// kashkool_admin/lib/features/settlement/settlement_screen.dart
class SettlementScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);
    final center = ref.watch(selectedCenterProvider);
    
    return Column(
      children: [
        _DateCenterPicker(),
        Consumer(
          builder: (_, ref, __) {
            final draft = ref.watch(draftSettlementProvider(center.id, date));
            return switch (draft) {
              AsyncData(:final value) => _SettlementPreview(settlement: value),
              AsyncLoading() => const SpaceGlassShimmer(child: _SettlementSkeleton()),
              AsyncError(:final error) => ErrorState(message: error.toString()),
            };
          },
        ),
        // ONE TAP CONFIRM
        FilledButton.icon(
          icon: const Icon(Icons.check_circle),
          label: Text(context.l10n.settlementConfirm),
          onPressed: () => _confirmSettlement(ref, center.id, date),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: SecretaryColors.success,
          ),
        ),
      ],
    );
  }
  
  void _confirmSettlement(WidgetRef ref, String centerId, DateTime date) async {
    // Show confirmation dialog with summary
    final confirmed = await showDialog<bool>(...);
    if (confirmed == true) {
      await ref.read(settlementServiceProvider).confirmAndPost(centerId, date);
      ref.read(feedbackProvider.notifier).showSuccess();
    }
  }
}
```

### 4. Center-Level Aggregation
```dart
// Multi-center: aggregate all centers for tenant-level view
class TenantSettlementService {
  Future<TenantSettlement> aggregateTenant(String tenantId, DateTime date) async {
    final centers = await _centerRepo.getAll(tenantId);
    final centerSettlements = await Future.wait(
      centers.map((c) => _getCenterSettlement(c.id, date))
    );
    
    return TenantSettlement(
      tenantId: tenantId,
      date: date,
      centers: centerSettlements,
      totalGrossPiasters: centerSettlements.fold(0, (a, b) => a + b.totalGrossPiasters),
      totalNetPayoutPiasters: centerSettlements.fold(0, (a, b) => a + b.totalNetPayoutPiasters),
    );
  }
}
```

---

## 🔍 VERIFICATION CHECKLIST
```bash
# 1. Settlement models in kashkool_core
ls packages/kashkool_core/lib/models/ | grep settlement

# 2. One-tap UI in admin
grep -r "SettlementScreen\|confirmAndPost" apps/kashkool_admin/lib/features/settlement/

# 3. Formula implementation
grep -r "Attended.*Price.*Split.*Wages" apps/ backend/

# 4. Ledger entries on confirm
grep -r "LedgerEntryType.PAYOUT\|LedgerEntryType.SETTLEMENT" apps/ backend/

# 5. RLS policies for settlement tables
cat supabase/migrations/20261123000003_rls.sql | grep -A10 "settlements"
```

---

## 🛑 VIOLATION RESPONSE
- Multi-step reconciliation (not one-tap) = **rejected**
- Formula mismatch = **rejected**
- No ledger entries on confirm = **rejected**
- Missing center-level aggregation = **rejected**
- No preview before confirm = **rejected**
- Output includes: exact violation, required pattern

---

## 💡 INTEGRATION WITH SAVIOR CORE
- **OR & Context Pruning**: Filters settlement scope by center, date range, teacher status
- **Pulse-Triggered Routing**: Complex multi-center aggregation escalates to cloud
- **360° Awareness**: Monitors settlement status, payout delays, discrepancies in real-time
- **Homeostasis**: Auto-generates drafts daily, flags unconfirmed settlements