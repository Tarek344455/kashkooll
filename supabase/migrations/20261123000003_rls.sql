-- Row Level Security: tenant isolation enforced inside Postgres.
-- Every table is locked down; service_role (edge functions) bypasses RLS.

alter table public.tenants             enable row level security;
alter table public.profiles            enable row level security;
alter table public.students            enable row level security;
alter table public.groups              enable row level security;
alter table public.halls               enable row level security;
alter table public.sessions            enable row level security;
alter table public.attendance          enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.reservations        enable row level security;
alter table public.quizzes             enable row level security;
alter table public.quiz_results        enable row level security;
alter table public.subscriptions       enable row level security;
alter table public.billing_transactions enable row level security;
alter table public.usage_events        enable row level security;
alter table public.invoices              enable row level security;
alter table public.feature_flags       enable row level security;
alter table public.audit_logs          enable row level security;
alter table public.knowledge_cache     enable row level security;
alter table public.reports             enable row level security;
alter table public.health_ping         enable row level security;

-- ---------------------------------------------------------------------------
-- profiles: own row (or supervisor). Role/tenant changes go through RPCs.
-- ---------------------------------------------------------------------------
create policy profiles_select on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_supervisor());

create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = auth.uid() or public.is_supervisor())
  with check (id = auth.uid() or public.is_supervisor());

-- Column hardening: clients may only touch presence/profile copy, never
-- role / tenant / device binding (those are RPC-owned).
revoke update on public.profiles from authenticated;
grant update (display_name, is_online, phone) on public.profiles to authenticated;

-- ---------------------------------------------------------------------------
-- tenants: readable by any signed-in user (branding), writable by supervisor
-- or the centre's own admin.
-- ---------------------------------------------------------------------------
create policy tenants_select on public.tenants
  for select to authenticated
  using (true);

create policy tenants_insert on public.tenants
  for insert to authenticated
  with check (public.is_supervisor());

create policy tenants_update on public.tenants
  for update to authenticated
  using (
    public.is_supervisor()
    or (public.auth_role() = 'centerAdmin' and public.auth_tenant_id() = id)
  )
  with check (
    public.is_supervisor()
    or (public.auth_role() = 'centerAdmin' and public.auth_tenant_id() = id)
  );

-- ---------------------------------------------------------------------------
-- Tenant-scoped operational tables: members read, staff write.
-- ---------------------------------------------------------------------------
create policy students_select on public.students
  for select to authenticated
  using (public.is_tenant_member(tenant_id));

create policy students_write on public.students
  for insert to authenticated
  with check (public.is_tenant_staff(tenant_id));

create policy students_update on public.students
  for update to authenticated
  using (public.is_tenant_staff(tenant_id))
  with check (public.is_tenant_staff(tenant_id));

create policy students_delete on public.students
  for delete to authenticated
  using (public.is_tenant_staff(tenant_id));

create policy groups_select on public.groups
  for select to authenticated
  using (public.is_tenant_member(tenant_id));

create policy groups_write on public.groups
  for all to authenticated
  using (public.is_tenant_staff(tenant_id))
  with check (public.is_tenant_staff(tenant_id));

create policy halls_select on public.halls
  for select to authenticated
  using (public.is_tenant_member(tenant_id));

create policy halls_write on public.halls
  for all to authenticated
  using (public.is_tenant_staff(tenant_id))
  with check (public.is_tenant_staff(tenant_id));

create policy sessions_select on public.sessions
  for select to authenticated
  using (public.is_tenant_member(tenant_id));

create policy sessions_write on public.sessions
  for all to authenticated
  using (public.is_tenant_staff(tenant_id))
  with check (public.is_tenant_staff(tenant_id));

-- Attendance: students may read their own centre's scans; only staff record.
create policy attendance_select on public.attendance
  for select to authenticated
  using (public.is_tenant_member(tenant_id));

create policy attendance_insert on public.attendance
  for insert to authenticated
  with check (public.is_tenant_staff(tenant_id));

create policy attendance_update on public.attendance
  for update to authenticated
  using (public.is_tenant_staff(tenant_id))
  with check (public.is_tenant_staff(tenant_id));

create policy attendance_delete on public.attendance
  for delete to authenticated
  using (public.is_tenant_staff(tenant_id));

-- ---------------------------------------------------------------------------
-- Wallet ledger: staff insert (via RPC), staff may flip status to voided via
-- the void RPC (the wallet_guard trigger restricts what an update can do).
-- No delete policy exists — the ledger is append-only.
-- ---------------------------------------------------------------------------
create policy wallet_select on public.wallet_transactions
  for select to authenticated
  using (public.is_tenant_member(tenant_id));

create policy wallet_insert on public.wallet_transactions
  for insert to authenticated
  with check (public.is_tenant_staff(tenant_id));

create policy wallet_update on public.wallet_transactions
  for update to authenticated
  using (public.is_tenant_staff(tenant_id))
  with check (public.is_tenant_staff(tenant_id));

-- ---------------------------------------------------------------------------
-- Reservations / quizzes / results / cache / reports: member read, staff write.
-- ---------------------------------------------------------------------------
create policy reservations_select on public.reservations
  for select to authenticated
  using (public.is_tenant_member(tenant_id));

create policy reservations_write on public.reservations
  for all to authenticated
  using (public.is_tenant_staff(tenant_id))
  with check (public.is_tenant_staff(tenant_id));

create policy quizzes_select on public.quizzes
  for select to authenticated
  using (public.is_tenant_member(tenant_id));

create policy quizzes_write on public.quizzes
  for all to authenticated
  using (public.is_tenant_staff(tenant_id))
  with check (public.is_tenant_staff(tenant_id));

create policy quiz_results_select on public.quiz_results
  for select to authenticated
  using (public.is_tenant_member(tenant_id));

create policy quiz_results_write on public.quiz_results
  for all to authenticated
  using (public.is_tenant_staff(tenant_id))
  with check (public.is_tenant_staff(tenant_id));

create policy knowledge_cache_select on public.knowledge_cache
  for select to authenticated
  using (public.is_tenant_member(tenant_id));

create policy knowledge_cache_write on public.knowledge_cache
  for all to authenticated
  using (public.is_tenant_staff(tenant_id))
  with check (public.is_tenant_staff(tenant_id));

create policy reports_select on public.reports
  for select to authenticated
  using (public.is_tenant_member(tenant_id));

-- Reports are generated by the weekly edge function (service role).

-- ---------------------------------------------------------------------------
-- Billing: clients read the subscription of their own centre/account;
-- writes are service-role only (no insert/update/delete policies at all).
-- ---------------------------------------------------------------------------
create policy subscriptions_select on public.subscriptions
  for select to authenticated
  using (
    public.is_supervisor()
    or account_id = public.auth_tenant_id()
    or account_id = auth.uid()::text
  );

create policy billing_transactions_select on public.billing_transactions
  for select to authenticated
  using (
    public.is_supervisor()
    or account_id = public.auth_tenant_id()
    or account_id = auth.uid()::text
  );

create policy usage_events_select on public.usage_events
  for select to authenticated
  using (
    public.is_supervisor()
    or account_id = public.auth_tenant_id()
    or account_id = auth.uid()::text
  );

create policy invoices_select on public.invoices
  for select to authenticated
  using (
    public.is_supervisor()
    or account_id = public.auth_tenant_id()
    or account_id = auth.uid()::text
  );

-- ---------------------------------------------------------------------------
-- feature_flags: everyone signed in reads; only supervisor writes (via RPC).
-- ---------------------------------------------------------------------------
create policy feature_flags_select on public.feature_flags
  for select to authenticated
  using (true);

create policy feature_flags_write on public.feature_flags
  for all to authenticated
  using (public.is_supervisor())
  with check (public.is_supervisor());

-- ---------------------------------------------------------------------------
-- audit_logs: tenant members and supervisor read; any tenant member may
-- append; nobody updates or deletes (trigger enforces append-only).
-- ---------------------------------------------------------------------------
create policy audit_logs_select on public.audit_logs
  for select to authenticated
  using (public.is_supervisor() or public.is_tenant_member(tenant_id));

create policy audit_logs_insert on public.audit_logs
  for insert to authenticated
  with check (public.is_supervisor() or public.is_tenant_member(tenant_id));

-- ---------------------------------------------------------------------------
-- health_ping: readable by any signed-in user; written by pg_cron/service.
-- ---------------------------------------------------------------------------
create policy health_ping_select on public.health_ping
  for select to authenticated
  using (true);

-- ---------------------------------------------------------------------------
-- Table privileges. RLS decides rows; grants decide operations.
-- ---------------------------------------------------------------------------
grant select, insert, update, delete on public.tenants to authenticated;
grant select, insert, update, delete on public.students to authenticated;
grant select, insert, update, delete on public.groups to authenticated;
grant select, insert, update, delete on public.halls to authenticated;
grant select, insert, update, delete on public.sessions to authenticated;
grant select, insert, update, delete on public.attendance to authenticated;
grant select, insert, update on public.wallet_transactions to authenticated;
grant select, insert, update, delete on public.reservations to authenticated;
grant select, insert, update, delete on public.quizzes to authenticated;
grant select, insert, update, delete on public.quiz_results to authenticated;
grant select on public.subscriptions to authenticated;
grant select on public.billing_transactions to authenticated;
grant select on public.usage_events to authenticated;
grant select on public.invoices to authenticated;
grant select, insert, update, delete on public.feature_flags to authenticated;
grant select, insert on public.audit_logs to authenticated;
grant select, insert, update, delete on public.knowledge_cache to authenticated;
grant select on public.reports to authenticated;
grant select on public.health_ping to authenticated;
grant select on public.profiles to authenticated;

-- Explicitly remove ledger/audit delete from every client role.
revoke delete on public.wallet_transactions from authenticated, anon;
revoke update, delete on public.audit_logs from authenticated, anon;

-- Service role (edge functions) gets full access; RLS is bypassed for it.
grant all on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to service_role;
