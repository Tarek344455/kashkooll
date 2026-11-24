-- RLS for Installment Plans (Zero-Cost payment flexibility).
-- Least-privilege per role: student, parent, teacher, secretary, admin.

alter table public.installment_plans enable row level security;
alter table public.installment_payments enable row level security;

-- ---------------------------------------------------------------------------
-- installment_plans:
--   - student/parent: read own plans in tenant.
--   - staff: read all plans in tenant; write plans.
-- ---------------------------------------------------------------------------
create policy installment_plans_select on public.installment_plans
  for select to authenticated
  using (
    public.is_tenant_member(tenant_id)
    and (
      public.is_tenant_staff(tenant_id)
      or student_id = (
        select id from public.students s
        where s.user_id = auth.uid() and s.tenant_id = installment_plans.tenant_id
        limit 1
      )
    )
  );

create policy installment_plans_write on public.installment_plans
  for all to authenticated
  using (public.is_tenant_staff(tenant_id))
  with check (public.is_tenant_staff(tenant_id));

-- ---------------------------------------------------------------------------
-- installment_payments:
--   - student/parent: read own payments in tenant.
--   - staff: read all payments in tenant; update to mark paid.
-- ---------------------------------------------------------------------------
create policy installment_payments_select on public.installment_payments
  for select to authenticated
  using (
    public.is_tenant_member(tenant_id)
    and (
      public.is_tenant_staff(tenant_id)
      or student_id = (
        select id from public.students s
        where s.user_id = auth.uid() and s.tenant_id = installment_payments.tenant_id
        limit 1
      )
    )
  );

create policy installment_payments_insert on public.installment_payments
  for insert to authenticated
  with check (
    public.is_tenant_member(tenant_id)
    and public.is_tenant_staff(tenant_id)
  );

create policy installment_payments_update on public.installment_payments
  for update to authenticated
  using (public.is_tenant_staff(tenant_id))
  with check (public.is_tenant_staff(tenant_id));