# ARCHITECTURE.md — KASHKOOL (كشكول) MASTER INFRASTRUCTURE SPECIFICATION

## 1. SYSTEM OVERVIEW & ARCHITECTURAL PRINCIPLES
Kashkool is an enterprise-grade, multi-tenant EdTech ecosystem built specifically for the Egyptian educational market (Centers, Teachers, Secretaries, Students, Parents, Super Admin).

### Core Pillars:
1. **Offline-First Operations:** Edge operations (Dynamic QR attendance, thermal receipt printing, cash desk ledger) run with zero network reliance, committing locally to SQLCipher and queuing for cloud sync.
2. **Zero-Trust Multi-Tenancy:** Every entity belongs to a `tenantId`. RLS policies, Drift local storage, and edge functions enforce absolute isolation at the storage, database, and logic layers.
3. **Anti-Piracy & Hardware Binding:** Single-device binding via SHA-256 hardware fingerprints (`deviceFingerprint`), screen recording/capture blocking (`FLAG_SECURE`), and dynamic drifting watermarks.
4. **Invisible Intelligence (No AI Jargon):** All smart features (automated grading, Socratic study assistance, parent weekly reports, adaptive question bank) operate under native platform names (`StudyAssistant`, `AutomatedReports`, `QuestionEngine`, `SmartSchedule`).
5. **Space Glass Design System:** Cosmic dark theme (`#060913` -> `#0B1021` -> `#111833`), translucent blur surfaces, glowing neon accents, and white-label dynamic token overrides per tenant.

---

## 2. MONOREPO STRUCTURE
```text
kashkool/
├── ARCHITECTURE.md
├── EXECUTION_ROADMAP.md
├── packages/
│   └── kashkool_core/            # Shared immutable models, enums, validators
├── apps/
│   ├── kashkool_app/             # Cross-platform client app (iOS, Android, Windows, macOS, Web)
│   └── kashkool_admin/           # God-Mode Super-Admin app
└── backend/
    ├── supabase/                 # Security rules, indexes, realtime DB rules
    └── functions/                # TypeScript Node.js 20 Edge Functions
```

---

## 3. MULTI-TENANCY & RBAC MATRIX
- **Super Admin (`god_mode`):** Global access, tenant provisioning, system kill-switches, ghost impersonation tokens.
- **Center Admin (`center_admin`):** Full control over center tenant, groups, billing, secretary accounts, revenue reports.
- **Teacher (`teacher`):** Teacher tenant or center instructor, course manager, question bank creator, gradebook.
- **Secretary (`secretary`):** Offline scanner desk, cash top-ups, thermal receipt printing, attendance check-in.
- **Student (`student`):** Access to enrolled courses, live DRM lectures, quiz engine, Socratic StudyAssistant, student wallet.
- **Parent (`parent`):** Linked to student accounts, views behavioral/attendance reports, exam history, fee receipts.

---

## 4. SECURITY & ANTI-PIRACY RULES
1. **Hardware Fingerprint Locking:** SHA-256 identifier generated from device hardware parameters. On auth, verified against student's `boundDeviceId`.
2. **Screen Capture Defense:** `FLAG_SECURE` enabled on Android; screen capture detection on iOS/desktop triggers stream obscuration and logs security event to Supabase Postgres.
3. **Dynamic Watermark Overlay:** Floating canvas overlay displaying `Student Name + Phone + Device ID` drifting across video and exam viewports at random intervals.

---

## 5. CODING CONVENTIONS & QUALITY STANDARDS
- **Dart/Flutter:** Strict null safety, immutable data structures (`copyWith`, `toJson`, `fromJson`), Riverpod state management.
- **TypeScript Functions:** Node.js 20 runtime, strict type checking, atomic transactions for financial ledger entries.
- **Local Database:** Drift with SQLCipher AES-256 encryption. Key stored in secure storage.
