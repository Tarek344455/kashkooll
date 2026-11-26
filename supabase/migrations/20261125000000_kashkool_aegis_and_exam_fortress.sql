-- ============================================================================
-- KASHKOOL (kashkool_app) — SUPABASE POSTGRESQL FORTRESS MIGRATION
-- Pure Stack: PostgreSQL + Supabase Auth + RLS + ACID PL/pgSQL RPCs
-- Target Scale: 10,000+ Concurrent Active Users | Zero-Cheat Exam Shield
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Core Tenant, Role & Membership Tables
CREATE TABLE IF NOT EXISTS public.tenants (
  id TEXT PRIMARY KEY,
  name_ar TEXT NOT NULL,
  name_en TEXT NOT NULL,
  plan_id TEXT NOT NULL DEFAULT 'plan-pro',
  hmac_key_version INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.tenant_memberships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('student', 'secretary', 'teacher', 'parent', 'center_admin')),
  student_id TEXT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, user_id, role)
);

CREATE TABLE IF NOT EXISTS public.groups (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  teacher_id UUID NULL,
  name_ar TEXT NOT NULL,
  name_en TEXT NOT NULL,
  subject_ar TEXT NOT NULL,
  subject_en TEXT NOT NULL,
  schedule JSONB NOT NULL DEFAULT '{}'::jsonb,
  hall_name TEXT NOT NULL DEFAULT 'Hall A',
  enrolled INTEGER NOT NULL DEFAULT 0 CHECK (enrolled >= 0),
  capacity INTEGER NOT NULL DEFAULT 40 CHECK (capacity > 0),
  price_per_session_piasters INTEGER NOT NULL DEFAULT 8000 CHECK (price_per_session_piasters >= 0),
  center_split_percent INTEGER NOT NULL DEFAULT 20 CHECK (center_split_percent BETWEEN 0 AND 100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_group_capacity CHECK (enrolled <= capacity)
);

CREATE TABLE IF NOT EXISTS public.students (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  user_id UUID NULL,
  group_id TEXT NOT NULL REFERENCES public.groups(id),
  name_ar TEXT NOT NULL,
  name_en TEXT NOT NULL,
  phone TEXT NOT NULL,
  wallet_balance_piasters INTEGER NOT NULL DEFAULT 0 CHECK (wallet_balance_piasters >= 0),
  due_balance_piasters INTEGER NOT NULL DEFAULT 0 CHECK (due_balance_piasters >= 0),
  streak_days INTEGER NOT NULL DEFAULT 0 CHECK (streak_days >= 0),
  mastery_percent INTEGER NOT NULL DEFAULT 75 CHECK (mastery_percent BETWEEN 0 AND 100),
  is_blocked BOOLEAN NOT NULL DEFAULT false,
  qr_activation_code TEXT NULL UNIQUE,
  parent_invite_code TEXT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.parent_student_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  parent_user_id UUID NOT NULL,
  student_id TEXT NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  verified_via_code TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (parent_user_id, student_id)
);

-- 2. Attendance, Makeup Sessions (حصة تعويضية) & Financial ACID Ledger
CREATE TABLE IF NOT EXISTS public.attendance (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  student_id TEXT NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  group_id TEXT NOT NULL REFERENCES public.groups(id),
  session_id TEXT NOT NULL,
  idempotency_key TEXT NOT NULL,
  feedback_status TEXT NOT NULL CHECK (feedback_status IN ('valid', 'due', 'blocked')),
  is_makeup BOOLEAN NOT NULL DEFAULT false,
  scanned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS public.makeup_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  student_id TEXT NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  from_group_id TEXT NOT NULL REFERENCES public.groups(id),
  to_group_id TEXT NOT NULL REFERENCES public.groups(id),
  reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'issued' CHECK (status IN ('issued', 'redeemed', 'expired')),
  issued_by UUID NULL,
  redeemed_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.ledger_entries (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  student_id TEXT NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('topup', 'payment', 'reservation', 'refund', 'charge', 'settlement', 'void')),
  amount_piasters INTEGER NOT NULL,
  remaining_due_piasters INTEGER NOT NULL DEFAULT 0 CHECK (remaining_due_piasters >= 0),
  channel TEXT NOT NULL DEFAULT 'cash_desk',
  idempotency_key TEXT NOT NULL,
  voided_entry_id TEXT NULL REFERENCES public.ledger_entries(id),
  note TEXT NOT NULL DEFAULT '',
  created_by UUID NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, idempotency_key)
);

CREATE TABLE IF NOT EXISTS public.payment_submissions (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  student_id TEXT NOT NULL,
  channel_id TEXT NOT NULL,
  amount_piasters INTEGER NOT NULL CHECK (amount_piasters > 0),
  sender_reference TEXT NOT NULL,
  receipt_url TEXT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  rejection_reason TEXT NULL,
  reviewed_by UUID NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Homework, Mistake Bank (بنك الأخطاء), Announcements & Support Tickets
CREATE TABLE IF NOT EXISTS public.homework_assignments (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  group_id TEXT NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  title_ar TEXT NOT NULL,
  title_en TEXT NOT NULL,
  instructions_ar TEXT NOT NULL,
  instructions_en TEXT NOT NULL,
  due_at TIMESTAMPTZ NOT NULL,
  max_score INTEGER NOT NULL DEFAULT 20 CHECK (max_score > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.homework_submissions (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  assignment_id TEXT NOT NULL REFERENCES public.homework_assignments(id) ON DELETE CASCADE,
  student_id TEXT NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  answer_text TEXT NOT NULL DEFAULT '',
  attachment_url TEXT NULL,
  score INTEGER NULL CHECK (score >= 0),
  teacher_annotation TEXT NULL,
  status TEXT NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'graded', 'needs_revision')),
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  graded_at TIMESTAMPTZ NULL,
  UNIQUE (assignment_id, student_id)
);

CREATE TABLE IF NOT EXISTS public.mistake_bank (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  student_id TEXT NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  source_type TEXT NOT NULL CHECK (source_type IN ('quiz', 'exam', 'homework')),
  source_id TEXT NOT NULL,
  topic_ar TEXT NOT NULL,
  topic_en TEXT NOT NULL,
  prompt TEXT NOT NULL,
  student_answer TEXT NOT NULL,
  correct_answer TEXT NOT NULL,
  explanation TEXT NOT NULL DEFAULT '',
  is_mastered BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.announcements (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  target_group_id TEXT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  title_ar TEXT NOT NULL,
  title_en TEXT NOT NULL,
  body_ar TEXT NOT NULL,
  body_en TEXT NOT NULL,
  priority TEXT NOT NULL DEFAULT 'normal' CHECK (priority IN ('normal', 'urgent')),
  created_by UUID NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.announcement_reads (
  announcement_id TEXT NOT NULL REFERENCES public.announcements(id) ON DELETE CASCADE,
  student_id TEXT NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (announcement_id, student_id)
);

CREATE TABLE IF NOT EXISTS public.support_tickets (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  student_id TEXT NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  creator_role TEXT NOT NULL CHECK (creator_role IN ('student', 'parent')),
  category TEXT NOT NULL CHECK (category IN ('academic', 'financial', 'schedule', 'technical')),
  subject TEXT NOT NULL,
  message TEXT NOT NULL,
  staff_reply TEXT NULL,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'answered', 'closed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. ZERO-CHEAT MASSIVE-SCALE EXAM FORTRESS ("KASHKOOL EXAM SHIELD")
CREATE TABLE IF NOT EXISTS public.exams (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  group_id TEXT NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
  title_ar TEXT NOT NULL,
  title_en TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL CHECK (duration_minutes BETWEEN 5 AND 240),
  pass_percent INTEGER NOT NULL DEFAULT 60 CHECK (pass_percent BETWEEN 1 AND 100),
  max_violations INTEGER NOT NULL DEFAULT 3 CHECK (max_violations BETWEEN 1 AND 20),
  shuffle_seed_salt TEXT NOT NULL DEFAULT encode(gen_random_bytes(16), 'hex'),
  is_published BOOLEAN NOT NULL DEFAULT false,
  starts_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ends_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '30 days'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Public/sanitized questions (NO correct_index or rubric!)
CREATE TABLE IF NOT EXISTS public.exam_questions (
  id TEXT PRIMARY KEY,
  exam_id TEXT NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  topic_ar TEXT NOT NULL,
  topic_en TEXT NOT NULL,
  prompt_ar TEXT NOT NULL,
  prompt_en TEXT NOT NULL,
  formula TEXT NOT NULL DEFAULT '',
  media_url TEXT NULL,
  options JSONB NOT NULL,
  order_index INTEGER NOT NULL DEFAULT 0
);

-- STRICT SERVER-ONLY ANSWER KEY ISOLATION (ZERO SELECT RLS FOR STUDENTS)
CREATE TABLE IF NOT EXISTS public.exam_question_keys (
  question_id TEXT PRIMARY KEY REFERENCES public.exam_questions(id) ON DELETE CASCADE,
  exam_id TEXT NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  correct_index INTEGER NOT NULL CHECK (correct_index >= 0),
  points INTEGER NOT NULL DEFAULT 1 CHECK (points > 0),
  explanation_ar TEXT NOT NULL DEFAULT '',
  explanation_en TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS public.exam_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exam_id TEXT NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  student_id TEXT NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  shuffle_seed TEXT NOT NULL,
  question_order JSONB NOT NULL DEFAULT '[]'::jsonb,
  option_orders JSONB NOT NULL DEFAULT '{}'::jsonb,
  status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'submitted', 'locked_violation', 'expired')),
  violations_count INTEGER NOT NULL DEFAULT 0 CHECK (violations_count >= 0),
  score_points INTEGER NULL,
  max_points INTEGER NULL,
  percent_score INTEGER NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  hard_deadline_at TIMESTAMPTZ NOT NULL,
  last_heartbeat_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  submitted_at TIMESTAMPTZ NULL,
  UNIQUE (exam_id, student_id)
);

CREATE TABLE IF NOT EXISTS public.exam_answers (
  attempt_id UUID NOT NULL REFERENCES public.exam_attempts(id) ON DELETE CASCADE,
  question_id TEXT NOT NULL REFERENCES public.exam_questions(id) ON DELETE CASCADE,
  selected_index INTEGER NOT NULL CHECK (selected_index >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (attempt_id, question_id)
);

CREATE TABLE IF NOT EXISTS public.exam_security_events (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  attempt_id UUID NOT NULL REFERENCES public.exam_attempts(id) ON DELETE CASCADE,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  student_id TEXT NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL,
  detail TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.certificates (
  id TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  student_id TEXT NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  exam_id TEXT NOT NULL REFERENCES public.exams(id) ON DELETE CASCADE,
  score_percent INTEGER NOT NULL,
  verification_hash TEXT NOT NULL,
  issued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (exam_id, student_id)
);

-- 5. KASHKOOL AEGIS SHIELD: Anti-Replay Nonces, Device Binding & Immutable Audit Ledger
CREATE TABLE IF NOT EXISTS public.qr_nonces (
  nonce_hash TEXT PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  scope TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  consumed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.device_bindings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  device_fingerprint TEXT NOT NULL,
  device_label TEXT NOT NULL DEFAULT 'Browser',
  is_revoked BOOLEAN NOT NULL DEFAULT false,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (tenant_id, user_id, device_fingerprint)
);

CREATE TABLE IF NOT EXISTS public.security_audit_logs (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tenant_id TEXT NOT NULL,
  actor_id TEXT NOT NULL,
  actor_role TEXT NOT NULL,
  action TEXT NOT NULL,
  target_table TEXT NOT NULL,
  target_id TEXT NOT NULL,
  before_state JSONB NULL,
  after_state JSONB NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. Sub-15ms High-Scale Composite Indexes
CREATE INDEX IF NOT EXISTS idx_attendance_tenant_student_time ON public.attendance (tenant_id, student_id, scanned_at DESC);
CREATE INDEX IF NOT EXISTS idx_attendance_session ON public.attendance (tenant_id, session_id);
CREATE INDEX IF NOT EXISTS idx_ledger_tenant_student_time ON public.ledger_entries (tenant_id, student_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_exam_attempts_exam_status ON public.exam_attempts (exam_id, status);
CREATE INDEX IF NOT EXISTS idx_exam_attempts_student ON public.exam_attempts (student_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_exam_sec_events_attempt ON public.exam_security_events (attempt_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mistake_bank_student ON public.mistake_bank (tenant_id, student_id, is_mastered, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_announcements_group ON public.announcements (tenant_id, target_group_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_time ON public.security_audit_logs (tenant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_qr_nonces_expires ON public.qr_nonces (expires_at);

-- 7. Helper Functions for Zero-Trust RLS
CREATE OR REPLACE FUNCTION public.has_tenant_role(p_tenant_id TEXT, p_roles TEXT[])
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.tenant_memberships tm
    WHERE tm.tenant_id = p_tenant_id
      AND tm.user_id = auth.uid()
      AND tm.is_active = true
      AND tm.role = ANY (p_roles)
  );
$$;

CREATE OR REPLACE FUNCTION public.is_linked_parent(p_tenant_id TEXT, p_student_id TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.parent_student_links psl
    WHERE psl.tenant_id = p_tenant_id
      AND psl.parent_user_id = auth.uid()
      AND psl.student_id = p_student_id
  );
$$;

-- 8. FORCE ROW LEVEL SECURITY ON 100% OF TABLES
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenants FORCE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tenant_memberships FORCE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups FORCE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students FORCE ROW LEVEL SECURITY;
ALTER TABLE public.parent_student_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parent_student_links FORCE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance FORCE ROW LEVEL SECURITY;
ALTER TABLE public.makeup_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.makeup_sessions FORCE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ledger_entries FORCE ROW LEVEL SECURITY;
ALTER TABLE public.payment_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_submissions FORCE ROW LEVEL SECURITY;
ALTER TABLE public.homework_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.homework_assignments FORCE ROW LEVEL SECURITY;
ALTER TABLE public.homework_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.homework_submissions FORCE ROW LEVEL SECURITY;
ALTER TABLE public.mistake_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mistake_bank FORCE ROW LEVEL SECURITY;
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcements FORCE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_reads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.announcement_reads FORCE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.support_tickets FORCE ROW LEVEL SECURITY;
ALTER TABLE public.exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exams FORCE ROW LEVEL SECURITY;
ALTER TABLE public.exam_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_questions FORCE ROW LEVEL SECURITY;
ALTER TABLE public.exam_question_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_question_keys FORCE ROW LEVEL SECURITY;
ALTER TABLE public.exam_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_attempts FORCE ROW LEVEL SECURITY;
ALTER TABLE public.exam_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_answers FORCE ROW LEVEL SECURITY;
ALTER TABLE public.exam_security_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exam_security_events FORCE ROW LEVEL SECURITY;
ALTER TABLE public.certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.certificates FORCE ROW LEVEL SECURITY;
ALTER TABLE public.qr_nonces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_nonces FORCE ROW LEVEL SECURITY;
ALTER TABLE public.device_bindings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_bindings FORCE ROW LEVEL SECURITY;
ALTER TABLE public.security_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_audit_logs FORCE ROW LEVEL SECURITY;

-- Strict Policies:
CREATE POLICY p_groups_read ON public.groups FOR SELECT
  USING (public.has_tenant_role(tenant_id, ARRAY['student','secretary','teacher','parent','center_admin']));

CREATE POLICY p_groups_staff_write ON public.groups FOR ALL
  USING (public.has_tenant_role(tenant_id, ARRAY['teacher','center_admin','secretary']))
  WITH CHECK (public.has_tenant_role(tenant_id, ARRAY['teacher','center_admin','secretary']));

CREATE POLICY p_students_access ON public.students FOR SELECT
  USING (
    user_id = auth.uid()
    OR public.has_tenant_role(tenant_id, ARRAY['teacher','secretary','center_admin'])
    OR public.is_linked_parent(tenant_id, id)
  );

CREATE POLICY p_attendance_access ON public.attendance FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM public.students s WHERE s.id = student_id AND s.user_id = auth.uid())
    OR public.has_tenant_role(tenant_id, ARRAY['teacher','secretary','center_admin'])
    OR public.is_linked_parent(tenant_id, student_id)
  );

CREATE POLICY p_ledger_access ON public.ledger_entries FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM public.students s WHERE s.id = student_id AND s.user_id = auth.uid())
    OR public.has_tenant_role(tenant_id, ARRAY['teacher','secretary','center_admin'])
    OR public.is_linked_parent(tenant_id, student_id)
  );

CREATE POLICY p_exams_student_read ON public.exams FOR SELECT
  USING (
    (is_published = true AND public.has_tenant_role(tenant_id, ARRAY['student','parent']))
    OR public.has_tenant_role(tenant_id, ARRAY['teacher','center_admin'])
  );

CREATE POLICY p_exam_questions_read ON public.exam_questions FOR SELECT
  USING (
    public.has_tenant_role(tenant_id, ARRAY['teacher','center_admin'])
    OR EXISTS (
      SELECT 1 FROM public.exam_attempts ea
      JOIN public.students s ON s.id = ea.student_id
      WHERE ea.exam_id = exam_questions.exam_id
        AND s.user_id = auth.uid()
        AND ea.status = 'in_progress'
    )
  );

-- CRITICAL: exam_question_keys has ZERO student SELECT policy! Only teacher/admin.
CREATE POLICY p_exam_keys_teacher_only ON public.exam_question_keys FOR ALL
  USING (public.has_tenant_role(tenant_id, ARRAY['teacher','center_admin']))
  WITH CHECK (public.has_tenant_role(tenant_id, ARRAY['teacher','center_admin']));

CREATE POLICY p_exam_attempts_access ON public.exam_attempts FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM public.students s WHERE s.id = student_id AND s.user_id = auth.uid())
    OR public.has_tenant_role(tenant_id, ARRAY['teacher','center_admin'])
    OR public.is_linked_parent(tenant_id, student_id)
  );

CREATE POLICY p_audit_logs_admin_read ON public.security_audit_logs FOR SELECT
  USING (public.has_tenant_role(tenant_id, ARRAY['teacher','center_admin']));

-- Prevent DELETE/UPDATE on immutable security_audit_logs & ledger_entries
CREATE OR REPLACE FUNCTION public.prevent_immutable_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'Kashkool Aegis Shield: Immutable table % cannot be modified or deleted.', TG_TABLE_NAME;
END;
$$;

DROP TRIGGER IF EXISTS trg_immutable_audit_logs ON public.security_audit_logs;
CREATE TRIGGER trg_immutable_audit_logs
  BEFORE UPDATE OR DELETE ON public.security_audit_logs
  FOR EACH ROW EXECUTE FUNCTION public.prevent_immutable_mutation();

DROP TRIGGER IF EXISTS trg_immutable_ledger_entries ON public.ledger_entries;
CREATE TRIGGER trg_immutable_ledger_entries
  BEFORE UPDATE OR DELETE ON public.ledger_entries
  FOR EACH ROW EXECUTE FUNCTION public.prevent_immutable_mutation();

-- 9. Audit Triggers on Critical Tables
CREATE OR REPLACE FUNCTION public.fn_audit_critical_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.security_audit_logs (
    tenant_id, actor_id, actor_role, action, target_table, target_id, before_state, after_state
  ) VALUES (
    COALESCE(NEW.tenant_id, OLD.tenant_id, 'unknown'),
    COALESCE(auth.uid()::text, 'system'),
    COALESCE(current_setting('request.jwt.claim.role', true), 'service'),
    TG_OP,
    TG_TABLE_NAME,
    COALESCE(NEW.id::text, OLD.id::text),
    CASE WHEN TG_OP IN ('UPDATE', 'DELETE') THEN to_jsonb(OLD) ELSE NULL END,
    CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN to_jsonb(NEW) ELSE NULL END
  );
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_ledger ON public.ledger_entries;
CREATE TRIGGER trg_audit_ledger
  AFTER INSERT ON public.ledger_entries
  FOR EACH ROW EXECUTE FUNCTION public.fn_audit_critical_change();

DROP TRIGGER IF EXISTS trg_audit_exam_attempts ON public.exam_attempts;
CREATE TRIGGER trg_audit_exam_attempts
  AFTER UPDATE OF score_points, status ON public.exam_attempts
  FOR EACH ROW EXECUTE FUNCTION public.fn_audit_critical_change();

-- 10. ATOMIC ACID RPCs (SECURITY DEFINER)
CREATE OR REPLACE FUNCTION public.record_attendance(
  p_id TEXT,
  p_tenant_id TEXT,
  p_student_id TEXT,
  p_session_id TEXT,
  p_idempotency_key TEXT,
  p_scanned_at TIMESTAMPTZ DEFAULT now()
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_student public.students%ROWTYPE;
  v_status TEXT;
BEGIN
  SELECT * INTO v_student FROM public.students WHERE id = p_student_id AND tenant_id = p_tenant_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Student not found in tenant';
  END IF;

  v_status := CASE
    WHEN v_student.is_blocked THEN 'blocked'
    WHEN v_student.due_balance_piasters > 0 THEN 'due'
    ELSE 'valid'
  END;

  INSERT INTO public.attendance (id, tenant_id, student_id, group_id, session_id, idempotency_key, feedback_status, scanned_at)
  VALUES (p_id, p_tenant_id, p_student_id, v_student.group_id, p_session_id, p_idempotency_key, v_status, p_scanned_at)
  ON CONFLICT (tenant_id, idempotency_key) DO NOTHING;

  IF NOT v_student.is_blocked THEN
    UPDATE public.students SET streak_days = streak_days + 1 WHERE id = p_student_id;
  END IF;

  RETURN jsonb_build_object('ok', true, 'status', v_status);
END;
$$;

CREATE OR REPLACE FUNCTION public.record_wallet_transaction(
  p_id TEXT,
  p_tenant_id TEXT,
  p_student_id TEXT,
  p_amount_piasters INTEGER,
  p_kind TEXT,
  p_channel TEXT,
  p_idempotency_key TEXT,
  p_note TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_student public.students%ROWTYPE;
  v_new_wallet INTEGER;
  v_new_due INTEGER;
  v_paid_due INTEGER;
BEGIN
  IF p_amount_piasters <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive';
  END IF;

  IF EXISTS (SELECT 1 FROM public.ledger_entries WHERE tenant_id = p_tenant_id AND idempotency_key = p_idempotency_key) THEN
    RETURN jsonb_build_object('ok', true, 'idempotent', true);
  END IF;

  SELECT * INTO v_student FROM public.students WHERE id = p_student_id AND tenant_id = p_tenant_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Student not found';
  END IF;

  v_new_wallet := v_student.wallet_balance_piasters;
  v_new_due := v_student.due_balance_piasters;

  IF p_kind = 'topup' THEN
    v_new_wallet := v_new_wallet + p_amount_piasters;
  ELSIF p_kind = 'payment' THEN
    v_paid_due := LEAST(v_new_due, p_amount_piasters);
    v_new_due := GREATEST(0, v_new_due - v_paid_due);
    v_new_wallet := v_new_wallet + (p_amount_piasters - v_paid_due);
  ELSIF p_kind = 'reservation' THEN
    IF v_new_wallet >= p_amount_piasters THEN
      v_new_wallet := v_new_wallet - p_amount_piasters;
    ELSE
      v_new_due := v_new_due + (p_amount_piasters - v_new_wallet);
      v_new_wallet := 0;
    END IF;
  ELSIF p_kind = 'refund' THEN
    v_new_due := GREATEST(0, v_new_due - p_amount_piasters);
  END IF;

  UPDATE public.students
  SET wallet_balance_piasters = v_new_wallet, due_balance_piasters = v_new_due
  WHERE id = p_student_id;

  INSERT INTO public.ledger_entries (
    id, tenant_id, student_id, kind, amount_piasters, remaining_due_piasters, channel, idempotency_key, note, created_by
  ) VALUES (
    p_id, p_tenant_id, p_student_id, p_kind, p_amount_piasters, v_new_due, p_channel, p_idempotency_key, p_note, auth.uid()
  );

  RETURN jsonb_build_object('ok', true, 'wallet_balance_piasters', v_new_wallet, 'due_balance_piasters', v_new_due);
END;
$$;

CREATE OR REPLACE FUNCTION public.void_wallet_transaction(
  p_tenant_id TEXT,
  p_transaction_id TEXT,
  p_reason TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_orig public.ledger_entries%ROWTYPE;
  v_void_id TEXT := 'void-' || gen_random_uuid()::text;
BEGIN
  SELECT * INTO v_orig FROM public.ledger_entries WHERE id = p_transaction_id AND tenant_id = p_tenant_id;
  IF NOT FOUND OR v_orig.kind = 'void' THEN
    RAISE EXCEPTION 'Original transaction not found or already void';
  END IF;

  IF EXISTS (SELECT 1 FROM public.ledger_entries WHERE voided_entry_id = p_transaction_id) THEN
    RETURN jsonb_build_object('ok', true, 'already_voided', true);
  END IF;

  IF v_orig.kind = 'topup' THEN
    UPDATE public.students
    SET wallet_balance_piasters = GREATEST(0, wallet_balance_piasters - v_orig.amount_piasters)
    WHERE id = v_orig.student_id;
  END IF;

  INSERT INTO public.ledger_entries (
    id, tenant_id, student_id, kind, amount_piasters, remaining_due_piasters, channel, idempotency_key, voided_entry_id, note, created_by
  ) VALUES (
    v_void_id, p_tenant_id, v_orig.student_id, 'void', -v_orig.amount_piasters, 0, v_orig.channel, v_void_id, p_transaction_id, p_reason, auth.uid()
  );

  RETURN jsonb_build_object('ok', true, 'void_id', v_void_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.start_exam_attempt(
  p_exam_id TEXT,
  p_student_id TEXT,
  p_device_id TEXT
)
RETURNS public.exam_attempts
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_exam public.exams%ROWTYPE;
  v_attempt public.exam_attempts%ROWTYPE;
  v_seed TEXT;
BEGIN
  SELECT * INTO v_exam FROM public.exams WHERE id = p_exam_id AND is_published = true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Exam not available';
  END IF;

  SELECT * INTO v_attempt FROM public.exam_attempts WHERE exam_id = p_exam_id AND student_id = p_student_id;
  IF FOUND THEN
    RETURN v_attempt;
  END IF;

  v_seed := encode(hmac(p_exam_id || ':' || p_student_id, v_exam.shuffle_seed_salt, 'sha256'), 'hex');
  INSERT INTO public.exam_attempts (
    exam_id, tenant_id, student_id, device_id, shuffle_seed, started_at, hard_deadline_at
  ) VALUES (
    p_exam_id, v_exam.tenant_id, p_student_id, p_device_id, v_seed, now(),
    LEAST(v_exam.ends_at, now() + (v_exam.duration_minutes || ' minutes')::interval)
  )
  RETURNING * INTO v_attempt;

  RETURN v_attempt;
END;
$$;

CREATE OR REPLACE FUNCTION public.upsert_exam_answer(
  p_attempt_id UUID,
  p_question_id TEXT,
  p_selected_index INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_attempt public.exam_attempts%ROWTYPE;
BEGIN
  SELECT * INTO v_attempt FROM public.exam_attempts WHERE id = p_attempt_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Attempt not found';
  END IF;
  IF auth.uid() IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.students s WHERE s.id = v_attempt.student_id AND s.user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Forbidden: attempt belongs to another student';
  END IF;
  IF v_attempt.status <> 'in_progress' THEN
    RAISE EXCEPTION 'Attempt is locked or already submitted';
  END IF;
  IF now() > v_attempt.hard_deadline_at + interval '2 seconds' THEN
    RAISE EXCEPTION 'Server deadline exceeded';
  END IF;

  INSERT INTO public.exam_answers (attempt_id, question_id, selected_index, updated_at)
  VALUES (p_attempt_id, p_question_id, p_selected_index, now())
  ON CONFLICT (attempt_id, question_id)
  DO UPDATE SET selected_index = EXCLUDED.selected_index, updated_at = now();

  RETURN jsonb_build_object('ok', true, 'saved_at', now());
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_and_grade_exam(p_attempt_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_attempt public.exam_attempts%ROWTYPE;
  v_exam public.exams%ROWTYPE;
  v_earned INTEGER := 0;
  v_total INTEGER := 0;
  v_pct INTEGER := 0;
  v_cert_id TEXT;
BEGIN
  SELECT * INTO v_attempt FROM public.exam_attempts WHERE id = p_attempt_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Attempt not found';
  END IF;
  IF auth.uid() IS NOT NULL AND NOT (
    EXISTS (SELECT 1 FROM public.students s WHERE s.id = v_attempt.student_id AND s.user_id = auth.uid())
    OR public.has_tenant_role(v_attempt.tenant_id, ARRAY['teacher','center_admin'])
  ) THEN
    RAISE EXCEPTION 'Forbidden: attempt access denied';
  END IF;
  IF v_attempt.status IN ('submitted', 'locked_violation') AND v_attempt.submitted_at IS NOT NULL THEN
    RETURN jsonb_build_object(
      'ok', true, 'idempotent', true,
      'score_points', v_attempt.score_points,
      'max_points', v_attempt.max_points,
      'percent_score', v_attempt.percent_score
    );
  END IF;

  SELECT * INTO v_exam FROM public.exams WHERE id = v_attempt.exam_id;

  SELECT
    COALESCE(SUM(k.points), 0),
    COALESCE(SUM(CASE WHEN a.selected_index = k.correct_index THEN k.points ELSE 0 END), 0)
  INTO v_total, v_earned
  FROM public.exam_question_keys k
  LEFT JOIN public.exam_answers a ON a.question_id = k.question_id AND a.attempt_id = p_attempt_id
  WHERE k.exam_id = v_attempt.exam_id;

  v_pct := CASE WHEN v_total > 0 THEN ROUND((v_earned::numeric / v_total::numeric) * 100)::integer ELSE 0 END;

  UPDATE public.exam_attempts
  SET status = CASE WHEN status = 'locked_violation' THEN 'locked_violation' ELSE 'submitted' END,
      score_points = v_earned,
      max_points = v_total,
      percent_score = v_pct,
      submitted_at = now()
  WHERE id = p_attempt_id;

  -- Auto-populate Mistake Bank for wrong or unanswered items
  INSERT INTO public.mistake_bank (
    id, tenant_id, student_id, source_type, source_id, topic_ar, topic_en, prompt, student_answer, correct_answer, explanation
  )
  SELECT
    'mb-' || p_attempt_id::text || '-' || q.id,
    v_attempt.tenant_id,
    v_attempt.student_id,
    'exam',
    v_attempt.exam_id,
    q.topic_ar,
    q.topic_en,
    q.prompt_ar,
    COALESCE(q.options ->> a.selected_index, 'لم تتم الإجابة'),
    q.options ->> k.correct_index,
    k.explanation_ar
  FROM public.exam_question_keys k
  JOIN public.exam_questions q ON q.id = k.question_id
  LEFT JOIN public.exam_answers a ON a.question_id = k.question_id AND a.attempt_id = p_attempt_id
  WHERE k.exam_id = v_attempt.exam_id
    AND (a.selected_index IS NULL OR a.selected_index <> k.correct_index)
  ON CONFLICT (id) DO NOTHING;

  IF v_pct >= v_exam.pass_percent THEN
    v_cert_id := 'cert-' || substr(encode(digest(p_attempt_id::text, 'sha256'), 'hex'), 1, 12);
    INSERT INTO public.certificates (id, tenant_id, student_id, exam_id, score_percent, verification_hash)
    VALUES (v_cert_id, v_attempt.tenant_id, v_attempt.student_id, v_attempt.exam_id, v_pct,
            encode(hmac(v_cert_id || ':' || v_attempt.student_id || ':' || v_pct::text, v_exam.shuffle_seed_salt, 'sha256'), 'hex'))
    ON CONFLICT (exam_id, student_id) DO NOTHING;
  END IF;

  RETURN jsonb_build_object('ok', true, 'score_points', v_earned, 'max_points', v_total, 'percent_score', v_pct);
END;
$$;
