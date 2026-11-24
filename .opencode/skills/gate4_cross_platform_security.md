# 🛡️ SKILL: Gate 4 — Cross-Platform & Security Enforcer
**ID:** `kashkool-gate4-cross-platform-security-v1`
**Activation:** AUTOMATIC — Triggers on any platform-specific code, security-sensitive feature, or Postgres query in `kashkool_app`, `kashkool_admin`, `packages/kashkool_core/`
**Enforcement Level:** MANDATORY — No `dart:io` in shared, FLAG_SECURE + Watermark, Rules/Indexes match

---

## 🎯 PURPOSE
Enforce **Gate 4 of the Supreme Constitution**: No `dart:io` in shared files. Enforce `FLAG_SECURE` + `DynamicWatermarkOverlay` on paid content. Every Postgres query must match `supabase/migrations/20261123000003_rls.sql` and `supabase/migrations/20261123000001_schema.sql`.

---

## 🔄 AUTO-ACTIVATION TRIGGERS
- Importing `dart:io`, `dart:html`, `package:flutter/foundation.dart` (kIsWeb)
- Creating paid content screens (video, PDF, premium features)
- Writing Postgres queries (`.eq()`, `.gte()`, `.order()`, `.limit()`)
- Adding new collections/documents in Supabase Postgres

---

## 📋 ENFORCEMENT RULES

### 1. No Platform-Specific Code in Shared (`kashkool_core`)
```dart
// ❌ FORBIDDEN in kashkool_core
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

// ✅ REQUIRED: Platform interface in core, implementations in apps
// kashkool_core/lib/platform/platform_interface.dart
abstract class PlatformService {
  Future<void> secureScreen(bool enable);
  Future<String> getDeviceId();
  Future<void> preventScreenshot(bool enable);
}

// kashkool_app/lib/platform/platform_service_impl.dart
class PlatformServiceImpl implements PlatformService {
  @override
  Future<void> secureScreen(bool enable) async {
    if (enable) {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } else {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    }
  }
  // ...
}
```

### 2. FLAG_SECURE + Dynamic Watermark on Paid Content
```dart
// Required for ALL paid content screens
class PaidContentScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Enable FLAG_SECURE immediately
    useEffect(() {
      ref.read(platformServiceProvider).secureScreen(true);
      return () => ref.read(platformServiceProvider).secureScreen(false);
    }, []);
    
    // 2. Dynamic watermark overlay
    return Stack(
      children: [
        _ContentPlayer(),
        DynamicWatermarkOverlay(
          userId: ref.watch(currentUserProvider).id,
          tenantId: ref.watch(currentTenantProvider).id,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }
}

// Watermark: diagonal, semi-transparent, user-specific, rotates
class DynamicWatermarkOverlay extends StatefulWidget {
  // ... implementation with CustomPainter
}
```

### 3. RLS policies & Indexes Match (Zero Drift)
```sql
-- Example Dart query:
-- supabase.from('lessons').select('id,title').eq('tenant_id', tid)
--     .eq('status', 'published').order('created_at');

-- Required RLS policy in supabase/migrations/20261123000003_rls.sql:
create policy lessons_read on public.lessons for select to authenticated
using (tenant_id = public.auth_tenant_id() and status = 'published');

-- Required covering index in supabase/migrations/20261123000001_schema.sql:
create index lessons_tenant_status_idx
  on public.lessons (tenant_id, status, created_at desc);
```

---

## 🔍 VERIFICATION CHECKLIST
```bash
# 1. No dart:io in shared
grep -r "import 'dart:io'" packages/kashkool_core/ && echo "VIOLATION" || echo "OK"

# 2. FLAG_SECURE on all paid screens
grep -r "FLAG_SECURE" apps/kashkool_app/lib/features/paid_content/

# 3. Watermark on all paid screens
grep -r "DynamicWatermarkOverlay" apps/kashkool_app/lib/features/paid_content/

# 4. Migrations parse + RLS enforced (automated gate)
python supabase/validate_sql.py
supabase test db
```

---

## 🛑 VIOLATION RESPONSE
- `dart:io` in shared = **rejected**
- Paid content without FLAG_SECURE = **rejected**
- Paid content without Watermark = **rejected**
- Query without matching rule/index = **rejected**
- Output includes: exact file:line, required fix pattern

---

## 💡 INTEGRATION WITH SAVIOR CORE
- **OR & Context Pruning**: Filters platform implementations by target platform (Android/iOS/Web/Desktop)
- **Pulse-Triggered Routing**: Complex security logic (watermark generation, DRM) escalates to cloud
- **360° Awareness**: Monitors security posture across all platforms in real-time
- **Homeostasis**: Auto-reapplies FLAG_SECURE on lifecycle changes, regenerates watermarks on user switch