-- Atomic billing operations. A payment webhook must never leave a transaction
-- recorded without the subscription it paid for (or vice versa).

-- One invoice per account, type and billing period (idempotent monthly jobs).
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'invoices_account_period_key' and conrelid = 'public.invoices'::regclass
  ) then
    alter table public.invoices
      add constraint invoices_account_period_key unique (account_id, type, period_start);
  end if;
end
$$;

-- Applies a verified subscription payment in one transaction:
-- billing_transactions row + subscription row + tenant branding/tier + audit.
create or replace function public.process_subscription_payment(
  p_account_id text,
  p_account_type text,
  p_modules text[],
  p_billing_cycle text,
  p_promo_code text,
  p_payment_method text,
  p_amount_piasters bigint,
  p_transaction_id text,
  p_expires_at timestamptz,
  p_metadata jsonb default '{}'
) returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_existing public.billing_transactions;
  v_tx public.billing_transactions;
  v_expiry timestamptz;
begin
  if auth.role() <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;

  -- Idempotency: replaying a provider webhook returns the first result.
  select * into v_existing
  from public.billing_transactions
  where id = p_transaction_id;
  if found then
    return jsonb_build_object('status', 'already_processed', 'transaction', to_jsonb(v_existing));
  end if;

  v_expiry := coalesce(
    p_expires_at,
    now() + case when p_billing_cycle = 'yearly' then interval '365 days' else interval '30 days' end
  );

  insert into public.billing_transactions
    (id, account_id, account_type, modules, billing_cycle, promo_code,
     payment_method, amount_piasters, currency, status, metadata)
  values
    (p_transaction_id, p_account_id, p_account_type, p_modules, p_billing_cycle,
     p_promo_code, p_payment_method, p_amount_piasters, 'EGP', 'completed', p_metadata)
  returning * into v_tx;

  perform public.apply_subscription(
    p_account_id, p_account_type, p_modules, p_billing_cycle, p_promo_code, v_expiry
  );

  return jsonb_build_object('status', 'processed', 'transaction', to_jsonb(v_tx));
end
$$;

-- Daily subscription expiry sweep (called by the edge function / pg_cron).
create or replace function public.expire_subscriptions() returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_expired integer := 0;
  v_record record;
begin
  if auth.role() <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;

  for v_record in
    select account_id from public.subscriptions
    where expires_at is not null and expires_at < now() and cardinality(active_modules) > 0
  loop
    update public.subscriptions
    set active_modules = '{}', updated_at = now()
    where account_id = v_record.account_id;

    update public.tenants
    set active_modules = '{}', subscription_tier = 'free', updated_at = now()
    where id = v_record.account_id;

    insert into public.audit_logs (tenant_id, action, details, actor_uid, severity)
    values (
      v_record.account_id, 'subscription.expired',
      'Subscription expired; paid modules deactivated.',
      'system', 'medium'
    );

    v_expired := v_expired + 1;
  end loop;

  return jsonb_build_object('expired', v_expired);
end
$$;

grant execute on function public.process_subscription_payment(text, text, text[], text, text, text, bigint, text, timestamptz, jsonb) to service_role;
grant execute on function public.expire_subscriptions() to service_role;
revoke execute on function public.process_subscription_payment(text, text, text[], text, text, text, bigint, text, timestamptz, jsonb) from public, anon, authenticated;
revoke execute on function public.expire_subscriptions() from public, anon, authenticated;
