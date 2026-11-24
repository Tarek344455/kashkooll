-- Provenance columns used by the idempotent sheet-import edge function.
do $$
declare
  t text;
begin
  foreach t in array array[
    'students', 'sessions', 'wallet_transactions', 'attendance', 'quizzes'
  ]
  loop
    execute format(
      'alter table public.%I add column if not exists migration_source text not null default ''''', t
    );
    execute format(
      'alter table public.%I add column if not exists migrated_at timestamptz', t
    );
  end loop;
end
$$;
