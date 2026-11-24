# Authentication & Local Backend (Supabase)

Kashkool uses **Supabase Auth (GoTrue)** for phone OTP and **Supabase Postgres**
for every tenant-scoped row. There is no simulated backend and no generated
verification codes in the app: a failed or unconfigured provider produces an
explicit `authBackendUnavailable` / `notConfigured` state in the UI.

---

## 1. Configuration (only via `--dart-define`)

| Variable | Where it goes | Purpose |
| --- | --- | --- |
| `SUPABASE_URL` | both Flutter apps | Project API URL |
| `SUPABASE_ANON_KEY` (publishable key) | both Flutter apps | Public client key, protected by RLS |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Functions only | Never ship in a client build |
| `WEBHOOK_SECRET` | Edge Functions only | Shared secret for webhook/import functions |
| `SAVIOR_GATEWAY_URL` | Edge Functions only | Study assistant inference gateway |
| `SAVIOR_GATEWAY_KEY` | Edge Functions only | Gateway credential, optional |

```bash
flutter run -t lib/main.dart \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

If either define is missing, `SupabaseBootstrap` stays unconfigured and the
login screen shows a real error instead of hanging or faking a session.

---

## 2. Phone numbers

`EgyptValidators.normalizeEgyptianPhone` converts every accepted local or
international format to E.164 (`+20...`) **before** `signInWithOtp` is called.
The auth repository maps GoTrue errors to the existing `AuthErrorCode` enum:
rate limits, quota, provider disabled / not configured, network, invalid code.

An SMS provider (Twilio / MessageBird / Vonage) must be enabled in the Supabase
dashboard for live OTP delivery. Without it the request fails loudly — no code
is hardcoded, and no exception is swallowed.

---

## 3. First-run database setup

```bash
# Hosted project
supabase link --project-ref <project-ref>
supabase db push

# Local stack (requires Docker Desktop)
powershell -ExecutionPolicy Bypass -File scripts\start-dev-backend.ps1
```

`supabase db push` applies, in order:
`000001_schema.sql`, `000002_functions.sql`, `000003_rls.sql`,
`000004_realtime.sql`, `000005_cron.sql`, `000006_billing_atomic.sql`,
`000007_import_columns.sql`. The local script additionally loads
`supabase/seed.sql` and verifies the Auth and Data API health endpoints.

---

## 4. Device binding

On first successful OTP the client derives a device fingerprint and calls the
`bind_device` RPC. The Postgres `profiles`/`students` rows store the bound
device id; a mismatch raises `DeviceSecurityException`. Web sessions use an
empty fingerprint by design and are exempt from hardware binding.

---

## 5. Verification

```bash
python supabase/validate_sql.py          # PostgreSQL grammar for every migration
cd supabase/functions && deno task check && deno task test
supabase test db                 # pgTAP: RLS on every public table
flutter analyze --fatal-infos            # in each Dart package
```
