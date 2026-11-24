-- RLS for Payment Channels & Receipt Submission Lifecycle.
-- Least-privilege per role: student, parent, teacher, secretary, admin.

alter table public.payment_channels enable row level security;
alter table public.payment_submissions enable row level security;
alter table public.ledger_entries enable row level security;

-- ---------------------------------------------------------------------------
-- payment_channels: everyone in tenant reads; staff in tenant writes.
-- ---------------------------------------------------------------------------
create policy payment_channels_select on public.payment_channels
  for select to authenticated
  using (public.is_tenant_member(tenant_id));

create policy payment_channels_write on public.payment_channels
  for all to authenticated
  using (public.is_tenant_staff(tenant_id))
  with check (public.is_tenant_staff(tenant_id));

-- ---------------------------------------------------------------------------
-- payment_submissions:
--   - student/parent: read own submissions in tenant.
--   - staff: read all in tenant; insert own pending submissions; update only
--     to flip pending->approved/rejected via the RPCs (this policy guards the
--     row, but the RPCs enforce the real transitions).
-- ---------------------------------------------------------------------------
create policy payment_submissions_select on public.payment_submissions
  for select to authenticated
  using (
    public.is_tenant_member(tenant_id)
    and (public.is_tenant_staff(tenant_id) or student_id = (
      select id from public.students s
      where s.user_id = auth.uid() and s.tenant_id = payment_submissions.tenant_id
      limit 1
    ))
  );

create policy payment_submissions_insert on public.payment_submissions
  for insert to authenticated
  with check (
    public.is_tenant_member(tenant_id)
    and student_id = (
      select id from public.students s
      where s.user_id = auth.uid() and s.tenant_id = payment_submissions.tenant_id
      limit 1
    )
    and status = 'pending'
  );

create policy payment_submissions_update on public.payment_submissions
  for update to authenticated
  using (public.is_tenant_staff(tenant_id))
  with check (public.is_tenant_staff(tenant_id));

-- ---------------------------------------------------------------------------
-- ledger_entries: append-only. Everyone in tenant reads; staff inserts via
-- RPC. No update/delete policies (trigger enforces append-only).
-- ---------------------------------------------------------------------------
create policy ledger_entries_select on public.ledger_entries
  for select to authenticated
  using (public.is_tenant_member(tenant_id));

create policy ledger_entries_insert on public.ledger_entries
  for insert to authenticated
  with check (public.is_tenant_staff(tenant_id));

-- ---------------------------------------------------------------------------
-- Table privileges.
-- ---------------------------------------------------------------------------
grant select on public.payment_channels to authenticated;
grant select, insert on public.payment_submissions to authenticated;
grant select on public.ledger_entries to authenticated;
