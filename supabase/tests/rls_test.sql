-- pgTAP gate for the security model. Runs against the local stack with
-- `supabase test db --local`. Fails the build if any public table is exposed
-- without RLS or if an anonymous client can read the immutable audit trail.

begin;
select plan(2);

select is(
    (select count(*)::int from pg_tables where schemaname = 'public' and not rowsecurity),
    0,
    'every public table enforces row level security'
);

set local role anon;
select throws_ok(
    'select * from public.audit_logs',
    '42501',
    null,
    'anonymous clients cannot read the immutable audit trail'
);
reset role;

select * from finish();
rollback;
