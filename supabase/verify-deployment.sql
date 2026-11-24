-- Kashkool Supabase Deployment Verification
-- Run this in Supabase Dashboard > SQL Editor after deployment

-- 1. Verify all migrations applied
SELECT version, name, applied_at 
FROM supabase_migrations.schema_migrations 
ORDER BY applied_at;

-- 2. Verify payment tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('payment_channels', 'payment_submissions', 'ledger_entries');

-- 3. Verify RLS enabled on payment tables
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('payment_channels', 'payment_submissions', 'ledger_entries');

-- 4. Verify RPC functions exist
SELECT proname, prosrc 
FROM pg_proc 
WHERE proname IN ('approve_payment_submission', 'reject_payment_submission');

-- 5. Verify storage bucket
SELECT id, name, public 
FROM storage.buckets 
WHERE name = 'receipts';

-- 6. Verify storage policies
SELECT policyname, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects' 
AND policyname LIKE '%receipts%';

-- 7. Test RPC (replace with real submission_id)
-- SELECT approve_payment_submission('test-submission-id', 'test-reviewer-id', 'test note');
-- SELECT reject_payment_submission('test-submission-id', 'test-reviewer-id', 'test reason');

-- 8. Verify indexes on payment_submissions
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'payment_submissions';

-- 9. Verify unique constraint (non-rejected submissions)
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE conrelid = 'payment_submissions'::regclass 
AND contype = 'u';

-- 10. Verify ledger_entries append-only (no UPDATE/DELETE policies)
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'ledger_entries';