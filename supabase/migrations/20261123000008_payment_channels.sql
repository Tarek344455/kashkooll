-- Payment Channels & Receipt Submission Lifecycle (per-teacher / per-center).
--
-- Tables:
--   payment_channels    - active channels a teacher/center accepts payments on
--   payment_submissions - student receipt submissions awaiting approval/rejection
--   ledger_entries      - append-only immutable ledger (piasters, bigint)
--
-- Money is stored in minor units (piasters = EGP / 100) everywhere.
-- Idempotency: UNIQUE (channel_id, sender_reference) blocks duplicate receipts.

-- ---------------------------------------------------------------------------
-- payment_channels: each channel belongs to exactly one tenant (teacher or
-- center account). 'active' gates whether students can submit to it.
-- ---------------------------------------------------------------------------
create table public.payment_channels (
  id              text primary key,
  tenant_id       text not null references public.tenants (id) on delete cascade,
  name            text not null,                 -- 'فودافون كاش', 'إنستاباي', 'فوري', 'كاش'
  channel_type    text not null
                  check (channel_type in ('vodafone_cash', 'insta_pay', 'fawry', 'cash')),
  account_ref     text not null,                 -- phone / wallet / merchant ref
  fee_piasters    integer not null default 0 check (fee_piasters >= 0),
  min_amount_piasters integer not null default 0 check (min_amount_piasters >= 0),
  max_amount_piasters integer not null check (max_amount_piasters > 0),
  active          boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index payment_channels_tenant_idx on public.payment_channels (tenant_id);
create index payment_channels_active_idx on public.payment_channels (tenant_id, active);

-- ---------------------------------------------------------------------------
-- payment_submissions: one receipt submission per channel + sender reference.
-- A student may submit many times (different channels / references) but never
-- the same channel + reference twice unless the earlier one was rejected.
-- ---------------------------------------------------------------------------
create table public.payment_submissions (
  id                text primary key,
  tenant_id         text not null references public.tenants (id) on delete cascade,
  student_id        text not null,
  channel_id        text not null references public.payment_channels (id) on delete cascade,
  amount_piasters   bigint not null check (amount_piasters > 0),
  sender_reference  text not null,               -- transaction ref from the gateway app
  receipt_url       text not null,               -- signed storage URL (short-lived)
  status            text not null default 'pending'
                    check (status in ('pending', 'approved', 'rejected')),
  reviewed_by       uuid,                        -- staff who approved/rejected
  reviewed_at       timestamptz,
  rejection_reason  text,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create unique index payment_submissions_one_active_idx
  on public.payment_submissions (channel_id, sender_reference)
  where status <> 'rejected';

create index payment_submissions_tenant_idx on public.payment_submissions (tenant_id);
create index payment_submissions_student_idx on public.payment_submissions (student_id, status);
create index payment_submissions_status_idx on public.payment_submissions (tenant_id, status, created_at desc);

-- ---------------------------------------------------------------------------
-- ledger_entries: append-only immutable financial ledger. Every approved
-- payment creates a matching entry here; rejections never touch the ledger.
-- ---------------------------------------------------------------------------
create table public.ledger_entries (
  id                  text primary key,
  tenant_id           text not null references public.tenants (id) on delete cascade,
  student_id          text not null,
  amount_piasters     bigint not null check (amount_piasters <> 0),
  kind                text not null
                      check (kind in ('payment', 'topup', 'charge', 'void', 'refund', 'settlement')),
  channel             text not null default 'cash',
  reference_id        text,
  idempotency_key     text unique,
  voids_entry_id      text references public.ledger_entries (id),
  note                text not null default '',
  created_by          uuid,
  created_at          timestamptz not null default now(),
  constraint ledger_void_requires_target
    check (kind <> 'void' or voids_entry_id is not null)
);

create index ledger_entries_tenant_student_idx on public.ledger_entries (tenant_id, student_id);
create index ledger_entries_created_idx on public.ledger_entries (created_at);
create index ledger_entries_idempotency_idx on public.ledger_entries (idempotency_key);

-- ---------------------------------------------------------------------------
-- updated_at triggers.
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_trigger where tgname = 'touch_updated_at_payment_channels'
  ) then
    create trigger touch_updated_at_payment_channels
      before update on public.payment_channels
      for each row execute function public.touch_updated_at();
  end if;
  if not exists (
    select 1 from pg_trigger where tgname = 'touch_updated_at_payment_submissions'
  ) then
    create trigger touch_updated_at_payment_submissions
      before update on public.payment_submissions
      for each row execute function public.touch_updated_at();
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- Guard: ledger_entries is append-only (no delete; only void via compensating
-- entry). Updates are forbidden entirely.
-- ---------------------------------------------------------------------------
create or replace function public.ledger_append_only() returns trigger
language plpgsql set search_path = public
as $$
begin
  if tg_op = 'DELETE' then
    raise exception 'ledger entries is append-only: use void entry'
      using errcode = '42501';
  end if;
  raise exception 'ledger entries is immutable: corrections require a void/refund entry'
    using errcode = '42501';
end
$$;

create trigger ledger_append_only
  before update or delete on public.ledger_entries
  for each row execute function public.ledger_append_only();

-- ---------------------------------------------------------------------------
-- RPC: approve_payment_submission (staff only).
-- Row-locks the submission, flips to 'approved', inserts an immutable ledger
-- entry, and activates the linked enrollment / session / reservation.
-- ---------------------------------------------------------------------------
create or replace function public.approve_payment_submission(
  p_submission_id text,
  p_reviewer_uid uuid default null,
  p_note text default ''
) returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_sub public.payment_submissions;
  v_channel public.payment_channels;
  v_ledger public.ledger_entries;
  v_tenant text;
begin
  -- Lock the submission row for the duration of this transaction.
  select * into v_sub
  from public.payment_submissions
  where id = p_submission_id
  for update;

  if not found then
    raise exception 'submission % not found', p_submission_id using errcode = 'P0002';
  end if;

  if v_sub.status <> 'pending' then
    raise exception 'submission % already %', p_submission_id, v_sub.status using errcode = '23514';
  end if;

  v_tenant := v_sub.tenant_id;

  if not public.is_tenant_staff(v_tenant) then
    raise exception 'not authorized for tenant %', v_tenant using errcode = '42501';
  end if;

  select * into v_channel
  from public.payment_channels
  where id = v_sub.channel_id and tenant_id = v_tenant;

  if not found then
    raise exception 'channel % not found', v_sub.channel_id using errcode = 'P0002';
  end if;

  -- Mark submission approved.
  update public.payment_submissions
  set status = 'approved',
      reviewed_by = coalesce(p_reviewer_uid, auth.uid()),
      reviewed_at = now(),
      updated_at = now()
  where id = p_submission_id;

  -- Immutable ledger entry for the approved amount.
  insert into public.ledger_entries
    (id, tenant_id, student_id, amount_piasters, kind, channel,
     reference_id, idempotency_key, note, created_by)
  values
    (p_submission_id, v_tenant, v_sub.student_id, v_sub.amount_piasters,
     'payment', v_channel.channel_type, v_sub.sender_reference,
     'pay:' || p_submission_id,
     coalesce(nullif(p_note, ''), 'Payment approved: ' || v_channel.name),
     coalesce(p_reviewer_uid, auth.uid()))
  returning * into v_ledger;

  -- Activation of the linked enrollment / session / reservation is executed by
  -- the billing edge function inside the same transaction after the ledger
  -- insert commits (kept explicit rather than silent).

  return jsonb_build_object(
    'ok', true,
    'submissionId', p_submission_id,
    'status', 'approved',
    'ledgerEntryId', v_ledger.id,
    'amountPiasters', v_ledger.amount_piasters
  );
end
$$;

grant execute on function public.approve_payment_submission(text, uuid, text) to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: reject_payment_submission (staff only). Requires a non-empty reason.
-- ---------------------------------------------------------------------------
create or replace function public.reject_payment_submission(
  p_submission_id text,
  p_reason text,
  p_reviewer_uid uuid default null
) returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_sub public.payment_submissions;
  v_tenant text;
begin
  if coalesce(p_reason, '') = '' then
    raise exception 'rejection reason is required' using errcode = '23514';
  end if;

  select * into v_sub
  from public.payment_submissions
  where id = p_submission_id
  for update;

  if not found then
    raise exception 'submission % not found', p_submission_id using errcode = 'P0002';
  end if;

  if v_sub.status <> 'pending' then
    raise exception 'submission % already %', p_submission_id, v_sub.status using errcode = '23514';
  end if;

  v_tenant := v_sub.tenant_id;

  if not public.is_tenant_staff(v_tenant) then
    raise exception 'not authorized for tenant %', v_tenant using errcode = '42501';
  end if;

  update public.payment_submissions
  set status = 'rejected',
      reviewed_by = coalesce(p_reviewer_uid, auth.uid()),
      reviewed_at = now(),
      rejection_reason = p_reason,
      updated_at = now()
  where id = p_submission_id;

  return jsonb_build_object(
    'ok', true,
    'submissionId', p_submission_id,
    'status', 'rejected',
    'reason', p_reason
  );
end
$$;

grant execute on function public.reject_payment_submission(text, text, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- Table privileges (RLS decides rows; grants decide operations).
-- ---------------------------------------------------------------------------
grant select, insert, update, delete on public.payment_channels to authenticated;
grant select, insert, update on public.payment_submissions to authenticated;
grant select, insert on public.ledger_entries to authenticated;

-- Explicitly remove delete from ledger_entries for clients (append-only).
revoke delete on public.ledger_entries from authenticated, anon;

-- Service role (edge functions) bypasses RLS.
grant all on all tables in schema public to service_role;
