-- Storage bucket for payment receipts (private, signed URLs only).
-- Run this after migrations are applied.

-- Create the private bucket
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('receipts', 'receipts', false, 5242880, array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do update set
  public = false,
  file_size_limit = 5242880,
  allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];

-- RLS policies for receipts bucket
-- Students/parents: can upload to their own folder (tenant_id/student_id/)
create policy "receipts_upload_own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = (select tenant_id::text from public.profiles where id = auth.uid())
    and (storage.foldername(name))[2] = (select id::text from public.profiles where id = auth.uid())
  );

-- Students/parents: can read their own receipts
create policy "receipts_read_own" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] = (select tenant_id::text from public.profiles where id = auth.uid())
    and (storage.foldername(name))[2] = (select id::text from public.profiles where id = auth.uid())
  );

-- Staff (teacher/secretary/admin): can read all receipts in their tenant
create policy "receipts_read_staff" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'receipts'
    and (storage.foldername(name))[1] in (
      select tenant_id::text from public.profiles where id = auth.uid()
    )
    and public.is_tenant_staff((storage.foldername(name))[1])
  );

-- Service role: full access (for edge functions)
create policy "receipts_service_role" on storage.objects
  for all to service_role
  using (bucket_id = 'receipts')
  with check (bucket_id = 'receipts');