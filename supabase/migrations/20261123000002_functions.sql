-- Kashkool triggers, guards and atomic RPCs.
-- Everything money-related runs through these functions so the ledger stays
-- immutable, idempotent and anti-fraud checked no matter which client writes.

-- ---------------------------------------------------------------------------
-- Identity helpers used by RLS. SECURITY DEFINER + fixed search_path so the
-- profile lookup bypasses RLS on profiles without recursion.
-- ---------------------------------------------------------------------------
create or replace function public.auth_role() returns text
language sql stable security definer set search_path = public
as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.auth_tenant_id() returns text
language sql stable security definer set search_path = public
as $$
  select tenant_id from public.profiles where id = auth.uid()
$$;

create or replace function public.is_supervisor() returns boolean
language sql stable security definer set search_path = public
as $$
  select coalesce(public.auth_role() = 'supervisor', false)
$$;

create or replace function public.is_tenant_member(p_tenant_id text) returns boolean
language sql stable security definer set search_path = public
as $$
  select auth.role() = 'service_role'
      or coalesce(public.auth_role() = 'supervisor', false)
      or public.auth_tenant_id() = p_tenant_id
$$;

create or replace function public.is_tenant_staff(p_tenant_id text) returns boolean
language sql stable security definer set search_path = public
as $$
  select auth.role() = 'service_role'
      or coalesce(public.auth_role() = 'supervisor', false)
      or (
        public.auth_tenant_id() = p_tenant_id
        and public.auth_role() in ('centerAdmin', 'assistant', 'teacher')
      )
$$;

-- ---------------------------------------------------------------------------
-- updated_at maintenance.
-- ---------------------------------------------------------------------------
create or replace function public.touch_updated_at() returns trigger
language plpgsql set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end
$$;

do $$
declare
  t text;
begin
  foreach t in array array[
    'tenants', 'profiles', 'students', 'groups', 'halls', 'sessions',
    'attendance', 'reservations', 'quizzes', 'quiz_results', 'subscriptions'
  ]
  loop
    execute format(
      'create trigger touch_updated_at before update on public.%I
       for each row execute function public.touch_updated_at()', t
    );
  end loop;
end
$$;

-- ---------------------------------------------------------------------------
-- Profile bootstrap: every new auth user gets a profile (role student,
-- unassigned tenant) — derived from the profiles table on every request.
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, phone)
  values (new.id, new.phone)
  on conflict (id) do nothing;
  return new;
end
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Wallet ledger guards.
-- ---------------------------------------------------------------------------

-- Validates the student and void references before a ledger row lands.
create or replace function public.wallet_validate() returns trigger
language plpgsql set search_path = public
as $$
declare
  v_target public.wallet_transactions;
begin
  if not exists (
    select 1 from public.students
    where id = new.student_id and tenant_id = new.tenant_id
  ) then
    raise exception 'student % not found in tenant %', new.student_id, new.tenant_id
      using errcode = 'P0002';
  end if;

  if new.kind = 'void' then
    select * into v_target
    from public.wallet_transactions
    where id = new.voids_transaction_id;

    if not found then
      raise exception 'void target % does not exist', new.voids_transaction_id
        using errcode = 'P0002';
    end if;
    if v_target.tenant_id <> new.tenant_id then
      raise exception 'void target belongs to another tenant' using errcode = '42501';
    end if;
    if v_target.status <> 'completed' then
      raise exception 'void target is not completed' using errcode = '23514';
    end if;
    if new.amount_piasters <> -v_target.amount_piasters then
      raise exception 'void amount must reverse the original exactly' using errcode = '23514';
    end if;
  end if;

  return new;
end
$$;

create trigger wallet_validate
  before insert on public.wallet_transactions
  for each row execute function public.wallet_validate();

-- Append-only: deletes are forbidden; the only legal update is the
-- completed -> voided status flip, and only once a compensating void row
-- exists. Every other column must stay byte-identical.
create or replace function public.wallet_guard() returns trigger
language plpgsql set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'wallet ledger is append-only: use void_wallet_transaction()'
      using errcode = '42501';
  end if;

  if old.status = 'completed'
     and new.status = 'voided'
     and (to_jsonb(new) - 'status') = (to_jsonb(old) - 'status')
     and exists (
       select 1 from public.wallet_transactions v
       where v.voids_transaction_id = old.id and v.kind = 'void'
     )
  then
    return new;
  end if;

  raise exception 'wallet ledger is immutable: corrections require a void/refund entry'
    using errcode = '42501';
end
$$;

create trigger wallet_guard
  before update or delete on public.wallet_transactions
  for each row execute function public.wallet_guard();

-- Keeps students.wallet_balance_piasters in lockstep with the ledger.
create or replace function public.wallet_apply_balance() returns trigger
language plpgsql set search_path = public
as $$
begin
  if tg_op = 'INSERT' and new.status = 'completed' then
    update public.students
    set wallet_balance_piasters = wallet_balance_piasters + new.amount_piasters
    where id = new.student_id and tenant_id = new.tenant_id;
  elsif tg_op = 'UPDATE' and old.status = 'completed' and new.status = 'voided' then
    update public.students
    set wallet_balance_piasters = wallet_balance_piasters - old.amount_piasters
    where id = old.student_id and tenant_id = old.tenant_id;
  end if;
  return null;
end
$$;

create trigger wallet_apply_balance
  after insert or update of status on public.wallet_transactions
  for each row execute function public.wallet_apply_balance();

-- Audit trail is append-only too.
create or replace function public.audit_append_only() returns trigger
language plpgsql set search_path = public
as $$
begin
  raise exception 'audit_logs is append-only' using errcode = '42501';
end
$$;

create trigger audit_append_only
  before update or delete on public.audit_logs
  for each row execute function public.audit_append_only();

-- ---------------------------------------------------------------------------
-- RPC: attendance scan (idempotent, 1-tap secretary flow).
-- ---------------------------------------------------------------------------
create or replace function public.record_attendance(
  p_id text,
  p_tenant_id text,
  p_student_id text,
  p_session_id text,
  p_idempotency_key text,
  p_scanned_at timestamptz default now()
) returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_row public.attendance;
begin
  if not public.is_tenant_staff(p_tenant_id) then
    raise exception 'not authorized for tenant %', p_tenant_id using errcode = '42501';
  end if;

  insert into public.attendance as a
    (id, tenant_id, student_id, session_id, idempotency_key, scanned_at, recorded_by)
  values
    (p_id, p_tenant_id, p_student_id, p_session_id, p_idempotency_key, p_scanned_at, auth.uid())
  on conflict (tenant_id, session_id, student_id) do update set
    scanned_at = excluded.scanned_at,
    status = 'present',
    updated_at = now()
  returning * into v_row;

  return to_jsonb(v_row);
end
$$;

-- ---------------------------------------------------------------------------
-- RPC: wallet entry (staff only, idempotent, validated).
-- ---------------------------------------------------------------------------
create or replace function public.record_wallet_transaction(
  p_id text,
  p_tenant_id text,
  p_student_id text,
  p_amount_piasters bigint,
  p_kind text default 'topup',
  p_channel text default 'cash',
  p_reference_id text default null,
  p_idempotency_key text default null,
  p_note text default ''
) returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_row public.wallet_transactions;
  v_key text;
begin
  if not public.is_tenant_staff(p_tenant_id) then
    raise exception 'not authorized for tenant %', p_tenant_id using errcode = '42501';
  end if;
  if p_amount_piasters = 0 then
    raise exception 'amount must be non-zero' using errcode = '23514';
  end if;

  v_key := coalesce(p_idempotency_key, p_id);

  insert into public.wallet_transactions
    (id, tenant_id, student_id, amount_piasters, kind, channel,
     reference_id, idempotency_key, note, created_by)
  values
    (p_id, p_tenant_id, p_student_id, p_amount_piasters, p_kind, p_channel,
     p_reference_id, v_key, p_note, auth.uid())
  on conflict (idempotency_key) do nothing
  returning * into v_row;

  if v_row.id is null then
    select * into v_row
    from public.wallet_transactions
    where idempotency_key = v_key;
  end if;

  return to_jsonb(v_row);
end
$$;

-- ---------------------------------------------------------------------------
-- RPC: formal void (immutable correction + audit + owner alert payload).
-- ---------------------------------------------------------------------------
create or replace function public.void_wallet_transaction(
  p_tenant_id text,
  p_transaction_id text,
  p_reason text default ''
) returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_original public.wallet_transactions;
  v_void public.wallet_transactions;
begin
  if not public.is_tenant_staff(p_tenant_id) then
    raise exception 'not authorized for tenant %', p_tenant_id using errcode = '42501';
  end if;

  select * into v_original
  from public.wallet_transactions
  where id = p_transaction_id and tenant_id = p_tenant_id;

  if not found then
    raise exception 'transaction % not found', p_transaction_id using errcode = 'P0002';
  end if;

  -- Already voided: return the existing compensating entry (idempotent).
  if v_original.status = 'voided' then
    select * into v_void
    from public.wallet_transactions
    where voids_transaction_id = v_original.id and kind = 'void'
    limit 1;
    return to_jsonb(v_void);
  end if;

  if v_original.status <> 'completed' then
    raise exception 'only completed transactions can be voided' using errcode = '23514';
  end if;

  insert into public.wallet_transactions
    (id, tenant_id, student_id, amount_piasters, kind, channel,
     reference_id, idempotency_key, voids_transaction_id, note, created_by)
  values
    (p_transaction_id || '-void', p_tenant_id, v_original.student_id,
     -v_original.amount_piasters, 'void', v_original.channel,
     v_original.reference_id, 'void:' || p_transaction_id,
     p_transaction_id, p_reason, auth.uid())
  on conflict (idempotency_key) do nothing
  returning * into v_void;

  if v_void.id is null then
    select * into v_void
    from public.wallet_transactions
    where idempotency_key = 'void:' || p_transaction_id;
  else
    update public.wallet_transactions
    set status = 'voided'
    where id = p_transaction_id;
  end if;

  insert into public.audit_logs (tenant_id, action, details, actor_uid, severity, payload)
  values (
    p_tenant_id,
    'wallet.voided',
    coalesce(nullif(p_reason, ''), 'Transaction voided by staff.'),
    coalesce(auth.uid()::text, 'system'),
    'high',
    jsonb_build_object('transactionId', p_transaction_id, 'voidId', v_void.id)
  );

  return to_jsonb(v_void);
end
$$;

-- ---------------------------------------------------------------------------
-- RPC: hardware binding, stored on the student/profile row.
-- SECURITY DEFINER: the binding column must not be client-writable directly.
-- ---------------------------------------------------------------------------
create or replace function public.bind_device(
  p_tenant_id text,
  p_fingerprint text
) returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_student public.students;
begin
  if auth.uid() is null then
    raise exception 'unauthenticated' using errcode = '28000';
  end if;

  select * into v_student
  from public.students
  where user_id = auth.uid() and tenant_id = p_tenant_id
  limit 1;

  if not found then
    return jsonb_build_object('status', 'not_linked');
  end if;

  -- Web sessions carry an empty fingerprint by design (no stable hardware id).
  if coalesce(p_fingerprint, '') = '' then
    return jsonb_build_object('status', 'ok', 'studentId', v_student.id);
  end if;

  if v_student.bound_device_id is null or v_student.bound_device_id = '' then
    update public.students
    set bound_device_id = p_fingerprint, device_bound_at = now()
    where id = v_student.id;
    return jsonb_build_object('status', 'ok', 'studentId', v_student.id);
  end if;

  if v_student.bound_device_id <> p_fingerprint then
    return jsonb_build_object('status', 'locked');
  end if;

  return jsonb_build_object('status', 'ok', 'studentId', v_student.id);
end
$$;

-- ---------------------------------------------------------------------------
-- RPC: enrol a student (staff). Links an existing auth profile by phone.
-- ---------------------------------------------------------------------------
create or replace function public.enroll_student(
  p_tenant_id text,
  p_student_id text,
  p_name text,
  p_phone text,
  p_group_id text default null
) returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_profile public.profiles;
  v_student public.students;
begin
  if not public.is_tenant_staff(p_tenant_id) then
    raise exception 'not authorized for tenant %', p_tenant_id using errcode = '42501';
  end if;

  select * into v_profile
  from public.profiles
  where phone = p_phone and tenant_id is null
  limit 1;

  insert into public.students as s
    (id, tenant_id, user_id, name, phone, group_id)
  values
    (p_student_id, p_tenant_id, v_profile.id, p_name, p_phone, p_group_id)
  on conflict (id) do update set
    name = excluded.name,
    phone = excluded.phone,
    group_id = coalesce(excluded.group_id, s.group_id),
    user_id = coalesce(excluded.user_id, s.user_id),
    updated_at = now()
  returning * into v_student;

  if v_profile.id is not null then
    update public.profiles
    set tenant_id = p_tenant_id, role = 'student'
    where id = v_profile.id;
  end if;

  return to_jsonb(v_student);
end
$$;

-- ---------------------------------------------------------------------------
-- RPC: platform switches (supervisor only) + audit.
-- ---------------------------------------------------------------------------
create or replace function public.set_flag(p_key text, p_enabled boolean) returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_row public.feature_flags;
begin
  if not public.is_supervisor() then
    raise exception 'supervisor role required' using errcode = '42501';
  end if;

  insert into public.feature_flags as f (key, enabled)
  values (p_key, p_enabled)
  on conflict (key) do update set
    enabled = excluded.enabled,
    updated_at = now()
  returning * into v_row;

  insert into public.audit_logs (tenant_id, action, details, actor_uid, severity)
  values (
    '', 'flag.changed',
    'Flag "' || p_key || '" set to ' || p_enabled::text,
    coalesce(auth.uid()::text, 'system'),
    case when p_key = 'global_emergency' and p_enabled then 'high' else 'medium' end
  );

  return to_jsonb(v_row);
end
$$;

-- ---------------------------------------------------------------------------
-- RPC: tenant lifecycle (supervisor only) + audit.
-- ---------------------------------------------------------------------------
create or replace function public.create_tenant(
  p_tenant_id text,
  p_name text,
  p_subdomain text default '',
  p_accent_color text default '#00E5FF',
  p_primary_color text default '#0B1020'
) returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_row public.tenants;
begin
  if not public.is_supervisor() then
    raise exception 'supervisor role required' using errcode = '42501';
  end if;

  insert into public.tenants (id, name, subdomain, accent_color, primary_color, subscription_expires_at)
  values (p_tenant_id, p_name, p_subdomain, p_accent_color, p_primary_color, now() + interval '30 days')
  returning * into v_row;

  insert into public.audit_logs (tenant_id, action, details, actor_uid)
  values (
    p_tenant_id, 'tenant.created',
    'Centre "' || p_name || '" created with subdomain "' || p_subdomain || '".',
    coalesce(auth.uid()::text, 'system')
  );

  return to_jsonb(v_row);
end
$$;

create or replace function public.set_tenant_active(
  p_tenant_id text,
  p_active boolean,
  p_reason text default ''
) returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_row public.tenants;
begin
  if not public.is_supervisor() then
    raise exception 'supervisor role required' using errcode = '42501';
  end if;

  update public.tenants
  set is_active = p_active,
      frozen_at = case when p_active then frozen_at else now() end,
      unfrozen_at = case when p_active then now() else unfrozen_at end
  where id = p_tenant_id
  returning * into v_row;

  if not found then
    raise exception 'tenant % not found', p_tenant_id using errcode = 'P0002';
  end if;

  insert into public.audit_logs (tenant_id, action, details, actor_uid, severity)
  values (
    p_tenant_id,
    case when p_active then 'tenant.unfrozen' else 'tenant.frozen' end,
    coalesce(nullif(p_reason, ''),
      case when p_active then 'Centre reactivated by support.' else 'Centre frozen by support.' end),
    coalesce(auth.uid()::text, 'system'),
    case when p_active then 'medium' else 'high' end
  );

  return to_jsonb(v_row);
end
$$;

create or replace function public.update_tenant_subscription(
  p_tenant_id text,
  p_tier text,
  p_expires_at timestamptz
) returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_row public.tenants;
begin
  if not public.is_supervisor() then
    raise exception 'supervisor role required' using errcode = '42501';
  end if;

  update public.tenants
  set subscription_tier = p_tier, subscription_expires_at = p_expires_at
  where id = p_tenant_id
  returning * into v_row;

  if not found then
    raise exception 'tenant % not found', p_tenant_id using errcode = 'P0002';
  end if;

  insert into public.audit_logs (tenant_id, action, details, actor_uid)
  values (
    p_tenant_id, 'subscription.updated',
    'Tier set to "' || p_tier || '" until ' || p_expires_at::text,
    coalesce(auth.uid()::text, 'system')
  );

  return to_jsonb(v_row);
end
$$;

-- ---------------------------------------------------------------------------
-- RPC: usage metering (service role / supervisor). Atomic jsonb increment.
-- ---------------------------------------------------------------------------
create or replace function public.increment_usage(
  p_account_id text,
  p_meter_key text,
  p_quantity integer
) returns bigint
language plpgsql security invoker set search_path = public
as $$
declare
  v_total bigint;
begin
  if not (public.is_supervisor() or auth.role() = 'service_role') then
    raise exception 'service role or supervisor required' using errcode = '42501';
  end if;
  if p_quantity <= 0 then
    raise exception 'quantity must be positive' using errcode = '23514';
  end if;

  update public.subscriptions
  set usage_counters = jsonb_set(
        usage_counters,
        array[p_meter_key],
        to_jsonb(coalesce((usage_counters ->> p_meter_key)::bigint, 0) + p_quantity)
      ),
      updated_at = now()
  where account_id = p_account_id
  returning (usage_counters ->> p_meter_key)::bigint into v_total;

  if not found then
    raise exception 'subscription for % not found', p_account_id using errcode = 'P0002';
  end if;

  insert into public.usage_events (account_id, meter_key, quantity)
  values (p_account_id, p_meter_key, p_quantity);

  return v_total;
end
$$;

-- ---------------------------------------------------------------------------
-- RPC: subscription activation (service role only — billing webhooks).
-- ---------------------------------------------------------------------------
create or replace function public.apply_subscription(
  p_account_id text,
  p_account_type text,
  p_modules text[],
  p_billing_cycle text,
  p_promo_code text default null,
  p_expires_at timestamptz default null
) returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_row public.subscriptions;
  v_expiry timestamptz;
begin
  if auth.role() <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;

  v_expiry := coalesce(
    p_expires_at,
    now() + case when p_billing_cycle = 'yearly' then interval '365 days' else interval '30 days' end
  );

  insert into public.subscriptions as s
    (account_id, account_type, active_modules, billing_cycle, promo_code, expires_at)
  values
    (p_account_id, p_account_type, p_modules, p_billing_cycle, p_promo_code, v_expiry)
  on conflict (account_id) do update set
    account_type = excluded.account_type,
    active_modules = excluded.active_modules,
    billing_cycle = excluded.billing_cycle,
    promo_code = coalesce(excluded.promo_code, s.promo_code),
    expires_at = excluded.expires_at,
    updated_at = now()
  returning * into v_row;

  update public.tenants
  set active_modules = p_modules,
      subscription_tier = case when cardinality(p_modules) > 0 then 'paid' else 'free' end,
      subscription_expires_at = v_expiry
  where id = p_account_id;

  insert into public.audit_logs (tenant_id, action, details, actor_uid)
  values (
    p_account_id, 'subscription.activated',
    'Activated modules: ' || array_to_string(p_modules, ', '),
    'system'
  );

  return to_jsonb(v_row);
end
$$;

-- ---------------------------------------------------------------------------
-- RPC: platform metrics for the admin command centre (supervisor only).
-- ---------------------------------------------------------------------------
create or replace function public.platform_metrics() returns jsonb
language plpgsql stable security invoker set search_path = public
as $$
declare
  v_result jsonb;
begin
  if not public.is_supervisor() then
    raise exception 'supervisor role required' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'activeTenants', (select count(*) from public.tenants where is_active),
    'frozenTenants', (select count(*) from public.tenants where not is_active),
    'totalStudents', (select count(*) from public.students),
    'activeStudents', (select count(*) from public.students where is_online),
    'liveSessions', (select count(*) from public.sessions where is_active),
    'pendingAlerts', (select count(*) from public.audit_logs where severity = 'high')
  ) into v_result;

  return v_result;
end
$$;

-- ---------------------------------------------------------------------------
-- RPC: governorate activity map (supervisor only).
-- ---------------------------------------------------------------------------
create or replace function public.sessions_by_governorate() returns jsonb
language sql stable security invoker set search_path = public
as $$
  select coalesce(jsonb_object_agg(governorate, cnt), '{}'::jsonb)
  from (
    select lower(trim(governorate)) as governorate, count(*) as cnt
    from public.sessions
    where is_active and trim(governorate) <> '' and public.is_supervisor()
    group by lower(trim(governorate))
  ) s
$$;

-- ---------------------------------------------------------------------------
-- Execute grants. Client-facing RPCs go to authenticated; service-only RPCs
-- stay revoked from everyone except service_role (which bypasses RLS).
-- ---------------------------------------------------------------------------
grant execute on function public.record_attendance(text, text, text, text, text, timestamptz) to authenticated;
grant execute on function public.record_wallet_transaction(text, text, text, bigint, text, text, text, text, text) to authenticated;
grant execute on function public.void_wallet_transaction(text, text, text) to authenticated;
grant execute on function public.bind_device(text, text) to authenticated;
grant execute on function public.enroll_student(text, text, text, text, text) to authenticated;
grant execute on function public.set_flag(text, boolean) to authenticated;
grant execute on function public.create_tenant(text, text, text, text, text) to authenticated;
grant execute on function public.set_tenant_active(text, boolean, text) to authenticated;
grant execute on function public.update_tenant_subscription(text, text, timestamptz) to authenticated;
grant execute on function public.platform_metrics() to authenticated;
grant execute on function public.sessions_by_governorate() to authenticated;
grant execute on function public.increment_usage(text, text, integer) to authenticated, service_role;
grant execute on function public.apply_subscription(text, text, text[], text, text, timestamptz) to service_role;

revoke execute on function public.apply_subscription(text, text, text[], text, text, timestamptz) from public, anon, authenticated;
revoke execute on function public.increment_usage(text, text, integer) from public, anon;
