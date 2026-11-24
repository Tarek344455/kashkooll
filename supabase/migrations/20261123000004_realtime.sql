-- Realtime: live-sync contract (Gate 3). A scan, payment, flag flip or tenant
-- freeze propagates to every connected role in <2s via postgres_changes.
-- Guarded so the file also applies to a plain PostgreSQL instance.

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    -- Add each table idempotently (ALTER PUBLICATION ... ADD TABLE errors if
    -- the table is already a member, so check pg_publication_tables first).
    declare
      t text;
    begin
      foreach t in array array[
        'attendance', 'wallet_transactions', 'students', 'sessions',
        'feature_flags', 'tenants', 'audit_logs', 'reservations', 'quiz_results'
      ]
      loop
        if not exists (
          select 1 from pg_publication_tables
          where pubname = 'supabase_realtime'
            and schemaname = 'public'
            and tablename = t
        ) then
          execute format('alter publication supabase_realtime add table public.%I', t);
        end if;
      end loop;
    end;
  else
    create publication supabase_realtime for table
      public.attendance, public.wallet_transactions, public.students,
      public.sessions, public.feature_flags, public.tenants,
      public.audit_logs, public.reservations, public.quiz_results;
  end if;
end
$$;

-- REPLICA IDENTITY FULL lets Realtime deliver old-row payloads for UPDATE/
-- DELETE (needed for optimistic UI reconciliation on the clients).
alter table public.attendance replica identity full;
alter table public.wallet_transactions replica identity full;
alter table public.students replica identity full;
alter table public.sessions replica identity full;
alter table public.feature_flags replica identity full;
alter table public.tenants replica identity full;
alter table public.audit_logs replica identity full;
alter table public.reservations replica identity full;
alter table public.quiz_results replica identity full;
