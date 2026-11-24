-- Digital Certificates (الشهادات الرقمية القابلة للتحقق).
--
-- Certificates are issued when a student completes a group/session.
-- Each certificate has a unique number and QR code for public verification
-- (Zero-Cost: no SMS, no paid verification gateway).

-- ---------------------------------------------------------------------------
-- certificates: one row per issued certificate.
-- ---------------------------------------------------------------------------
create table public.certificates (
  id                  text primary key,
  tenant_id           text not null references public.tenants (id) on delete cascade,
  student_id          text not null references public.students (id) on delete cascade,
  group_id            text not null references public.groups (id) on delete cascade,
  certificate_number  text not null unique,
  title               text not null,                         -- 'إتمام دورة اللغة الإنجليزية'
  issued_at           timestamptz not null default now(),
  expires_at          timestamptz,                           -- optional expiry
  qr_code_payload     text not null,                         -- URL for public verification
  pdf_url             text,                                  -- signed storage URL (private bucket)
  is_verified         boolean not null default true,
  created_by          uuid,                                  -- staff who issued
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index certificates_tenant_idx on public.certificates (tenant_id);
create index certificates_student_idx on public.certificates (student_id);
create index certificates_group_idx on public.certificates (group_id);
create index certificates_number_idx on public.certificates (certificate_number);

-- ---------------------------------------------------------------------------
-- certificate_verifications: public verification log (who checked which cert).
-- ---------------------------------------------------------------------------
create table public.certificate_verifications (
  id              text primary key,
  certificate_id  text not null references public.certificates (id) on delete cascade,
  verified_at     timestamptz not null default now(),
  verifier_ip     text,
  verifier_agent  text,
  result          text not null default 'valid'
                  check (result in ('valid', 'invalid', 'expired')),
  created_at      timestamptz not null default now()
);

create index certificate_verifications_cert_idx on public.certificate_verifications (certificate_id);
create index certificate_verifications_created_idx on public.certificate_verifications (created_at);

-- ---------------------------------------------------------------------------
-- updated_at triggers
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_trigger where tgname = 'touch_updated_at_certificates'
  ) then
    create trigger touch_updated_at_certificates
      before update on public.certificates
      for each row execute function public.touch_updated_at();
  end if;
end
$$;

-- ---------------------------------------------------------------------------
-- RPC: issue_certificate (staff only).
-- Issues a new certificate for a student who completed a group.
-- ---------------------------------------------------------------------------
create or replace function public.issue_certificate(
  p_student_id text,
  p_group_id text,
  p_title text,
  p_certificate_number text,
  p_expires_at timestamptz default null,
  p_created_by uuid default null
) returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_tenant text;
  v_cert_id text := gen_random_uuid()::text;
  v_qr_payload text;
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

  -- QR payload: public verification URL
  v_qr_payload := 'https://pudaizumdahrlbckpyzq.supabase.co/certificates/verify/' || v_cert_id;

  insert into public.certificates
    (id, tenant_id, student_id, group_id, certificate_number,
     title, issued_at, expires_at, qr_code_payload, pdf_url,
     is_verified, created_by)
  values
    (v_cert_id, v_tenant, p_student_id, p_group_id, p_certificate_number,
     p_title, now(), p_expires_at, v_qr_payload, null,
     true, coalesce(p_created_by, auth.uid()));

  return jsonb_build_object(
    'ok', true,
    'certificateId', v_cert_id,
    'certificateNumber', p_certificate_number,
    'qrCodePayload', v_qr_payload
  );
end
$$;

grant execute on function public.issue_certificate(text, text, text, text, timestamptz, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: verify_certificate (public).
-- Publicly verifies a certificate by its ID or number.
-- ---------------------------------------------------------------------------
create or replace function public.verify_certificate(
  p_certificate_id text default null,
  p_certificate_number text default null
) returns jsonb
language plpgsql security invoker set search_path = public
as $$
declare
  v_cert public.certificates;
  v_found boolean := false;
begin
  -- Look up by ID first
  if p_certificate_id is not null then
    select * into v_cert
    from public.certificates
    where id = p_certificate_id;
    v_found := found;
  end if;

  -- Fallback to certificate number
  if not v_found and p_certificate_number is not null then
    select * into v_cert
    from public.certificates
    where certificate_number = p_certificate_number;
    v_found := found;
  end if;

  if not v_found then
    return jsonb_build_object(
      'valid', false,
      'result', 'invalid',
      'message', 'Certificate not found'
    );
  end if;

  -- Check expiry
  if v_cert.expires_at is not null and v_cert.expires_at < now() then
    return jsonb_build_object(
      'valid', false,
      'result', 'expired',
      'certificateId', v_cert.id,
      'certificateNumber', v_cert.certificate_number,
      'studentId', v_cert.student_id,
      'groupId', v_cert.group_id,
      'title', v_cert.title,
      'issuedAt', v_cert.issued_at,
      'expiresAt', v_cert.expires_at,
      'message', 'Certificate has expired'
    );
  end if;

  if not v_cert.is_verified then
    return jsonb_build_object(
      'valid', false,
      'result', 'invalid',
      'certificateId', v_cert.id,
      'certificateNumber', v_cert.certificate_number,
      'message', 'Certificate is not verified'
    );
  end if;

  return jsonb_build_object(
    'valid', true,
    'result', 'valid',
    'certificateId', v_cert.id,
    'certificateNumber', v_cert.certificate_number,
    'studentId', v_cert.student_id,
    'groupId', v_cert.group_id,
    'title', v_cert.title,
    'issuedAt', v_cert.issued_at,
    'expiresAt', v_cert.expires_at,
    'message', 'Certificate is valid'
  );
end
$$;

grant execute on function public.verify_certificate(text, text) to authenticated, anon;

-- ---------------------------------------------------------------------------
-- Table privileges
-- ---------------------------------------------------------------------------
grant select, insert, update on public.certificates to authenticated;
grant select on public.certificate_verifications to authenticated, anon;
grant insert on public.certificate_verifications to authenticated, anon;