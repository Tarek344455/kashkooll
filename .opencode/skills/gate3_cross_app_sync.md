# 🛡️ SKILL: Gate 3 — Cross-App Real-Time Sync Enforcer
**ID:** `kashkool-gate3-cross-app-sync-v1`
**Activation:** AUTOMATIC — Triggers on any Postgres write, Edge Function, or Realtime listener in `kashkool_app`, `kashkool_admin`, `supabase/functions/`
**Enforcement Level:** MANDATORY — Secretary QR → Student/Teacher/Parent <2s, Kill-Switch <2s

---

## 🎯 PURPOSE
Enforce **Gate 3 of the Supreme Constitution**: Real-time propagation across all apps. Secretary QR scan → Student/Teacher/Parent update instantly. Kill-Switch or Tenant Freeze → enforced `<2 seconds` via Supabase Realtime.

---

## 🔄 AUTO-ACTIVATION TRIGGERS
- Writing to Postgres through PostgREST (`.insert()`, `.update()`, `.delete()`)
- Calling idempotent RPCs (`record_attendance`, `record_wallet_transaction`, `bind_device`)
- Subscribing to Realtime channels (`channel.onPostgresChanges`, `StreamBuilder`)
- Implementing Kill-Switch / Tenant Freeze logic

---

## 📋 SYNC ARCHITECTURE

### 1. Secretary Action → Multi-App Propagation
```dart
// Secretary scans QR → offline Drift write first, then idempotent cloud sync.
await localDb.into(localDb.attendance).insert(AttendanceCompanion.insert(...));
await syncEngine.syncPending(); // calls record_attendance RPC with idempotency key
```

```sql
-- supabase/migrations/20261123000002_functions.sql
-- The RPC validates group membership, records the scan once (idempotency key),
-- and the Realtime publication pushes the row to student/teacher/parent apps.
select record_attendance(
  p_id := ..., p_tenant_id := ..., p_student_id := ...,
  p_session_id := ..., p_idempotency_key := ...
);
```

### 2. Kill-Switch / Tenant Freeze (<2s enforcement)
```dart
// Supabase Realtime: live config in ALL apps.
final channel = Supabase.instance.client
    .channel('live-config-$tenantId')
    .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'feature_flags',
      callback: (payload) => ref.read(appConfigProvider.notifier).reload(),
    )
  ..subscribe();

// In app bootstrap
ref.listen(appConfigProvider, (_, config) {
  if (config.killSwitch || config.tenantFrozen) {
    _enforceLockdown(); // MUST complete <2s
  }
});
```

### 3. Offline-First with Drift Sync
```dart
abstract class AttendanceRepository {
  Stream<List<Attendance>> watchAttendance(String studentId); // Drift
  Future<void> markAttendance(AttendanceDto dto);            // Drift + queue
  Future<void> syncPending();                                  // Drift → Supabase RPC
}

// Drift is the offline source of truth; the sync queue retries with backoff.
// Conflict rule: server-wins for attendance, immutable append for ledger rows.
```

---

## 🔍 VERIFICATION CHECKLIST
```bash
# 1. RLS policies for all cross-app tables
grep -nE "attendance|feature_flags|students|profiles" supabase/migrations/20261123000003_rls.sql

# 2. Indexes backing Realtime/filter queries
grep -n "create index" supabase/migrations/20261123000001_schema.sql

# 3. Edge Function type-check + tests
cd supabase/functions && deno task check && deno task test

# 4. Latency test (automated in CI)
# Secretary write → Student app update < 2000ms
```

---

## 🛑 VIOLATION RESPONSE
- Missing Realtime listener = **rejected**
- No Kill-Switch enforcement = **rejected**
- Latency > 2s = **rejected**
- Output includes: propagation path, missing listeners, latency measurements

---

## 💡 INTEGRATION WITH SAVIOR CORE
- **OR & Context Pruning**: Filters sync strategies by network state, app lifecycle, data priority
- **Pulse-Triggered Routing**: Complex conflict resolution escalates to cloud model
- **360° Awareness**: Monitors sync health across all 3 apps + backend in real-time
- **Homeostasis**: Auto-recovers from sync drift, re-establishes listeners on reconnect
