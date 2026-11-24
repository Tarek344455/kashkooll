# Supabase Handoff — Kashkool

Snapshot of the Supabase backend migration. Everything below refers to the
live Supabase architecture. No credentials or key material belong in this file.

---

## Backend layout

- `supabase/migrations/` — schema, triggers, RPCs, RLS, Realtime, cron,
  atomic billing, import provenance columns.
- `supabase/functions/` — Deno Edge Functions (subscription webhook, wallet
  webhooks, usage metering, weekly parent report, monthly billing, expiry,
  smart router, sheet migration) plus `_shared/` helpers and tests.
- `supabase/tests/rls_test.sql` — pgTAP security gate.
- `supabase/config.toml`, `supabase/seed.sql`, `supabase/validate_sql.py`.

The former Node function and legacy rule trees were removed after their
behaviour was ported. The pre-migration snapshot
is at `N:\spaceship-ai\projects\kashkool-pre-supabase-backup`.

---

## Required environment

Client (via `--dart-define`): `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
Edge Functions (Supabase secrets / `.env.local`): `SUPABASE_URL`,
`SUPABASE_SERVICE_ROLE_KEY`, `WEBHOOK_SECRET`, and for the study assistant
`SAVIOR_GATEWAY_URL`, `SAVIOR_GATEWAY_KEY`.

The gateway itself keeps its own config at
`C:\Users\ALesraagroup\.config\opencode\kashkool-savior\config\router.json`.

---

## Data model highlights

- `tenants`, `profiles`, `students`, `groups`, `halls`, `sessions`,
  `attendance` — tenant-scoped, idempotent attendance via
  `record_attendance`.
- `wallet_transactions` — append-only integer-piasters ledger; corrections go
  through `void_wallet_transaction`, never a `DELETE`.
- `billing_transactions`, `invoices`, `subscriptions`, `usage_events` — fully
  atomic through `process_subscription_payment`, `increment_usage`,
  `expire_subscriptions`.
- `reservations`, `quizzes`, `quiz_results`, `reports`, `audit_logs`,
  `feature_flags`, `knowledge_cache` — all RLS-protected.
- `feature_flags` and `tenants.is_active` power the admin kill-switch and
  freeze, propagated through Realtime in under two seconds.

---

## Commands

```bash
python supabase/validate_sql.py
cd supabase/functions && deno task check && deno task test
supabase db reset        # local, requires Docker
supabase test db
flutter pub get          # in all three Dart packages
dart run build_runner build
flutter analyze --fatal-infos
flutter test
```

Live OTP, Realtime delivery and webhook end-to-end checks require a real
Supabase project and an SMS/webhook provider. Until those credentials exist the
apps surface explicit `notConfigured` errors rather than invented codes.
