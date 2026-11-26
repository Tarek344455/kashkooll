-- ============================================================================
-- KASHKOOL (kashkool_app) — ADAPTIVE STUDENT MEMORY & SUPER-ADMIN AI VAULT
-- Pure Stack: 100% Supabase PostgreSQL + STRICT FORCE RLS + PII Scrubbing
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Super-Admin Registry (Strictly separate from Center Admin / Teacher / Student / Parent)
CREATE TABLE IF NOT EXISTS public.kashkool_super_admins (
  user_id UUID PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL DEFAULT 'Kashkool Platform Super-Admin',
  is_active BOOLEAN NOT NULL DEFAULT true,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.kashkool_super_admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kashkool_super_admins FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "super_admins_self_read" ON public.kashkool_super_admins;
CREATE POLICY "super_admins_self_read" ON public.kashkool_super_admins
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() AND is_active = true);

CREATE OR REPLACE FUNCTION public.is_kashkool_super_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.kashkool_super_admins sa
    WHERE sa.user_id = auth.uid()
      AND sa.is_active = true
  );
$$;

REVOKE ALL ON FUNCTION public.is_kashkool_super_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_kashkool_super_admin() TO authenticated;

-- 2. Adaptive Student Memory (Private to Owning Student + Platform Super-Admin)
CREATE TABLE IF NOT EXISTS public.student_ai_memories (
  student_id TEXT PRIMARY KEY REFERENCES public.students(id) ON DELETE CASCADE,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  owner_user_id UUID NULL,
  learning_pace TEXT NOT NULL DEFAULT 'balanced'
    CHECK (learning_pace IN ('gentle', 'balanced', 'intensive')),
  preferred_style TEXT NOT NULL DEFAULT 'step_by_step'
    CHECK (preferred_style IN ('step_by_step', 'visual_examples', 'socratic', 'concise_summary')),
  tone_preference TEXT NOT NULL DEFAULT 'warm_egyptian'
    CHECK (tone_preference IN ('warm_egyptian', 'calm_academic', 'encouraging_coach')),
  academic_track TEXT NOT NULL DEFAULT 'Thanaweya Amma',
  weak_topics JSONB NOT NULL DEFAULT '[]'::jsonb,
  emotional_triggers JSONB NOT NULL DEFAULT '[]'::jsonb,
  study_habits JSONB NOT NULL DEFAULT '{}'::jsonb,
  internal_analytical_weights JSONB NOT NULL DEFAULT '{"empathyWeight":0.85,"socraticWeight":0.75,"stepGranularity":3}'::jsonb,
  last_emotion TEXT NOT NULL DEFAULT 'CALM',
  total_sessions_count INTEGER NOT NULL DEFAULT 0 CHECK (total_sessions_count >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_student_ai_memories_tenant_updated
  ON public.student_ai_memories (tenant_id, updated_at DESC);

ALTER TABLE public.student_ai_memories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_ai_memories FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "student_memory_owner_select" ON public.student_ai_memories;
CREATE POLICY "student_memory_owner_select" ON public.student_ai_memories
  FOR SELECT TO authenticated
  USING (
    public.is_kashkool_super_admin()
    OR owner_user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.students s
      WHERE s.id = student_ai_memories.student_id
        AND s.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "student_memory_owner_insert" ON public.student_ai_memories;
CREATE POLICY "student_memory_owner_insert" ON public.student_ai_memories
  FOR INSERT TO authenticated
  WITH CHECK (
    owner_user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.students s
      WHERE s.id = student_ai_memories.student_id
        AND s.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "student_memory_owner_update" ON public.student_ai_memories;
CREATE POLICY "student_memory_owner_update" ON public.student_ai_memories
  FOR UPDATE TO authenticated
  USING (
    owner_user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.students s
      WHERE s.id = student_ai_memories.student_id
        AND s.user_id = auth.uid()
    )
  )
  WITH CHECK (
    owner_user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.students s
      WHERE s.id = student_ai_memories.student_id
        AND s.user_id = auth.uid()
    )
  );

-- 3. Student AI Sessions Log (Compact conversational summaries for cross-session continuity)
CREATE TABLE IF NOT EXISTS public.student_ai_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id TEXT NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  tenant_id TEXT NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
  subject TEXT NOT NULL DEFAULT 'General',
  detected_emotion TEXT NOT NULL DEFAULT 'CALM',
  routing_lane TEXT NOT NULL DEFAULT 'ULTRA_FAST_EMPATHETIC',
  topic_summary TEXT NOT NULL DEFAULT '',
  resolved_successfully BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_student_ai_sessions_student_recent
  ON public.student_ai_sessions (student_id, created_at DESC);

ALTER TABLE public.student_ai_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_ai_sessions FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "student_sessions_owner_select" ON public.student_ai_sessions;
CREATE POLICY "student_sessions_owner_select" ON public.student_ai_sessions
  FOR SELECT TO authenticated
  USING (
    public.is_kashkool_super_admin()
    OR EXISTS (
      SELECT 1 FROM public.students s
      WHERE s.id = student_ai_sessions.student_id
        AND s.user_id = auth.uid()
    )
  );

-- 4. SUPER-ADMIN-ONLY AI TRAINING & COGNITIVE TELEMETRY VAULT
-- ZERO SELECT/UPDATE/DELETE FOR STUDENTS, TEACHERS, SECRETARIES, CENTER ADMINS, OR PARENTS
CREATE TABLE IF NOT EXISTS public.ai_training_telemetry (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  anonymized_actor_hash TEXT NOT NULL,
  tenant_bucket TEXT NOT NULL DEFAULT 'eg-edtech',
  interaction_lane TEXT NOT NULL,
  detected_emotion TEXT NOT NULL,
  model_id TEXT NOT NULL,
  provider_id TEXT NOT NULL,
  ttft_ms INTEGER NOT NULL DEFAULT 0 CHECK (ttft_ms >= 0),
  total_latency_ms INTEGER NOT NULL DEFAULT 0 CHECK (total_latency_ms >= 0),
  failover_occurred BOOLEAN NOT NULL DEFAULT false,
  prompt_injection_flagged BOOLEAN NOT NULL DEFAULT false,
  cheating_attempt_flagged BOOLEAN NOT NULL DEFAULT false,
  sanitized_prompt_excerpt TEXT NOT NULL,
  sanitized_response_excerpt TEXT NOT NULL,
  pedagogical_strategy TEXT NOT NULL,
  quality_signal NUMERIC(4,3) NOT NULL DEFAULT 0.900 CHECK (quality_signal BETWEEN 0 AND 1),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_telemetry_created_at
  ON public.ai_training_telemetry (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ai_telemetry_emotion_lane
  ON public.ai_training_telemetry (detected_emotion, interaction_lane, created_at DESC);

ALTER TABLE public.ai_training_telemetry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_training_telemetry FORCE ROW LEVEL SECURITY;

-- Explicitly drop any permissive policies if re-run
DROP POLICY IF EXISTS "telemetry_super_admin_only_select" ON public.ai_training_telemetry;
CREATE POLICY "telemetry_super_admin_only_select" ON public.ai_training_telemetry
  FOR SELECT TO authenticated
  USING (public.is_kashkool_super_admin());

-- No INSERT/UPDATE/DELETE RLS policies for any regular role; writes happen strictly via SECURITY DEFINER RPC.

CREATE OR REPLACE FUNCTION public.prevent_telemetry_mutation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE EXCEPTION 'ai_training_telemetry is immutable and append-only';
END;
$$;

DROP TRIGGER IF EXISTS trg_ai_telemetry_immutable ON public.ai_training_telemetry;
CREATE TRIGGER trg_ai_telemetry_immutable
  BEFORE UPDATE OR DELETE ON public.ai_training_telemetry
  FOR EACH ROW EXECUTE FUNCTION public.prevent_telemetry_mutation();

-- 5. PII Scrubbing Helper + Non-Blocking Ingestion RPC
CREATE OR REPLACE FUNCTION public.scrub_kashkool_pii(p_input TEXT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_clean TEXT := COALESCE(p_input, '');
BEGIN
  -- Scrub 14-digit Egyptian National IDs first
  v_clean := regexp_replace(v_clean, '\y[23][0-9]{13}\y', '[NID_REDACTED]', 'g');
  -- Scrub Egyptian mobile numbers (+20 / 0020 / 010 / 011 / 012 / 015)
  v_clean := regexp_replace(v_clean, '(\+?2|002)?01[0125][0-9]{8}\y', '[PHONE_REDACTED]', 'g');
  -- Scrub emails
  v_clean := regexp_replace(v_clean, '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}', '[EMAIL_REDACTED]', 'g');
  -- Scrub API keys & Bearer tokens
  v_clean := regexp_replace(v_clean, '(Bearer\s+[A-Za-z0-9._-]+|sk-[A-Za-z0-9_-]{8,}|gsk_[A-Za-z0-9_-]{8,})', '[SECRET_REDACTED]', 'gi');
  RETURN left(v_clean, 1200);
END;
$$;

CREATE OR REPLACE FUNCTION public.ingest_ai_training_telemetry(
  p_actor_id TEXT,
  p_interaction_lane TEXT,
  p_detected_emotion TEXT,
  p_model_id TEXT,
  p_provider_id TEXT,
  p_ttft_ms INTEGER,
  p_total_latency_ms INTEGER,
  p_failover_occurred BOOLEAN,
  p_prompt_injection_flagged BOOLEAN,
  p_cheating_attempt_flagged BOOLEAN,
  p_prompt_excerpt TEXT,
  p_response_excerpt TEXT,
  p_pedagogical_strategy TEXT,
  p_quality_signal NUMERIC DEFAULT 0.900
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
  v_hash TEXT;
BEGIN
  v_hash := encode(digest(COALESCE(p_actor_id, 'anon') || ':kashkool-salt-2026', 'sha256'), 'hex');
  INSERT INTO public.ai_training_telemetry (
    anonymized_actor_hash,
    interaction_lane,
    detected_emotion,
    model_id,
    provider_id,
    ttft_ms,
    total_latency_ms,
    failover_occurred,
    prompt_injection_flagged,
    cheating_attempt_flagged,
    sanitized_prompt_excerpt,
    sanitized_response_excerpt,
    pedagogical_strategy,
    quality_signal
  ) VALUES (
    v_hash,
    COALESCE(p_interaction_lane, 'ULTRA_FAST_EMPATHETIC'),
    COALESCE(p_detected_emotion, 'CALM'),
    COALESCE(p_model_id, 'unknown'),
    COALESCE(p_provider_id, 'unknown'),
    GREATEST(0, COALESCE(p_ttft_ms, 0)),
    GREATEST(0, COALESCE(p_total_latency_ms, 0)),
    COALESCE(p_failover_occurred, false),
    COALESCE(p_prompt_injection_flagged, false),
    COALESCE(p_cheating_attempt_flagged, false),
    public.scrub_kashkool_pii(p_prompt_excerpt),
    public.scrub_kashkool_pii(p_response_excerpt),
    left(COALESCE(p_pedagogical_strategy, 'CALM -> ULTRA_FAST_EMPATHETIC'), 160),
    LEAST(1.0, GREATEST(0.0, COALESCE(p_quality_signal, 0.900)))
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.ingest_ai_training_telemetry(TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, INTEGER, BOOLEAN, BOOLEAN, BOOLEAN, TEXT, TEXT, TEXT, NUMERIC) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ingest_ai_training_telemetry(TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, INTEGER, BOOLEAN, BOOLEAN, BOOLEAN, TEXT, TEXT, TEXT, NUMERIC) TO authenticated;

-- 6. Student Preference Reset RPC
CREATE OR REPLACE FUNCTION public.reset_student_ai_preferences(p_student_id TEXT)
RETURNS public.student_ai_memories
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row public.student_ai_memories;
BEGIN
  UPDATE public.student_ai_memories m
  SET
    learning_pace = 'balanced',
    preferred_style = 'step_by_step',
    tone_preference = 'warm_egyptian',
    weak_topics = '[]'::jsonb,
    emotional_triggers = '[]'::jsonb,
    study_habits = '{}'::jsonb,
    updated_at = now()
  WHERE m.student_id = p_student_id
    AND (
      public.is_kashkool_super_admin()
      OR m.owner_user_id = auth.uid()
      OR EXISTS (
        SELECT 1 FROM public.students s
        WHERE s.id = m.student_id AND s.user_id = auth.uid()
      )
    )
  RETURNING * INTO v_row;

  IF v_row.student_id IS NULL THEN
    RAISE EXCEPTION 'FORBIDDEN: Student memory not owned by caller';
  END IF;

  RETURN v_row;
END;
$$;

REVOKE ALL ON FUNCTION public.reset_student_ai_preferences(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reset_student_ai_preferences(TEXT) TO authenticated;
