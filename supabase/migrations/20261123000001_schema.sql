-- Kashkool core schema (Supabase / PostgreSQL).
-- Relational tenant model with row level security on every table.
-- Money is stored as integer piasters (1 EGP = 100 piasters) everywhere.

-- ---------------------------------------------------------------------------
-- Auth compatibility helpers.
-- On Supabase these already exist; on a plain PostgreSQL instance (CI, local
-- validation) the guarded stubs below make the migrations self-contained.
-- ---------------------------------------------------------------------------
create schema if not exists auth;

do $$
begin
  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'auth' and p.proname = 'uid'
  ) then
    execute $fn$
      create function auth.uid() returns uuid
      language sql stable
      as $body$
        select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
      $body$
    $fn$;
  end if;

  if not exists (
    select 1 from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'auth' and p.proname = 'role'
  ) then
    execute $fn$
      create function auth.role() returns text
      language sql stable
      as $body$
        select coalesce(
          nullif(current_setting('request.jwt.claim.role', true), ''),
          'anon'
        )
      $body$
    $fn$;
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- Tenants (centres / teachers). Ids stay human-readable slugs ('demo-centre')
-- to match the existing app contracts and QR payloads.
-- ---------------------------------------------------------------------------
create table public.tenants (
  id                      text primary key,
  name                    text not null,
  subdomain               text not null default '',
  accent_color            text not null default '#00E5FF',
  primary_color           text not null default '#0B1020',
  is_active               boolean not null default true,
  subscription_tier       text not null default 'free',
  subscription_expires_at timestamptz,
  active_modules          text[] not null default '{}',
  frozen_at               timestamptz,
  unfrozen_at             timestamptz,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Profiles: one row per auth user. Role and tenant live here,
-- (role / tenantId). 'unassigned' is represented by a NULL tenant_id.
-- ---------------------------------------------------------------------------
create table public.profiles (
  id              uuid primary key references auth.users (id) on delete cascade,
  phone           text,
  display_name    text not null default '',
  role            text not null default 'student'
                  check (role in ('student', 'teacher', 'centerAdmin', 'assistant', 'parent', 'supervisor')),
  tenant_id       text references public.tenants (id) on delete set null,
  bound_device_id text,
  device_bound_at timestamptz,
  is_online       boolean not null default false,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index profiles_tenant_idx on public.profiles (tenant_id);
create index profiles_phone_idx on public.profiles (phone);

-- ---------------------------------------------------------------------------
-- Students: the centre roster. `id` is the client-generated document id used
-- by the offline Drift queue; `user_id` links the roster row to an auth user
-- once the phone number is enrolled.
-- ---------------------------------------------------------------------------
create table public.students (
  id                     text primary key,
  tenant_id              text not null references public.tenants (id) on delete cascade,
  user_id                uuid references auth.users (id) on delete set null,
  name                   text not null,
  phone                  text not null default '',
  group_id               text,
  wallet_balance_piasters bigint not null default 0,
  bound_device_id        text,
  device_bound_at        timestamptz,
  is_online              boolean not null default false,
  metadata               jsonb not null default '{}',
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now()
);

create unique index students_tenant_user_idx
  on public.students (tenant_id, user_id) where user_id is not null;
create index students_tenant_phone_idx on public.students (tenant_id, phone);

-- ---------------------------------------------------------------------------
-- Groups, halls, sessions (schedule).
-- ---------------------------------------------------------------------------
create table public.groups (
  id         text primary key,
  tenant_id  text not null references public.tenants (id) on delete cascade,
  name       text not null,
  subject    text not null default '',
  teacher_id text,
  schedule   jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index groups_tenant_idx on public.groups (tenant_id);

create table public.halls (
  id         text primary key,
  tenant_id  text not null references public.tenants (id) on delete cascade,
  name       text not null,
  capacity   integer not null default 0 check (capacity >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index halls_tenant_idx on public.halls (tenant_id);

create table public.sessions (
  id              text primary key,
  tenant_id       text not null references public.tenants (id) on delete cascade,
  group_id        text,
  hall_id         text,
  title           text not null default '',
  subject         text not null default '',
  governorate     text not null default '',
  starts_at       timestamptz,
  ends_at         timestamptz,
  price_piasters  integer not null default 0 check (price_piasters >= 0),
  session_type    text not null default 'offline',
  qr_secret       text not null default '',
  is_active       boolean not null default false,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index sessions_tenant_idx on public.sessions (tenant_id);
create index sessions_active_idx on public.sessions (is_active) where is_active;
create index sessions_governorate_idx on public.sessions (governorate);

-- ---------------------------------------------------------------------------
-- Attendance: one scan = one row. Idempotency key + natural key make re-scans
-- and offline queue replays safe.
-- ---------------------------------------------------------------------------
create table public.attendance (
  id              text primary key,
  tenant_id       text not null references public.tenants (id) on delete cascade,
  student_id      text not null,
  session_id      text not null,
  status          text not null default 'present'
                  check (status in ('present', 'late', 'absent', 'excused')),
  idempotency_key text unique,
  recorded_by     uuid,
  scanned_at      timestamptz not null default now(),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (tenant_id, session_id, student_id)
);

create index attendance_tenant_session_idx on public.attendance (tenant_id, session_id);
create index attendance_student_idx on public.attendance (student_id);

-- ---------------------------------------------------------------------------
-- Wallet ledger: append-only, integer piasters. Corrections are formal
-- void/refund entries, never edits or deletes (triggers enforce this).
-- `student_id` references students.id logically; no FK so the ledger survives
-- roster cleanup, and the insert trigger validates membership instead.
-- ---------------------------------------------------------------------------
create table public.wallet_transactions (
  id                   text primary key,
  tenant_id            text not null references public.tenants (id) on delete cascade,
  student_id           text not null,
  amount_piasters      bigint not null check (amount_piasters <> 0),
  kind                 text not null
                       check (kind in ('topup', 'payment', 'charge', 'reservation', 'settlement', 'void', 'refund')),
  channel              text not null default 'cash',
  status               text not null default 'completed'
                       check (status in ('pending', 'completed', 'failed', 'voided')),
  reference_id         text,
  idempotency_key      text unique,
  voids_transaction_id text references public.wallet_transactions (id),
  note                 text not null default '',
  created_by           uuid,
  created_at           timestamptz not null default now(),
  constraint wallet_void_requires_target
    check (kind <> 'void' or voids_transaction_id is not null)
);

create index wallet_tenant_student_idx on public.wallet_transactions (tenant_id, student_id);
create index wallet_created_idx on public.wallet_transactions (created_at);
create index wallet_reference_idx on public.wallet_transactions (reference_id);

-- ---------------------------------------------------------------------------
-- Reservations (books / materials / seats) with a reservation fee.
-- ---------------------------------------------------------------------------
create table public.reservations (
  id               text primary key,
  tenant_id        text not null references public.tenants (id) on delete cascade,
  student_id       text not null,
  item_type        text not null check (item_type in ('book', 'material', 'seat')),
  item_id          text not null default '',
  fee_piasters     integer not null default 0 check (fee_piasters >= 0),
  status           text not null default 'pending'
                   check (status in ('pending', 'paid', 'cancelled')),
  transaction_id   text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index reservations_tenant_student_idx on public.reservations (tenant_id, student_id);

-- ---------------------------------------------------------------------------
-- Assessments: quizzes and their results.
-- ---------------------------------------------------------------------------
create table public.quizzes (
  id         text primary key,
  tenant_id  text not null references public.tenants (id) on delete cascade,
  title             text not null default '',
  subject           text not null default '',
  tags              text[] not null default '{}',
  questions         jsonb not null default '[]',
  time_limit_minutes integer not null default 0,
  difficulty        text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index quizzes_tenant_idx on public.quizzes (tenant_id);

create table public.quiz_results (
  id         text primary key,
  tenant_id  text not null references public.tenants (id) on delete cascade,
  quiz_id    text not null,
  student_id text not null,
  score      numeric(6, 2) not null default 0,
  answers    jsonb not null default '{}',
  taken_at   timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index quiz_results_tenant_student_idx on public.quiz_results (tenant_id, student_id);
create index quiz_results_quiz_idx on public.quiz_results (quiz_id);

-- ---------------------------------------------------------------------------
-- Billing: subscriptions per account (centre or teacher), written only by the
-- billing edge functions (service role). Clients read their own subscription.
-- ---------------------------------------------------------------------------
create table public.subscriptions (
  account_id        text primary key,
  account_type      text not null check (account_type in ('teacher', 'center')),
  active_modules    text[] not null default '{}',
  billing_cycle     text not null default 'monthly' check (billing_cycle in ('monthly', 'yearly')),
  expires_at        timestamptz,
  promo_code        text,
  usage_counters    jsonb not null default '{}',
  feature_overrides jsonb not null default '{}',
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create table public.billing_transactions (
  id              text primary key,
  account_id      text not null,
  account_type    text not null,
  modules         text[] not null default '{}',
  billing_cycle   text not null default 'monthly',
  promo_code      text,
  payment_method  text not null,
  amount_piasters bigint not null,
  currency        text not null default 'EGP',
  status          text not null default 'completed',
  metadata        jsonb not null default '{}',
  created_at      timestamptz not null default now()
);

create index billing_transactions_account_idx on public.billing_transactions (account_id);

create table public.usage_events (
  id         uuid primary key default gen_random_uuid(),
  account_id text not null,
  meter_key  text not null,
  quantity   integer not null check (quantity > 0),
  metadata   jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create index usage_events_account_idx on public.usage_events (account_id, created_at);

create table public.invoices (
  id           uuid primary key default gen_random_uuid(),
  account_id   text not null,
  type         text not null default 'usage',
  period_start timestamptz,
  period_end   timestamptz,
  items        jsonb not null default '{}',
  total_piasters bigint not null default 0,
  status       text not null default 'pending' check (status in ('pending', 'paid', 'void')),
  created_at   timestamptz not null default now()
);

create index invoices_account_idx on public.invoices (account_id);

-- ---------------------------------------------------------------------------
-- Platform switches (global kill-switch + feature flags). One row per flag;
-- Realtime propagates a flip to every client in <2s.
-- ---------------------------------------------------------------------------
create table public.feature_flags (
  key        text primary key,
  enabled    boolean not null default false,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- Audit trail: append-only, every privileged action lands here.
-- ---------------------------------------------------------------------------
create table public.audit_logs (
  id         uuid primary key default gen_random_uuid(),
  tenant_id  text not null default '',
  action     text not null,
  details    text not null default '',
  actor_uid  text not null default 'system',
  severity   text not null default 'low' check (severity in ('low', 'medium', 'high')),
  payload    jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create index audit_logs_tenant_idx on public.audit_logs (tenant_id, created_at desc);
create index audit_logs_severity_idx on public.audit_logs (severity) where severity = 'high';

-- ---------------------------------------------------------------------------
-- Assistant semantic cache, weekly parent reports, backend heartbeat.
-- ---------------------------------------------------------------------------
create table public.knowledge_cache (
  id         text primary key,
  tenant_id  text not null references public.tenants (id) on delete cascade,
  answer     jsonb not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz
);

create index knowledge_cache_tenant_idx on public.knowledge_cache (tenant_id);

create table public.reports (
  id                   uuid primary key default gen_random_uuid(),
  tenant_id            text not null references public.tenants (id) on delete cascade,
  student_id           text not null,
  attendance_rate      numeric(5, 4) not null default 0,
  quiz_score_trajectory text not null default 'steady',
  weak_tags            text[] not null default '{}',
  summary_arabic       text not null default '',
  summary_english      text not null default '',
  report_week          date not null default current_date,
  generated_at         timestamptz not null default now(),
  unique (tenant_id, student_id, report_week)
);

create index reports_tenant_student_idx on public.reports (tenant_id, student_id, generated_at desc);

create table public.health_ping (
  id       text primary key default 'ping',
  beat_at  timestamptz not null default now(),
  service  text not null default 'pg_cron'
);
