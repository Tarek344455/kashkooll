import crypto from "node:crypto";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

export type EmotionalPulse =
  | "EXAM_ANXIETY"
  | "FRUSTRATION"
  | "BURNOUT"
  | "LOW_CONFIDENCE"
  | "CURIOSITY"
  | "DISTRACTION"
  | "CALM";

export type RoutingLane =
  | "ULTRA_FAST_EMPATHETIC"
  | "DEEP_COGNITIVE_REASONING"
  | "VISION_MULTIMODAL"
  | "STRUCTURED_JSON";

export type LearningPace = "gentle" | "balanced" | "intensive";
export type PreferredStyle = "step_by_step" | "visual_examples" | "socratic" | "concise_summary";
export type TonePreference = "warm_egyptian" | "calm_academic" | "encouraging_coach";

export interface StudentAiSessionSummary {
  id: string;
  subject: string;
  detectedEmotion: EmotionalPulse;
  routingLane: RoutingLane;
  topicSummary: string;
  createdAtMillis: number;
}

export interface StudentAiMemory {
  studentId: string;
  tenantId: string;
  learningPace: LearningPace;
  preferredStyle: PreferredStyle;
  tonePreference: TonePreference;
  academicTrack: string;
  weakTopics: string[];
  emotionalTriggers: string[];
  studyHabits: {
    preferredSessionMinutes?: number;
    prefersHintsFirst?: boolean;
    needsFrequentCheckIns?: boolean;
  };
  internalAnalyticalWeights: {
    empathyWeight: number;
    socraticWeight: number;
    stepGranularity: number;
  };
  lastEmotion: EmotionalPulse;
  totalSessionsCount: number;
  recentSessions: StudentAiSessionSummary[];
  updatedAtMillis: number;
}

export interface AiTelemetryRecord {
  id: string;
  anonymizedActorHash: string;
  interactionLane: RoutingLane;
  detectedEmotion: EmotionalPulse;
  modelId: string;
  providerId: string;
  ttftMs: number;
  totalLatencyMs: number;
  failoverOccurred: boolean;
  promptInjectionFlagged: boolean;
  cheatingAttemptFlagged: boolean;
  sanitizedPromptExcerpt: string;
  sanitizedResponseExcerpt: string;
  pedagogicalStrategy: string;
  qualitySignal: number;
  createdAtMillis: number;
}

export interface TelemetryStatsSnapshot {
  totalRecords: number;
  avgTtftMs: number;
  p95TtftMs: number;
  failoverCount: number;
  injectionBlockedCount: number;
  cheatingBlockedCount: number;
  emotionBreakdown: Record<string, number>;
  laneBreakdown: Record<string, number>;
  modelBreakdown: Record<string, number>;
}

const MAX_TELEMETRY_RING = 20_000;
const MAX_MEMORIES_CACHED = 15_000;

export function scrubPiiAndSecrets(input: string): string {
  const raw = String(input ?? "");
  return raw
    // 14-digit Egyptian National ID (must run before mobile numbers so embedded 010... sequences are not misclassified)
    .replace(/\b[23]\d{13}\b/g, "[NID_REDACTED]")
    // Egyptian mobile numbers (+2010..., 002010..., 2010..., 010..., 011..., 012..., 015...)
    .replace(/(?<!\d)(?:\+?2|002)?01[0125]\d{8}(?!\d)/g, "[PHONE_REDACTED]")
    // Emails
    .replace(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g, "[EMAIL_REDACTED]")
    // Secrets, Bearer tokens, API keys
    .replace(/(Bearer\s+[A-Za-z0-9._-]+|sk-[A-Za-z0-9_-]{8,}|gsk_[A-Za-z0-9_-]{8,}|sb_secret_[A-Za-z0-9_-]{6,})/gi, "[SECRET_REDACTED]")
    .slice(0, 1200);
}

export function hashActorId(actorId: string): string {
  return crypto
    .createHash("sha256")
    .update(`${actorId || "anonymous"}:kashkool-telemetry-salt-2026`)
    .digest("hex");
}

function defaultMemoryFor(studentId: string): StudentAiMemory {
  return {
    studentId,
    tenantId: "demo-centre",
    learningPace: "balanced",
    preferredStyle: "step_by_step",
    tonePreference: "warm_egyptian",
    academicTrack: "الثانوية العامة (رياضيات وفيزياء)",
    weakTopics: ["تطبيقات القيم العظمى والصغرى", "قانون كيرشوف الثاني"],
    emotionalTriggers: [],
    studyHabits: {
      preferredSessionMinutes: 15,
      prefersHintsFirst: true,
      needsFrequentCheckIns: true,
    },
    internalAnalyticalWeights: {
      empathyWeight: 0.85,
      socraticWeight: 0.78,
      stepGranularity: 3,
    },
    lastEmotion: "CALM",
    totalSessionsCount: 0,
    recentSessions: [],
    updatedAtMillis: Date.now(),
  };
}

function normalizeRole(actorRole: string): string {
  return String(actorRole ?? "").trim().toLowerCase();
}

export class CognitiveMemoryVaultService {
  private memories = new Map<string, StudentAiMemory>();
  private telemetryRing: AiTelemetryRecord[] = [];
  private serviceSupabase: SupabaseClient | null = null;

  constructor() {
    this.initServiceSupabase();
    this.seedInitialDemoMemory();
  }

  private initServiceSupabase(): void {
    const url = (process.env.SUPABASE_URL ?? process.env.VITE_SUPABASE_URL ?? "").trim();
    const serviceKey = (process.env.SUPABASE_SERVICE_ROLE_KEY ?? "").trim();
    if (url && serviceKey && /^https?:\/\//i.test(url)) {
      this.serviceSupabase = createClient(url, serviceKey, {
        auth: { persistSession: false, autoRefreshToken: false },
      });
    }
  }

  private seedInitialDemoMemory(): void {
    const stu1 = defaultMemoryFor("stu-1");
    stu1.recentSessions = [
      {
        id: "sess-seed-1",
        subject: "الفيزياء - كيرشوف",
        detectedEmotion: "EXAM_ANXIETY",
        routingLane: "DEEP_COGNITIVE_REASONING",
        topicSummary: "مراجعة قاعدة الإشارات في المسار المغلق",
        createdAtMillis: Date.now() - 3600_000 * 6,
      },
    ];
    stu1.totalSessionsCount = 1;
    this.memories.set("stu-1", stu1);
  }

  private assertMemoryOwnership(studentId: string, actorId: string, actorRole: string): void {
    const role = normalizeRole(actorRole);
    if (role === "super_admin") return;
    if (!actorId || actorId.trim() !== studentId.trim()) {
      throw new Error("FORBIDDEN: Cross-student adaptive memory access denied.");
    }
  }

  private assertSuperAdmin(actorRole: string): void {
    if (normalizeRole(actorRole) !== "super_admin") {
      throw new Error("FORBIDDEN: Super-Admin privilege required to access AI telemetry vault.");
    }
  }

  private getOrCreateInternalMemory(studentId: string): StudentAiMemory {
    const existing = this.memories.get(studentId);
    if (existing) return existing;
    if (this.memories.size >= MAX_MEMORIES_CACHED) {
      const oldestKey = this.memories.keys().next().value;
      if (oldestKey) this.memories.delete(oldestKey);
    }
    const created = defaultMemoryFor(studentId);
    this.memories.set(studentId, created);
    return created;
  }

  /** Internal server-only read used by Layer 2 Cognitive Context Fusion */
  getInternalMemorySnapshot(studentId: string): StudentAiMemory {
    return this.getOrCreateInternalMemory(studentId);
  }

  getMemoryForStudent(studentId: string, actorId: string, actorRole: string): StudentAiMemory {
    const targetId = studentId.trim();
    if (!targetId) throw new Error("VALIDATION: studentId is required.");
    this.assertMemoryOwnership(targetId, actorId, actorRole);
    const mem = this.getOrCreateInternalMemory(targetId);
    // Strip internal analytical weights for non-super_admin student view
    if (normalizeRole(actorRole) === "super_admin") {
      return mem;
    }
    return {
      ...mem,
      internalAnalyticalWeights: {
        empathyWeight: mem.internalAnalyticalWeights.empathyWeight,
        socraticWeight: mem.internalAnalyticalWeights.socraticWeight,
        stepGranularity: mem.internalAnalyticalWeights.stepGranularity,
      },
    };
  }

  updatePreferencesForStudent(params: {
    studentId: string;
    actorId: string;
    actorRole: string;
    learningPace?: LearningPace;
    preferredStyle?: PreferredStyle;
    tonePreference?: TonePreference;
    academicTrack?: string;
    weakTopics?: string[];
    prefersHintsFirst?: boolean;
    preferredSessionMinutes?: number;
  }): StudentAiMemory {
    const targetId = params.studentId.trim();
    if (!targetId) throw new Error("VALIDATION: studentId is required.");
    this.assertMemoryOwnership(targetId, params.actorId, params.actorRole);

    const validPaces: LearningPace[] = ["gentle", "balanced", "intensive"];
    const validStyles: PreferredStyle[] = ["step_by_step", "visual_examples", "socratic", "concise_summary"];
    const validTones: TonePreference[] = ["warm_egyptian", "calm_academic", "encouraging_coach"];

    const current = this.getOrCreateInternalMemory(targetId);
    const updated: StudentAiMemory = {
      ...current,
      learningPace:
        params.learningPace && validPaces.includes(params.learningPace)
          ? params.learningPace
          : current.learningPace,
      preferredStyle:
        params.preferredStyle && validStyles.includes(params.preferredStyle)
          ? params.preferredStyle
          : current.preferredStyle,
      tonePreference:
        params.tonePreference && validTones.includes(params.tonePreference)
          ? params.tonePreference
          : current.tonePreference,
      academicTrack: params.academicTrack?.trim()
        ? scrubPiiAndSecrets(params.academicTrack.trim()).slice(0, 120)
        : current.academicTrack,
      weakTopics: Array.isArray(params.weakTopics)
        ? params.weakTopics.map((x) => scrubPiiAndSecrets(String(x).trim())).filter(Boolean).slice(0, 12)
        : current.weakTopics,
      studyHabits: {
        ...current.studyHabits,
        ...(typeof params.prefersHintsFirst === "boolean"
          ? { prefersHintsFirst: params.prefersHintsFirst }
          : {}),
        ...(typeof params.preferredSessionMinutes === "number"
          ? {
              preferredSessionMinutes: Math.min(60, Math.max(5, Math.round(params.preferredSessionMinutes))),
            }
          : {}),
      },
      updatedAtMillis: Date.now(),
    };

    this.memories.set(targetId, updated);
    this.syncMemoryToSupabaseAsync(updated);
    return updated;
  }

  resetPreferencesForStudent(studentId: string, actorId: string, actorRole: string): StudentAiMemory {
    const targetId = studentId.trim();
    if (!targetId) throw new Error("VALIDATION: studentId is required.");
    this.assertMemoryOwnership(targetId, actorId, actorRole);
    const fresh = defaultMemoryFor(targetId);
    fresh.weakTopics = [];
    fresh.emotionalTriggers = [];
    this.memories.set(targetId, fresh);
    this.syncMemoryToSupabaseAsync(fresh);
    return fresh;
  }

  recordInteractionInMemory(params: {
    studentId: string;
    subject: string;
    emotion: EmotionalPulse;
    lane: RoutingLane;
    promptExcerpt: string;
  }): StudentAiMemory {
    const mem = this.getOrCreateInternalMemory(params.studentId);
    const cleanTopic = scrubPiiAndSecrets(params.promptExcerpt).slice(0, 90);
    const nextTriggers = new Set(mem.emotionalTriggers);
    if (
      params.emotion === "EXAM_ANXIETY" ||
      params.emotion === "FRUSTRATION" ||
      params.emotion === "BURNOUT" ||
      params.emotion === "LOW_CONFIDENCE"
    ) {
      nextTriggers.add(params.emotion);
    }

    const nextWeak = [...mem.weakTopics];
    const cleanSubject = scrubPiiAndSecrets(params.subject).trim();
    if (
      cleanSubject &&
      (params.emotion === "FRUSTRATION" || params.emotion === "EXAM_ANXIETY") &&
      !nextWeak.includes(cleanSubject)
    ) {
      nextWeak.unshift(cleanSubject);
    }

    const nextSession: StudentAiSessionSummary = {
      id: `sess-${Date.now()}-${crypto.randomUUID().slice(0, 5)}`,
      subject: cleanSubject || "General",
      detectedEmotion: params.emotion,
      routingLane: params.lane,
      topicSummary: cleanTopic,
      createdAtMillis: Date.now(),
    };

    const updated: StudentAiMemory = {
      ...mem,
      lastEmotion: params.emotion,
      emotionalTriggers: Array.from(nextTriggers).slice(0, 6),
      weakTopics: nextWeak.slice(0, 10),
      totalSessionsCount: mem.totalSessionsCount + 1,
      recentSessions: [nextSession, ...mem.recentSessions].slice(0, 8),
      internalAnalyticalWeights: {
        empathyWeight:
          params.emotion === "EXAM_ANXIETY" || params.emotion === "BURNOUT"
            ? Math.min(1, mem.internalAnalyticalWeights.empathyWeight + 0.03)
            : mem.internalAnalyticalWeights.empathyWeight,
        socraticWeight: mem.internalAnalyticalWeights.socraticWeight,
        stepGranularity:
          params.emotion === "FRUSTRATION" || params.emotion === "BURNOUT"
            ? 4
            : mem.internalAnalyticalWeights.stepGranularity,
      },
      updatedAtMillis: Date.now(),
    };

    this.memories.set(params.studentId, updated);
    this.syncMemoryToSupabaseAsync(updated);
    return updated;
  }

  ingestTelemetry(input: {
    actorId: string;
    interactionLane: RoutingLane;
    detectedEmotion: EmotionalPulse;
    modelId: string;
    providerId: string;
    ttftMs: number;
    totalLatencyMs: number;
    failoverOccurred: boolean;
    promptInjectionFlagged: boolean;
    cheatingAttemptFlagged: boolean;
    promptExcerpt: string;
    responseExcerpt: string;
    pedagogicalStrategy: string;
    qualitySignal?: number;
  }): AiTelemetryRecord {
    const record: AiTelemetryRecord = {
      id: `tel-${Date.now()}-${crypto.randomUUID().slice(0, 8)}`,
      anonymizedActorHash: hashActorId(input.actorId),
      interactionLane: input.interactionLane,
      detectedEmotion: input.detectedEmotion,
      modelId: input.modelId,
      providerId: input.providerId,
      ttftMs: Math.max(0, Math.round(input.ttftMs)),
      totalLatencyMs: Math.max(0, Math.round(input.totalLatencyMs)),
      failoverOccurred: Boolean(input.failoverOccurred),
      promptInjectionFlagged: Boolean(input.promptInjectionFlagged),
      cheatingAttemptFlagged: Boolean(input.cheatingAttemptFlagged),
      sanitizedPromptExcerpt: scrubPiiAndSecrets(input.promptExcerpt),
      sanitizedResponseExcerpt: scrubPiiAndSecrets(input.responseExcerpt),
      pedagogicalStrategy: input.pedagogicalStrategy.slice(0, 160),
      qualitySignal: Math.min(1, Math.max(0, input.qualitySignal ?? 0.92)),
      createdAtMillis: Date.now(),
    };

    if (this.telemetryRing.length >= MAX_TELEMETRY_RING) {
      this.telemetryRing.shift();
    }
    this.telemetryRing.push(record);

    this.ingestTelemetrySupabaseAsync(record, input.actorId);
    return record;
  }

  listTelemetryForSuperAdmin(
    actorRole: string,
    filters?: { emotion?: string; lane?: string; limit?: number }
  ): { records: AiTelemetryRecord[]; stats: TelemetryStatsSnapshot } {
    this.assertSuperAdmin(actorRole);

    const limit = Math.min(200, Math.max(10, filters?.limit ?? 80));
    let filtered = this.telemetryRing;
    if (filters?.emotion) {
      filtered = filtered.filter((r) => r.detectedEmotion === filters.emotion);
    }
    if (filters?.lane) {
      filtered = filtered.filter((r) => r.interactionLane === filters.lane);
    }

    const totalRecords = this.telemetryRing.length;
    const ttfts = this.telemetryRing.map((r) => r.ttftMs).sort((a, b) => a - b);
    const avgTtftMs = totalRecords > 0 ? Math.round(ttfts.reduce((s, v) => s + v, 0) / totalRecords) : 0;
    const p95TtftMs = totalRecords > 0 ? ttfts[Math.min(totalRecords - 1, Math.floor(totalRecords * 0.95))] : 0;

    const emotionBreakdown: Record<string, number> = {};
    const laneBreakdown: Record<string, number> = {};
    const modelBreakdown: Record<string, number> = {};
    let failoverCount = 0;
    let injectionBlockedCount = 0;
    let cheatingBlockedCount = 0;

    for (const r of this.telemetryRing) {
      emotionBreakdown[r.detectedEmotion] = (emotionBreakdown[r.detectedEmotion] ?? 0) + 1;
      laneBreakdown[r.interactionLane] = (laneBreakdown[r.interactionLane] ?? 0) + 1;
      modelBreakdown[r.modelId] = (modelBreakdown[r.modelId] ?? 0) + 1;
      if (r.failoverOccurred) failoverCount++;
      if (r.promptInjectionFlagged) injectionBlockedCount++;
      if (r.cheatingAttemptFlagged) cheatingBlockedCount++;
    }

    const recent = filtered.slice(-limit).reverse();
    return {
      records: recent,
      stats: {
        totalRecords,
        avgTtftMs,
        p95TtftMs,
        failoverCount,
        injectionBlockedCount,
        cheatingBlockedCount,
        emotionBreakdown,
        laneBreakdown,
        modelBreakdown,
      },
    };
  }

  exportTelemetryJsonlForSuperAdmin(actorRole: string): string {
    this.assertSuperAdmin(actorRole);
    return this.telemetryRing
      .map((r) =>
        JSON.stringify({
          id: r.id,
          actorHash: r.anonymizedActorHash,
          lane: r.interactionLane,
          emotion: r.detectedEmotion,
          modelId: r.modelId,
          providerId: r.providerId,
          strategy: r.pedagogicalStrategy,
          prompt: r.sanitizedPromptExcerpt,
          completion: r.sanitizedResponseExcerpt,
          ttftMs: r.ttftMs,
          failoverOccurred: r.failoverOccurred,
          promptInjectionFlagged: r.promptInjectionFlagged,
          cheatingAttemptFlagged: r.cheatingAttemptFlagged,
          createdAt: new Date(r.createdAtMillis).toISOString(),
        })
      )
      .join("\n");
  }

  private syncMemoryToSupabaseAsync(mem: StudentAiMemory): void {
    if (!this.serviceSupabase) return;
    void Promise.resolve(
      this.serviceSupabase.from("student_ai_memories").upsert({
        student_id: mem.studentId,
        tenant_id: mem.tenantId,
        learning_pace: mem.learningPace,
        preferred_style: mem.preferredStyle,
        tone_preference: mem.tonePreference,
        academic_track: mem.academicTrack,
        weak_topics: mem.weakTopics,
        emotional_triggers: mem.emotionalTriggers,
        study_habits: mem.studyHabits,
        internal_analytical_weights: mem.internalAnalyticalWeights,
        last_emotion: mem.lastEmotion,
        total_sessions_count: mem.totalSessionsCount,
        updated_at: new Date(mem.updatedAtMillis).toISOString(),
      })
    ).catch(() => undefined);
  }

  private ingestTelemetrySupabaseAsync(record: AiTelemetryRecord, rawActorId: string): void {
    if (!this.serviceSupabase) return;
    void Promise.resolve(
      this.serviceSupabase.rpc("ingest_ai_training_telemetry", {
        p_actor_id: rawActorId,
        p_interaction_lane: record.interactionLane,
        p_detected_emotion: record.detectedEmotion,
        p_model_id: record.modelId,
        p_provider_id: record.providerId,
        p_ttft_ms: record.ttftMs,
        p_total_latency_ms: record.totalLatencyMs,
        p_failover_occurred: record.failoverOccurred,
        p_prompt_injection_flagged: record.promptInjectionFlagged,
        p_cheating_attempt_flagged: record.cheatingAttemptFlagged,
        p_prompt_excerpt: record.sanitizedPromptExcerpt,
        p_response_excerpt: record.sanitizedResponseExcerpt,
        p_pedagogical_strategy: record.pedagogicalStrategy,
        p_quality_signal: record.qualitySignal,
      })
    ).catch(() => undefined);
  }
}

export const cognitiveMemoryVault = new CognitiveMemoryVaultService();
