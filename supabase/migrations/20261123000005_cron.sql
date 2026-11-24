-- Scheduled jobs: pg_cron calls the Supabase Edge Functions directly.
-- pg_cron + pg_net are preinstalled on Supabase; guarded for plain PostgreSQL.
--
-- The HTTP jobs call the edge functions with the service role key. Configure
-- once per database (values come from the Supabase dashboard, never committed):
--   alter database postgres set app.supabase_url = 'https://<ref>.supabase.co';
--   alter database postgres set app.service_role_key = '<service-role-key>';

do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
  end if;
  if exists (select 1 from pg_available_extensions where name = 'pg_net') then
    create extension if not exists pg_net;
  end if;
end
$$;

-- Heartbeat: the admin telemetry service reads health_ping. Runs every minute
-- directly in SQL (no HTTP round-trip needed).
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.schedule(
      'kashkool-health-ping',
      '* * * * *',
      $job$
        insert into public.health_ping (id, beat_at, service)
        values ('ping', now(), 'pg_cron')
        on conflict (id) do update set beat_at = now(), service = 'pg_cron'
      $job$
    );
  end if;
end
$$;

-- Weekly parent digest: Friday 18:00 Africa/Cairo (16:00 UTC winter / 15:00
-- summer; Egypt DST is handled by scheduling at 15:00 UTC year-round and the
-- edge function stamps local time). Calls the weekly-parent-report function.
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron')
     and exists (select 1 from pg_extension where extname = 'pg_net') then
    perform cron.schedule(
      'kashkool-weekly-parent-report',
      '0 15 * * 5',
      $job$
        select net.http_post(
          url := coalesce(nullif(current_setting('app.supabase_url', true), ''), 'http://localhost:54321')
                 || '/functions/v1/weekly-parent-report',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || coalesce(current_setting('app.service_role_key', true), '')
          ),
          body := '{}'::jsonb
        )
      $job$
    );

    -- Monthly usage billing: 1st of the month, 02:00 UTC.
    perform cron.schedule(
      'kashkool-monthly-billing',
      '0 2 1 * *',
      $job$
        select net.http_post(
          url := coalesce(nullif(current_setting('app.supabase_url', true), ''), 'http://localhost:54321')
                 || '/functions/v1/monthly-billing',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || coalesce(current_setting('app.service_role_key', true), '')
          ),
          body := '{}'::jsonb
        )
      $job$
    );

    -- Subscription expiry sweep: daily 03:00 UTC.
    perform cron.schedule(
      'kashkool-subscription-expiry',
      '0 3 * * *',
      $job$
        select net.http_post(
          url := coalesce(nullif(current_setting('app.supabase_url', true), ''), 'http://localhost:54321')
                 || '/functions/v1/subscription-expiry',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || coalesce(current_setting('app.service_role_key', true), '')
          ),
          body := '{}'::jsonb
        )
      $job$
    );
  end if;
end
$$;
