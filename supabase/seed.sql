-- Idempotent seed: platform switch defaults + development tenant.
-- Safe to run repeatedly (supabase db reset / seed).

insert into public.feature_flags (key, enabled) values
  ('global_emergency', false),
  ('new_quiz_feature', true),
  ('live_classroom', true),
  ('cash_desk', true)
on conflict (key) do nothing;

-- Development centre used by the dev scripts and smoke tests.
insert into public.tenants (id, name, subdomain, subscription_tier, subscription_expires_at)
values ('demo-centre', 'Demo Centre', 'demo', 'free', now() + interval '365 days')
on conflict (id) do nothing;

insert into public.health_ping (id, beat_at, service)
values ('ping', now(), 'seed')
on conflict (id) do nothing;
