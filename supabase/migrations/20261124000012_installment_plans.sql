-- Installment Plans (متبقي عليه / تقسيط)
-- Students can pay in installments instead of full amount.
-- Each installment plan links a student to a group/session with total amount
-- split across multiple due dates.

-- ---------------------------------------------------------------------------
-- installment_plans: one active plan per student per group (or overall).
-- ---------------------------------------------------------------------------
create table public.installment_plans (
  id                  text primary key,
  tenant_id           text not null references public.tenants (id) on delete cascade,
  student_id          text not null references public.students (id) on delete cascade,
  group_id            text references public.groups (id) on delete set null,
  total_amount_piasters bigint not null check (total_amount_piasters > 0),
  paid_amount_piasters bigint not null default 0 check (paid_amount_piasters >= 0),
  remaining_piasters  bigint not null check (remaining_piasters >= 0),
  number_of_installments integer not null check (number_of_installments > 0),
  installment_amount_piasters bigint not null check (installment_amount_piasters > 0),
  start_date          date not null,
  end_date            date not null,
  status              text not null default 'active'
                      check (status in ('active', 'completed', 'cancelled', 'overdue')),
  description         text,
  created_by          uuid,                       -- staff who created the plan
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  check (paid_amount_piasters <= total_amount_piasters),
  check (remaining_piasters = total_amount_piasters - paid_amount_piasters)
);

create index installment_plans_tenant_idx on public.installment_plans (tenant_id);
create index installment_plans_student_idx on public.installment_plans (student_id, status);
create index installment_plans_group_idx on public.installment_plans (group_id);

-- ---------------------------------------------------------------------------
-- installment_payments: each individual installment payment within a plan.
-- ---------------------------------------------------------------------------
create table public.installment_payments (
  id                  text primary key,
  plan_id             text not null references public.installment_plans (id) on delete cascade,
  tenant_id           text not null references public.tenants (id) on delete cascade,
  student_id          text not null,
  amount_piasters     bigint not null check (amount_piasters > 0),
  due_date            date not null,
  paid_date           timestamptz,
  status              text not null default 'pending'
                      check (status in ('pending', 'paid', 'overdue', 'cancelled')),
  receipt_url         text,                        -- signed storage URL
  submission_id       text references public.payment_submissions (id) on delete set null,
  note                text not null default '',
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index installment_payments_plan_idx on public.installment_payments (plan_id, status);
create index installment_payments_student_idx on public.installment_payments (student_id, status);
create index installment_payments_due_idx on public.installment_payments (due_date);
create index installment_payments_tenant_idx on public.installment_payments (tenant_id);

-- ---------------------------------------------------------------------------
-- updated_at triggers
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_trigger where tgname = 'touch_updated_at_installment_plans'
  ) then
    create trigger touch_updated_at_installment_plans
      before update on public.installment_plans
      for each row execute function public.touch_updated_at();
  end if;
  if not exists (
    select 1 from pg_trigger where tgname = 'touch_updated_at_installment_payments'
  ) then
    create trigger touch_updated_at_installment_payments
      before update on public.installment_payments
      for each row execute function public.touch_updated_at();
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- RPC: create_installment_plan (staff only).
-- Creates a new installment plan for a student.
-- ---------------------------------------------------------------------------
create or replace function public.create_installment_plan(
  p_student_id text,
  p_group_id text,
  p_total_amount_piasters bigint,
  p_number_of_installments integer,
  p_start_date date,
  p_end_date date,
  p_description text default '',
  p_created_by uuid default null
) returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_tenant text;
  v_installment_amount bigint;
  v_plan_id text := gen_random_uuid()::text;
  v_due_date date;
  v_i integer;
begin
  -- Get tenant from student
  select tenant_id into v_tenant
  from public.students
  where id = p_student_id;

  if not found then
    raise exception 'student % not found', p_student_id using errcode = 'P0002';
  end if;

  -- Check staff authorization
  if not public.is_tenant_staff(v_tenant) then
    raise exception 'not authorized for tenant %', v_tenant using errcode = '42501';
  end if;

  -- Calculate installment amount
  v_installment_amount := ceil(p_total_amount_piasters::numeric / p_number_of_installments)::bigint;

  -- Create the plan
  insert into public.installment_plans
    (id, tenant_id, student_id, group_id, total_amount_piasters,
     paid_amount_piasters, remaining_piasters, number_of_installments,
     installment_amount_piasters, start_date, end_date, description,
     created_by, status)
  values
    (v_plan_id, v_tenant, p_student_id, p_group_id, p_total_amount_piasters,
     0, p_total_amount_piasters, p_number_of_installments,
     v_installment_amount, p_start_date, p_end_date, p_description,
     coalesce(p_created_by, auth.uid()), 'active');

  -- Generate individual installment payments
  v_due_date := p_start_date;
  for v_i in 1..p_number_of_installments loop
    insert into public.installment_payments
      (id, plan_id, tenant_id, student_id, amount_piasters,
       due_date, status, created_at, updated_at)
    values
      (gen_random_uuid()::text, v_plan_id, v_tenant, p_student_id,
       v_installment_amount, v_due_date, 'pending', now(), now());

    v_due_date := v_due_date + interval '1 month';
  end loop;

  return jsonb_build_object(
    'ok', true,
    'planId', v_plan_id,
    'totalAmountPiasters', p_total_amount_piasters,
    'installmentAmountPiasters', v_installment_amount,
    'numberOfInstallments', p_number_of_installments
  );
end
$$;

grant execute on function public.create_installment_plan(text, text, bigint, integer, date, date, text, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: record_installment_payment (staff only).
-- Records payment for a specific installment and updates plan totals.
-- ---------------------------------------------------------------------------
create or replace function public.record_installment_payment(
  p_payment_id text,
  p_amount_piasters bigint,
  p_submission_id text default null,
  p_reviewer_uid uuid default null,
  p_note text default ''
) returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_payment public.installment_payments;
  v_plan public.installment_plans;
  v_new_paid bigint;
  v_new_remaining bigint;
begin
  -- Lock the payment row
  select * into v_payment
  from public.installment_payments
  where id = p_payment_id
  for update;

  if not found then
    raise exception 'installment payment % not found', p_payment_id using errcode = 'P0002';
  end if;

  if v_payment.status <> 'pending' then
    raise exception 'installment % already %', p_payment_id, v_payment.status using errcode = '23514';
  end if;

  -- Lock the plan row
  select * into v_plan
  from public.installment_plans
  where id = v_payment.plan_id
  for update;

  -- Check staff authorization
  if not public.is_tenant_staff(v_plan.tenant_id) then
    raise exception 'not authorized for tenant %', v_plan.tenant_id using errcode = '42501';
  end if;

  -- Update the installment payment
  update public.installment_payments
  set status = 'paid',
      paid_date = now(),
      submission_id = coalesce(p_submission_id, submission_id),
      note = coalesce(nullif(p_note, ''), note),
      updated_at = now()
  where id = p_payment_id;

  -- Update plan totals
  v_new_paid := v_plan.paid_amount_piasters + p_amount_piasters;
  v_new_remaining := v_plan.remaining_piasters - p_amount_piasters;

  update public.installment_plans
  set paid_amount_piasters = v_new_paid,
      remaining_piasters = v_new_remaining,
      status = case
        when v_new_remaining <= 0 then 'completed'
        else 'active'
      end,
      updated_at = now()
  where id = v_plan.id;

  return jsonb_build_object(
    'ok', true,
    'paymentId', p_payment_id,
    'planId', v_plan.id,
    'status', 'paid',
    'paidAmountPiasters', v_new_paid,
    'remainingPiasters', v_new_remaining,
    'planCompleted', v_new_remaining <= 0
  );
end
$$;

grant execute on function public.record_installment_payment(text, bigint, text, uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- Table privileges
-- ---------------------------------------------------------------------------
grant select, insert, update, delete on public.installment_plans to authenticated;
grant select, insert, update on public.installment_payments to authenticated;