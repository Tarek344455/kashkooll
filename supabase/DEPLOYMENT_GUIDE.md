# Kashkool Supabase Live Deployment Guide

## Prerequisites

1. **Supabase Project** — Create at https://supabase.com/dashboard
2. **Project Reference ID** — Settings → General → Reference ID (e.g., `abcdefghijklmnopqrst`)
3. **Access Token** — Settings → Access Tokens → Generate new token

## Quick Deploy (One Command)

```powershell
# From project root
cd N:\spaceship-ai\projects\kashkool\supabase
.\deploy-live.ps1 -ProjectRef "YOUR_PROJECT_REF" -AccessToken "YOUR_ACCESS_TOKEN"
```

## Manual Step-by-Step

### 1. Link to Live Project
```powershell
$env:SUPABASE_ACCESS_TOKEN = "sb_your_token_here"
supabase link --project-ref YOUR_PROJECT_REF
```

### 2. Push All Migrations
```powershell
supabase db push
```
> If conflicts: `supabase db reset --linked` (destroys data, applies fresh)

### 3. Create Private `receipts` Storage Bucket
```powershell
supabase storage buckets create receipts --public=false
```

### 4. Create Storage RLS Policies
```powershell
# Student upload
supabase storage policies create receipts `
    --name "student-upload" `
    --operation insert `
    --definition 'auth.role() = "authenticated" AND (bucket_id = "receipts")'

# Student read own
supabase storage policies create receipts `
    --name "student-read-own" `
    --operation select `
    --definition 'auth.role() = "authenticated" AND (bucket_id = "receipts") AND (owner = auth.uid())'

# Staff read all in tenant
supabase storage policies create receipts `
    --name "staff-read-all" `
    --operation select `
    --definition 'auth.role() = "authenticated" AND (bucket_id = "receipts") AND EXISTS (
        SELECT 1 FROM profiles p 
        WHERE p.id = auth.uid() 
        AND p.tenant_id = (SELECT tenant_id FROM payment_submissions WHERE receipt_url LIKE "%" || name || "%")
        AND p.role IN ("teacher", "secretary", "admin")
    )'
```

## Verify Deployment

1. **Migrations**: Dashboard → SQL Editor → Run `SELECT * FROM supabase_migrations.schema_migrations;`
2. **Tables**: Dashboard → Table Editor → Verify `payment_channels`, `payment_submissions`, `ledger_entries`
3. **Storage**: Dashboard → Storage → Verify `receipts` bucket (private)
4. **RPC**: Dashboard → SQL Editor → Test `SELECT approve_payment_submission(...);`

## Post-Deploy Checklist

- [ ] All 10 migrations applied
- [ ] `receipts` bucket created (private)
- [ ] 3 storage policies active
- [ ] RLS policies on payment tables working
- [ ] Edge functions deployed (if any)
- [ ] App connects to live Supabase URL/anon key

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `DbConnectError` | Check `SUPABASE_ACCESS_TOKEN` is set |
| `42501 insufficient_privilege` | Verify RLS policies match queries |
| `PGRST query errors` | Check composite indexes in `000001_schema.sql` |
| Bucket not found | Run storage bucket create command |
| Policy denied | Verify policy definitions match app queries |

## Local Development (Optional)

If Docker becomes available:
```powershell
supabase start          # Start local stack
supabase db reset       # Apply all migrations fresh
supabase status         # Show local URLs/keys
```

## Files in This Deployment

| File | Purpose |
|------|---------|
| `deploy-live.ps1` | Automated deploy script |
| `migrations/000001-000009_*.sql` | All schema, RLS, functions |
| `seed.sql` | Initial data |
| `validate_sql.py` | SQL syntax validator |
| `DEPLOYMENT_GUIDE.md` | This file |