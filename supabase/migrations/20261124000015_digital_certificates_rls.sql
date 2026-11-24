-- RLS for Digital Certificates.

alter table public.certificates enable row level security;
alter table public.certificate_verifications enable row level security;

-- ---------------------------------------------------------------------------
-- certificates:
--   - student/parent: read own certificates in tenant.
--   - staff: read all certificates in tenant; write certificates.
--   - public: read via verify_certificate RPC only (no direct table access).
-- ---------------------------------------------------------------------------
create policy certificates_select on public.certificates
  for select to authenticated
  using (
    public.is_tenant_member(tenant_id)
    and (
      public.is_tenant_staff(tenant_id)
      or student_id = (
        select id from public.students s
        where s.user_id = auth.uid() and s.tenant_id = certificates.tenant_id
        limit 1
      )
    )
  );

create policy certificates_write on public.certificates
  for all to authenticated
  using (public.is_tenant_staff(tenant_id))
  with check (public.is_tenant_staff(tenant_id));

-- ---------------------------------------------------------------------------
-- certificate_verifications:
--   - staff: read all verification logs in tenant.
--   - public: insert only (public verification attempts).
-- ---------------------------------------------------------------------------
create policy certificate_verifications_select on public.certificate_verifications
  for select to authenticated
  using (public.is_tenant_member(
    (select tenant_id from public.certificates where id = certificate_verifications.certificate_id)
  ));

create policy certificate_verifications_insert on public.certificate_verifications
  for insert to authenticated, anon
  with check (true);