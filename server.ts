import express, { type Express } from "express";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { createServer as createViteServer } from "vite";
import {
  KashkoolAiRouter,
  kashkoolAiRouter,
  runCognitivePipeline,
  sanitizeCognitiveOutput,
  type ChatWireMessage,
} from "./server/kashkoolAiRouter";
import { cognitiveMemoryVault } from "./server/cognitiveMemoryVault";
import { readServerSupabaseConfig } from "./server/supabaseServer";
import { aegisSecurity } from "./server/aegisSecurity";
import { examFortress, type ExamQuestionInput, type ExamViolationType } from "./server/examFortress";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
try {
  process.loadEnvFile?.();
} catch {
  // No local .env file present; rely on injected environment variables
}

const PORT = 3000;

function isValidImageDataUrl(dataUrl: string): boolean {
  return /^data:image\/[a-zA-Z0-9.+-]+;base64,.+$/.test(dataUrl.trim());
}

function errorMessage(err: unknown): string {
  if (err instanceof Error) return err.message;
  return "Request failed";
}

function statusFromServiceError(err: unknown): number {
  const msg = errorMessage(err);
  if (msg.startsWith("FORBIDDEN:")) return 403;
  if (msg.startsWith("NOT_FOUND:")) return 404;
  if (msg.startsWith("DEADLINE_EXPIRED:")) return 409;
  if (msg.startsWith("VALIDATION:")) return 400;
  return 500;
}

function readActorContext(req: express.Request): { actorId: string; actorRole: string } {
  const body = (req.body ?? {}) as Record<string, unknown>;
  const headerRole = req.header("x-kashkool-role")?.trim();
  const headerActor = req.header("x-kashkool-actor")?.trim();
  const actorRole = String(headerRole || body.actorRole || req.query.role || "student").trim().toLowerCase();
  const actorId = String(headerActor || body.studentId || body.actorId || req.query.studentId || req.ip || "stu-1").trim();
  return { actorId, actorRole };
}

export async function createKashkoolApp(options?: {
  skipVite?: boolean;
  router?: KashkoolAiRouter;
}): Promise<Express> {
  const aiRouter = options?.router ?? kashkoolAiRouter;
  const app = express();
  app.use(express.json({ limit: "8mb" }));

  app.get("/api/health", (_req, res) => {
    const stats = aiRouter.getStats();
    const supabaseCfg = readServerSupabaseConfig();
    res.json({
      ok: true,
      aiReady: stats.keylessReady,
      engine: "kashkool-ai-client",
      cognitivePipelineActive: true,
      providerStats: stats,
      supabaseConfigured: Boolean(supabaseCfg),
      aegisActive: true,
      examFortressActive: true,
    });
  });

  app.get("/api/supabase/config", (_req, res) => {
    const cfg = readServerSupabaseConfig();
    if (!cfg) {
      return res.json({ configured: false, browserReady: false });
    }
    if (!cfg.isPublicAnonKey) {
      return res.json({
        configured: true,
        browserReady: false,
        serverOnly: true,
      });
    }
    res.json({
      configured: true,
      browserReady: true,
      url: cfg.url,
      anonKey: cfg.key,
    });
  });

  // ---------------------------------------------------------------------------
  // KASHKOOL EXAM FORTRESS (Server-Authoritative, Zero-Cheat Assessment Engine)
  // ---------------------------------------------------------------------------
  app.get("/api/exams", (req, res) => {
    try {
      const { actorId, actorRole } = readActorContext(req);
      const list = examFortress.listExamsForRole(actorRole, actorId);
      res.json({ exams: list });
    } catch (err) {
      res.status(statusFromServiceError(err)).json({ error: errorMessage(err) });
    }
  });

  app.post("/api/exams", (req, res) => {
    try {
      const { actorId, actorRole } = readActorContext(req);
      const {
        tenantId,
        groupId,
        titleAr,
        titleEn,
        subjectAr,
        subjectEn,
        durationMinutes,
        passPercent,
        maxViolations,
        questions,
      } = (req.body ?? {}) as {
        tenantId?: string;
        groupId?: string;
        titleAr?: string;
        titleEn?: string;
        subjectAr?: string;
        subjectEn?: string;
        durationMinutes?: number;
        passPercent?: number;
        maxViolations?: number;
        questions?: ExamQuestionInput[];
      };

      const created = examFortress.createExam({
        tenantId,
        groupId: groupId ?? "grp-math-3sec",
        titleAr: titleAr ?? "",
        titleEn,
        subjectAr: subjectAr ?? "الرياضيات البحتة",
        subjectEn,
        durationMinutes: durationMinutes ?? 20,
        passPercent,
        maxViolations,
        questions: questions ?? [],
        actorId,
        actorRole,
      });
      res.status(201).json({ exam: created });
    } catch (err) {
      res.status(statusFromServiceError(err)).json({ error: errorMessage(err) });
    }
  });

  app.post("/api/exams/:examId/start", (req, res) => {
    try {
      const { examId } = req.params;
      const { actorId } = readActorContext(req);
      const { studentId, studentName, studentCode, deviceId } = (req.body ?? {}) as {
        studentId?: string;
        studentName?: string;
        studentCode?: string;
        deviceId?: string;
      };
      const payload = examFortress.startAttempt({
        examId,
        studentId: studentId?.trim() || actorId,
        studentName: studentName?.trim() || "طالب كشكول",
        studentCode,
        deviceId: deviceId?.trim() || "web-client",
      });
      res.json(payload);
    } catch (err) {
      res.status(statusFromServiceError(err)).json({ error: errorMessage(err) });
    }
  });

  app.post("/api/exams/attempts/:attemptId/answer", (req, res) => {
    try {
      const { attemptId } = req.params;
      const { actorId } = readActorContext(req);
      const { studentId, questionId, selectedDisplayIndex, deviceId } = (req.body ?? {}) as {
        studentId?: string;
        questionId?: string;
        selectedDisplayIndex?: number;
        deviceId?: string;
      };
      const result = examFortress.upsertAnswer({
        attemptId,
        studentId: studentId?.trim() || actorId,
        questionId: String(questionId ?? ""),
        selectedDisplayIndex: Number(selectedDisplayIndex),
        deviceId,
      });
      if (!result.saved && result.status === "expired") {
        return res.status(409).json(result);
      }
      res.json(result);
    } catch (err) {
      res.status(statusFromServiceError(err)).json({ error: errorMessage(err) });
    }
  });

  app.post("/api/exams/attempts/:attemptId/heartbeat", (req, res) => {
    try {
      const { attemptId } = req.params;
      const { actorId } = readActorContext(req);
      const { studentId, eventType, detail, deviceId } = (req.body ?? {}) as {
        studentId?: string;
        eventType?: ExamViolationType;
        detail?: string;
        deviceId?: string;
      };
      const validTypes: ExamViolationType[] = [
        "heartbeat",
        "tab_switch",
        "window_blur",
        "fullscreen_exit",
        "copy_attempt",
        "paste_attempt",
        "screen_capture_key",
        "split_screen",
        "dev_tools",
      ];
      const safeType = eventType && validTypes.includes(eventType) ? eventType : "heartbeat";
      const out = examFortress.recordHeartbeat({
        attemptId,
        studentId: studentId?.trim() || actorId,
        eventType: safeType,
        detail,
        deviceId,
      });
      res.json(out);
    } catch (err) {
      res.status(statusFromServiceError(err)).json({ error: errorMessage(err) });
    }
  });

  app.post("/api/exams/attempts/:attemptId/submit", (req, res) => {
    try {
      const { attemptId } = req.params;
      const { actorId, actorRole } = readActorContext(req);
      const { studentId } = (req.body ?? {}) as { studentId?: string };
      const graded = examFortress.submitAndGrade({
        attemptId,
        studentId: studentId?.trim() || actorId,
        actorRole,
      });
      res.json(graded);
    } catch (err) {
      res.status(statusFromServiceError(err)).json({ error: errorMessage(err) });
    }
  });

  app.get("/api/exams/attempts/:attemptId/result", (req, res) => {
    try {
      const { attemptId } = req.params;
      const { actorId, actorRole } = readActorContext(req);
      const result = examFortress.getAttemptResult(attemptId, actorId, actorRole);
      res.json(result);
    } catch (err) {
      res.status(statusFromServiceError(err)).json({ error: errorMessage(err) });
    }
  });

  app.get("/api/exams/:examId/attempts", (req, res) => {
    try {
      const { examId } = req.params;
      const { actorRole } = readActorContext(req);
      const attempts = examFortress.listAttemptsForExam(examId, actorRole);
      res.json({ attempts });
    } catch (err) {
      res.status(statusFromServiceError(err)).json({ error: errorMessage(err) });
    }
  });

  app.post("/api/exams/attempts/:attemptId/lock", (req, res) => {
    try {
      const { attemptId } = req.params;
      const { actorId, actorRole } = readActorContext(req);
      const result = examFortress.forceLockAttempt(attemptId, actorId, actorRole);
      res.json(result);
    } catch (err) {
      res.status(statusFromServiceError(err)).json({ error: errorMessage(err) });
    }
  });

  app.get("/api/certificates/:certId/verify", (req, res) => {
    const cert = examFortress.verifyCertificate(req.params.certId);
    if (!cert) {
      return res.status(404).json({ valid: false, error: "Certificate not found" });
    }
    res.json({ valid: true, certificate: cert });
  });

  // ---------------------------------------------------------------------------
  // KASHKOOL AEGIS SHIELD (HMAC Anti-Replay, Device Binding, Immutable Audit)
  // ---------------------------------------------------------------------------
  app.post("/api/security/qr/verify", (req, res) => {
    const { rawPayload, nonce, sessionId } = (req.body ?? {}) as {
      rawPayload?: string;
      nonce?: string;
      sessionId?: string;
    };
    if (!rawPayload || typeof rawPayload !== "string") {
      return res.status(400).json({ error: "rawPayload is required" });
    }
    const result = aegisSecurity.verifyDynamicQrAntiReplay({ rawPayload, nonce, sessionId });
    res.json(result);
  });

  app.post("/api/security/device/bind", (req, res) => {
    const { tenantId, actorId, deviceFingerprint, deviceLabel } = (req.body ?? {}) as {
      tenantId?: string;
      actorId?: string;
      deviceFingerprint?: string;
      deviceLabel?: string;
    };
    if (!actorId || !deviceFingerprint) {
      return res.status(400).json({ error: "actorId and deviceFingerprint are required" });
    }
    const out = aegisSecurity.bindDevice({
      tenantId: tenantId || "demo-centre",
      actorId,
      deviceFingerprint,
      deviceLabel: deviceLabel || "Web Browser",
    });
    res.json(out);
  });

  app.post("/api/security/device/revoke", (req, res) => {
    const { actorId, actorRole } = readActorContext(req);
    if (!["teacher", "secretary", "center_admin"].includes(actorRole)) {
      return res.status(403).json({ error: "FORBIDDEN: Staff role required to revoke devices." });
    }
    const { deviceId } = (req.body ?? {}) as { deviceId?: string };
    if (!deviceId) {
      return res.status(400).json({ error: "deviceId is required" });
    }
    const revoked = aegisSecurity.revokeDevice(deviceId, actorId);
    if (!revoked) {
      return res.status(404).json({ error: "Device binding not found" });
    }
    res.json({ revoked });
  });

  app.get("/api/security/devices", (req, res) => {
    const { actorRole } = readActorContext(req);
    if (!["teacher", "secretary", "center_admin"].includes(actorRole)) {
      return res.status(403).json({ error: "FORBIDDEN: Staff role required." });
    }
    const tenantId = String(req.query.tenantId ?? "demo-centre");
    res.json({ devices: aegisSecurity.listDevices(tenantId) });
  });

  app.get("/api/security/audit-logs", (req, res) => {
    const { actorRole } = readActorContext(req);
    if (!["teacher", "secretary", "center_admin"].includes(actorRole)) {
      return res.status(403).json({ error: "FORBIDDEN: Staff role required." });
    }
    const tenantId = String(req.query.tenantId ?? "demo-centre");
    const limit = Math.min(200, Math.max(10, Number(req.query.limit) || 60));
    res.json({ logs: aegisSecurity.listAuditLogs(tenantId, limit) });
  });

  // ---------------------------------------------------------------------------
  // KASHKOOL AI CLIENT ROUTES (4-Layer Cognitive Engine + Memory + Super-Admin Vault)
  // ---------------------------------------------------------------------------
  app.get("/api/ai/memory", (req, res) => {
    try {
      const { actorId, actorRole } = readActorContext(req);
      const studentId = String(req.query.studentId ?? actorId).trim();
      const memory = cognitiveMemoryVault.getMemoryForStudent(studentId, actorId, actorRole);
      res.json({ memory });
    } catch (err) {
      res.status(statusFromServiceError(err)).json({ error: errorMessage(err) });
    }
  });

  app.put("/api/ai/memory", (req, res) => {
    try {
      const { actorId, actorRole } = readActorContext(req);
      const body = (req.body ?? {}) as {
        studentId?: string;
        learningPace?: "gentle" | "balanced" | "intensive";
        preferredStyle?: "step_by_step" | "visual_examples" | "socratic" | "concise_summary";
        tonePreference?: "warm_egyptian" | "calm_academic" | "encouraging_coach";
        academicTrack?: string;
        weakTopics?: string[];
        prefersHintsFirst?: boolean;
        preferredSessionMinutes?: number;
      };
      const studentId = String(body.studentId ?? actorId).trim();
      const memory = cognitiveMemoryVault.updatePreferencesForStudent({
        studentId,
        actorId,
        actorRole,
        learningPace: body.learningPace,
        preferredStyle: body.preferredStyle,
        tonePreference: body.tonePreference,
        academicTrack: body.academicTrack,
        weakTopics: body.weakTopics,
        prefersHintsFirst: body.prefersHintsFirst,
        preferredSessionMinutes: body.preferredSessionMinutes,
      });
      res.json({ memory });
    } catch (err) {
      res.status(statusFromServiceError(err)).json({ error: errorMessage(err) });
    }
  });

  app.delete("/api/ai/memory", (req, res) => {
    try {
      const { actorId, actorRole } = readActorContext(req);
      const studentId = String(req.query.studentId ?? (req.body as { studentId?: string } | undefined)?.studentId ?? actorId).trim();
      const memory = cognitiveMemoryVault.resetPreferencesForStudent(studentId, actorId, actorRole);
      res.json({ memory });
    } catch (err) {
      res.status(statusFromServiceError(err)).json({ error: errorMessage(err) });
    }
  });

  // Write-only telemetry ingestion (scrubbed & anonymized; never exposes telemetry records)
  app.post("/api/ai/telemetry-ingest", (req, res) => {
    try {
      const { actorId } = readActorContext(req);
      const body = (req.body ?? {}) as {
        studentId?: string;
        subject?: string;
        emotion?: string;
        lane?: string;
        modelId?: string;
        providerId?: string;
        ttftMs?: number;
        totalLatencyMs?: number;
        failoverOccurred?: boolean;
        promptInjectionFlagged?: boolean;
        cheatingAttemptFlagged?: boolean;
        promptExcerpt?: string;
        responseExcerpt?: string;
        strategyCode?: string;
      };
      const targetStudent = String(body.studentId ?? actorId).trim();
      const emotion = (body.emotion ?? "CALM") as Parameters<typeof cognitiveMemoryVault.ingestTelemetry>[0]["detectedEmotion"];
      const lane = (body.lane ?? "ULTRA_FAST_EMPATHETIC") as Parameters<typeof cognitiveMemoryVault.ingestTelemetry>[0]["interactionLane"];

      cognitiveMemoryVault.recordInteractionInMemory({
        studentId: targetStudent,
        subject: String(body.subject ?? "General"),
        emotion,
        lane,
        promptExcerpt: String(body.promptExcerpt ?? ""),
      });

      const ingested = cognitiveMemoryVault.ingestTelemetry({
        actorId: targetStudent,
        interactionLane: lane,
        detectedEmotion: emotion,
        modelId: String(body.modelId ?? "direct-browser"),
        providerId: String(body.providerId ?? "llm7"),
        ttftMs: Number(body.ttftMs ?? 240),
        totalLatencyMs: Number(body.totalLatencyMs ?? 480),
        failoverOccurred: Boolean(body.failoverOccurred),
        promptInjectionFlagged: Boolean(body.promptInjectionFlagged),
        cheatingAttemptFlagged: Boolean(body.cheatingAttemptFlagged),
        promptExcerpt: String(body.promptExcerpt ?? ""),
        responseExcerpt: String(body.responseExcerpt ?? ""),
        pedagogicalStrategy: String(body.strategyCode ?? `${emotion} -> ${lane}`),
      });

      res.status(201).json({ ok: true, id: ingested.id });
    } catch (err) {
      res.status(statusFromServiceError(err)).json({ error: errorMessage(err) });
    }
  });

  // STRICT SUPER-ADMIN-ONLY TELEMETRY VAULT (403 for student/teacher/secretary/center_admin/parent)
  app.get("/api/admin/telemetry", (req, res) => {
    try {
      const { actorRole } = readActorContext(req);
      const emotion = typeof req.query.emotion === "string" ? req.query.emotion : undefined;
      const lane = typeof req.query.lane === "string" ? req.query.lane : undefined;
      const limit = Number(req.query.limit ?? 80);
      const vault = cognitiveMemoryVault.listTelemetryForSuperAdmin(actorRole, { emotion, lane, limit });
      res.json(vault);
    } catch (err) {
      res.status(statusFromServiceError(err)).json({ error: errorMessage(err) });
    }
  });

  app.get("/api/admin/telemetry/export", (req, res) => {
    try {
      const { actorRole } = readActorContext(req);
      const jsonl = cognitiveMemoryVault.exportTelemetryJsonlForSuperAdmin(actorRole);
      res.setHeader("Content-Type", "application/x-ndjson; charset=utf-8");
      res.setHeader("Content-Disposition", 'attachment; filename="kashkool-ai-telemetry.jsonl"');
      res.send(jsonl);
    } catch (err) {
      res.status(statusFromServiceError(err)).json({ error: errorMessage(err) });
    }
  });

  // 1. Multi-turn streaming study helper via kashkool-ai-client + 4-Layer Cognitive Engine
  app.post("/api/ai/study-chat", async (req, res) => {
    const startedAt = Date.now();
    try {
      const {
        prompt,
        history = [],
        photoDataUrl,
        role,
        subject,
        knapsackSummary,
        certaintyScore,
        lang,
        explicitMood,
        studentId,
      } = req.body ?? {};
      const { actorId } = readActorContext(req);
      const memoryOwnerId = String(studentId ?? actorId).trim() || "stu-1";
      const memory = cognitiveMemoryVault.getInternalMemorySnapshot(memoryOwnerId);

      const hasValidPhoto = typeof photoDataUrl === "string" && isValidImageDataUrl(photoDataUrl);
      const historyMessages: ChatWireMessage[] = Array.isArray(history)
        ? history.slice(1).map((m: { fromUser?: boolean; text?: string }) => ({
            role: m.fromUser ? ("user" as const) : ("assistant" as const),
            content: String(m.text ?? ""),
          }))
        : [];

      const plan = runCognitivePipeline({
        message: String(prompt ?? ""),
        history: historyMessages,
        memory,
        explicitMood: typeof explicitMood === "string" ? explicitMood : null,
        hasVisionMedia: hasValidPhoto,
        lang: lang === "en" ? "en" : "ar",
        subject: String(subject ?? "الرياضيات والفيزياء"),
      });

      const langHint = lang === "en" ? "English" : "Arabic (clear Egyptian empathetic style)";
      const contextualPrompt = [
        `Language: ${langHint}`,
        `User Role: ${role ?? "student"}`,
        `Lesson / Context: ${subject ?? "Pure Mathematics & Physics"}`,
        `Verified 15-min Rescue Focus: ${knapsackSummary ?? "On track"}`,
        `System Certainty Score: ${certaintyScore ?? 92}%`,
        "",
        "Student Message:",
        String(prompt ?? ""),
      ].join("\n");

      res.setHeader("Content-Type", "text/event-stream; charset=utf-8");
      res.setHeader("Cache-Control", "no-cache");
      res.setHeader("Connection", "keep-alive");

      // Emit initial cognitive telemetry metadata frame
      res.write(
        `data: ${JSON.stringify({
          meta: {
            emotion: plan.emotion,
            lane: plan.lane,
            strategyAr: plan.strategyAr,
            strategyEn: plan.strategyEn,
            memoryApplied: plan.memoryApplied,
            weakTopicsCount: memory.weakTopics.length,
          },
        })}\n\n`
      );

      // Immediate kind refusal for live-exam cheating without calling upstream
      if (plan.immediateGuardReply) {
        res.write(`data: ${JSON.stringify({ chunk: plan.immediateGuardReply })}\n\n`);
        cognitiveMemoryVault.ingestTelemetry({
          actorId: memoryOwnerId,
          interactionLane: plan.lane,
          detectedEmotion: plan.emotion,
          modelId: "kashkool-cognitive-guard",
          providerId: "internal-guard",
          ttftMs: Date.now() - startedAt,
          totalLatencyMs: Date.now() - startedAt,
          failoverOccurred: false,
          promptInjectionFlagged: plan.promptInjectionDetected,
          cheatingAttemptFlagged: true,
          promptExcerpt: String(prompt ?? ""),
          responseExcerpt: plan.immediateGuardReply,
          pedagogicalStrategy: plan.strategyCode,
          qualitySignal: 1.0,
        });
        res.write(
          `data: ${JSON.stringify({
            done: true,
            model: "kashkool-cognitive-guard",
            emotion: plan.emotion,
            lane: plan.lane,
            ttftMs: Date.now() - startedAt,
            failoverOccurred: false,
          })}\n\n`
        );
        return res.end();
      }

      const messages: ChatWireMessage[] = hasValidPhoto
        ? [
            ...plan.compressedHistory.slice(-4),
            {
              role: "user",
              content: [
                { type: "text", text: contextualPrompt },
                { type: "image_url", image_url: { url: photoDataUrl.trim() } },
              ],
            },
          ]
        : [
            ...plan.compressedHistory,
            {
              role: "user",
              content: contextualPrompt,
            },
          ];

      let emitted = false;
      let rawStreamed = "";
      let lastVisibleLength = 0;

      const stripStreamingThink = (raw: string): string => {
        const withoutClosed = raw.replace(/<think>[\s\S]*?<\/think>/gi, "");
        const openIdx = withoutClosed.toLowerCase().indexOf("<think>");
        const safe = openIdx !== -1 ? withoutClosed.slice(0, openIdx) : withoutClosed;
        return sanitizeCognitiveOutput(safe);
      };

      const result = await aiRouter.chat({
        messages,
        systemPrompt: plan.effectiveSystemPrompt,
        actorId: memoryOwnerId,
        lane: plan.lane,
        requireVision: hasValidPhoto,
        preferFast: plan.lane === "ULTRA_FAST_EMPATHETIC",
        temperature: 0.55,
        onResetStream: () => {
          rawStreamed = "";
          lastVisibleLength = 0;
          if (emitted) {
            emitted = false;
            res.write(`data: ${JSON.stringify({ reset: true })}\n\n`);
          }
        },
        onChunk: (piece) => {
          if (!piece) return;
          rawStreamed += piece;
          const visible = stripStreamingThink(rawStreamed);
          if (visible.length > lastVisibleLength) {
            const delta = visible.slice(lastVisibleLength);
            lastVisibleLength = visible.length;
            emitted = true;
            res.write(`data: ${JSON.stringify({ chunk: delta })}\n\n`);
          }
        },
      });

      const finalSafeText = sanitizeCognitiveOutput(result.text);

      if (!emitted && finalSafeText) {
        res.write(`data: ${JSON.stringify({ chunk: finalSafeText })}\n\n`);
        emitted = true;
      }

      cognitiveMemoryVault.recordInteractionInMemory({
        studentId: memoryOwnerId,
        subject: String(subject ?? "الرياضيات والفيزياء"),
        emotion: plan.emotion,
        lane: plan.lane,
        promptExcerpt: String(prompt ?? ""),
      });

      cognitiveMemoryVault.ingestTelemetry({
        actorId: memoryOwnerId,
        interactionLane: plan.lane,
        detectedEmotion: plan.emotion,
        modelId: result.modelId,
        providerId: result.providerId,
        ttftMs: result.ttftMs,
        totalLatencyMs: Date.now() - startedAt,
        failoverOccurred: result.failoverOccurred,
        promptInjectionFlagged: plan.promptInjectionDetected,
        cheatingAttemptFlagged: plan.cheatingAttemptDetected,
        promptExcerpt: String(prompt ?? ""),
        responseExcerpt: finalSafeText,
        pedagogicalStrategy: plan.strategyCode,
      });

      if (!emitted) {
        res.write(`data: ${JSON.stringify({ error: "Empty response from study helper." })}\n\n`);
      } else {
        res.write(
          `data: ${JSON.stringify({
            done: true,
            model: result.modelId,
            provider: result.providerId,
            emotion: plan.emotion,
            lane: plan.lane,
            ttftMs: result.ttftMs,
            failoverOccurred: result.failoverOccurred,
          })}\n\n`
        );
      }
      res.end();
    } catch (err) {
      if (!res.headersSent) {
        res.status(500).json({ error: errorMessage(err) });
      } else {
        res.write(`data: ${JSON.stringify({ error: errorMessage(err) })}\n\n`);
        res.end();
      }
    }
  });

  // 2. Adaptive Quiz Generator
  app.post("/api/ai/adaptive-quiz", async (req, res) => {
    try {
      const { lessonTitle, lang } = req.body ?? {};
      const langLabel = lang === "ar" ? "Natural Egyptian Arabic (Thanaweya Amma style)" : "Clear English";
      const prompt = [
        `Generate 3 high-quality multiple-choice practice questions strictly focused on: "${String(lessonTitle ?? "")}".`,
        `Output language: ${langLabel}.`,
        "Return ONLY valid JSON (no markdown fences or commentary) matching this exact schema:",
        JSON.stringify({
          questions: [
            {
              topicTag: "string",
              prompt: "string",
              formula: "ASCII/Unicode LTR math or physics expression",
              options: ["opt1", "opt2", "opt3", "opt4"],
              correctIndex: 0,
              remedial: "brief calm 1-sentence explanation hint",
            },
          ],
        }),
      ].join("\n");

      const { actorId } = readActorContext(req);
      const { data } = await aiRouter.chatJson<{ questions?: unknown[] }>({
        messages: [{ role: "user", content: prompt }],
        systemPrompt:
          "You are Kashkool's curriculum quiz author. Output valid JSON strictly following the requested schema.",
        actorId,
        preferFast: true,
        temperature: 0.4,
      });

      res.json(data);
    } catch (err) {
      res.status(500).json({ error: errorMessage(err) });
    }
  });

  // 3. Receipt OCR Scanner (Vision via kilo-nemotron-3.5-super-vl)
  app.post("/api/ai/scan-receipt", async (req, res) => {
    try {
      const { imageDataUrl, lang } = req.body ?? {};
      if (typeof imageDataUrl !== "string" || !isValidImageDataUrl(imageDataUrl)) {
        return res.status(400).json({ error: "Valid receipt image required." });
      }
      const langLabel = lang === "ar" ? "Arabic (Egyptian concise phrasing)" : "English";
      const prompt = [
        "Inspect this Egyptian payment transfer receipt screenshot or photo carefully.",
        "Return ONLY valid JSON matching:",
        JSON.stringify({
          amountEgp: "digits and optional decimal e.g. 240",
          referenceNumber: "string",
          detectedChannelType:
            "one of: insta_pay, vodafone_cash, etisalat_cash, orange_cash, we_pay, fawry, cash_desk, unknown",
          clarityStatus: "one of: high, medium, low",
          verificationNote: `1-sentence verification note in ${langLabel}`,
        }),
      ].join("\n");

      const { actorId } = readActorContext(req);
      const { data } = await aiRouter.chatJson({
        messages: [
          {
            role: "user",
            content: [
              { type: "text", text: prompt },
              { type: "image_url", image_url: { url: imageDataUrl.trim() } },
            ],
          },
        ],
        systemPrompt: "You are a precise Egyptian payment receipt verifier. Respond only with valid JSON.",
        actorId,
        requireVision: true,
        temperature: 0.2,
      });

      res.json(data);
    } catch (err) {
      res.status(500).json({ error: errorMessage(err) });
    }
  });

  // 4. Lesson Revision Flashcards Deck
  app.post("/api/ai/revision-deck", async (req, res) => {
    try {
      const { lessonTitle, lessonSummary, lang } = req.body ?? {};
      const langLabel = lang === "ar" ? "Natural Egyptian Arabic (Thanaweya Amma)" : "Clear English";
      const prompt = [
        `Output strictly in ${langLabel}.`,
        `Build a lightweight, high-retention 5-minute revision deck for:`,
        `Lesson: "${String(lessonTitle ?? "")}"`,
        `Key Notes: "${String(lessonSummary ?? "")}"`,
        "Include 4 active-recall flashcards (front + concise back), 2-3 common Egyptian exam traps, and 1 memorable hook.",
        "Return ONLY valid JSON matching:",
        JSON.stringify({
          lessonTitle: "string",
          memoryHook: "string",
          flashcards: [{ front: "string", back: "string" }],
          commonTraps: ["string"],
        }),
      ].join("\n");

      const { actorId } = readActorContext(req);
      const { data } = await aiRouter.chatJson({
        messages: [{ role: "user", content: prompt }],
        systemPrompt: "You are Kashkool's Egyptian Thanaweya Amma revision designer. Respond only with valid JSON.",
        actorId,
        preferFast: true,
        temperature: 0.5,
      });

      res.json(data);
    } catch (err) {
      res.status(500).json({ error: errorMessage(err) });
    }
  });

  // 5. Parent Weekly Digest
  app.post("/api/ai/parent-digest", async (req, res) => {
    try {
      const { prompt } = req.body ?? {};
      const fullPrompt = [
        String(prompt ?? ""),
        "",
        "Return ONLY valid JSON matching:",
        JSON.stringify({
          headline: "string",
          weeklyNarrative: "string",
          cheerMessage: "string",
          homeSupportTip: "string",
        }),
      ].join("\n");

      const { actorId } = readActorContext(req);
      const { data } = await aiRouter.chatJson({
        messages: [{ role: "user", content: fullPrompt }],
        systemPrompt: "You are Kashkool's calm Egyptian parent advisor. Respond only with valid JSON.",
        actorId,
        preferFast: true,
        temperature: 0.5,
      });

      res.json(data);
    } catch (err) {
      res.status(500).json({ error: errorMessage(err) });
    }
  });

  // 6. Secretary Follow-up Notice
  app.post("/api/ai/secretary-notice", async (req, res) => {
    try {
      const { prompt } = req.body ?? {};
      const fullPrompt = [
        String(prompt ?? ""),
        "",
        "Return ONLY valid JSON matching:",
        JSON.stringify({
          toneTag: "string",
          messageText: "string",
        }),
      ].join("\n");

      const { actorId } = readActorContext(req);
      const { data } = await aiRouter.chatJson({
        messages: [{ role: "user", content: fullPrompt }],
        systemPrompt: "You draft polite Egyptian reception desk messages. Respond only with valid JSON.",
        actorId,
        preferFast: true,
        temperature: 0.5,
      });

      res.json(data);
    } catch (err) {
      res.status(500).json({ error: errorMessage(err) });
    }
  });

  // 7. Teacher 90-Min Lesson & Homework Plan
  app.post("/api/ai/teacher-plan", async (req, res) => {
    try {
      const { prompt } = req.body ?? {};
      const fullPrompt = [
        String(prompt ?? ""),
        "",
        "Return ONLY valid JSON matching:",
        JSON.stringify({
          topicTitle: "string",
          pacingSteps: ["string"],
          basicHomework: ["string"],
          challengeHomework: ["string"],
          assistantChecklist: ["string"],
        }),
      ].join("\n");

      const { actorId } = readActorContext(req);
      const { data } = await aiRouter.chatJson({
        messages: [{ role: "user", content: fullPrompt }],
        systemPrompt: "You are Kashkool's instructional pacing planner. Respond only with valid JSON.",
        actorId,
        preferFast: true,
        temperature: 0.5,
      });

      res.json(data);
    } catch (err) {
      res.status(500).json({ error: errorMessage(err) });
    }
  });

  // 8. Operational Briefing
  app.post("/api/ai/operational-briefing", async (req, res) => {
    try {
      const { prompt } = req.body ?? {};
      const fullPrompt = [
        String(prompt ?? ""),
        "",
        "Return ONLY valid JSON matching:",
        JSON.stringify({
          headline: "string",
          confidenceStatement: "string",
          topDecision: "string",
          nextActionSteps: ["string"],
          trustGuarantee: "string",
        }),
      ].join("\n");

      const { actorId } = readActorContext(req);
      const { data } = await aiRouter.chatJson({
        messages: [{ role: "user", content: fullPrompt }],
        systemPrompt:
          "You are Kashkool's Operations Advisor. Never alter the exact numbers provided. Respond only with valid JSON.",
        actorId,
        preferFast: true,
        temperature: 0.4,
      });

      res.json(data);
    } catch (err) {
      res.status(500).json({ error: errorMessage(err) });
    }
  });

  // 9. Performance Evaluation (Student or Teacher/Center)
  app.post("/api/ai/evaluate", async (req, res) => {
    try {
      const { prompt } = req.body ?? {};
      const fullPrompt = [
        String(prompt ?? ""),
        "",
        "Return ONLY valid JSON matching:",
        JSON.stringify({
          overallScore: 88,
          trustBadge: "string",
          analyticalSummary: "string",
          instantFeedback: "string",
          strengths: ["string"],
          improvementAreas: ["string"],
          nextActionPlan: ["string"],
          trustVerificationNote: "string",
        }),
      ].join("\n");

      const { actorId } = readActorContext(req);
      const { data } = await aiRouter.chatJson({
        messages: [{ role: "user", content: fullPrompt }],
        systemPrompt:
          "You are Kashkool's Academic Evaluation & Trust Specialist in Egypt. " +
          "Deliver calm, honest, analytical evaluations that build certainty between students, parents, teachers, and center owners. " +
          "Never use buzzwords like AI, LLM, bot, API, or pricing jargon. Always cite exact verified figures provided in the prompt. Respond only with valid JSON.",
        actorId,
        preferFast: true,
        temperature: 0.4,
      });

      res.json(data);
    } catch (err) {
      res.status(500).json({ error: errorMessage(err) });
    }
  });

  // 10. Mistake Bank Deep Remediation (via kashkool-ai-client)
  app.post("/api/ai/mistake-explain", async (req, res) => {
    try {
      const { topicTag, questionPrompt, wrongAnswer, correctAnswer, lang } = req.body ?? {};
      const langLabel = lang === "ar" ? "Clear Egyptian Arabic (Thanaweya Amma)" : "Clear English";
      const prompt = [
        `Output strictly in ${langLabel}.`,
        `Topic: ${String(topicTag ?? "")}`,
        `Question: ${String(questionPrompt ?? "")}`,
        `Student's Wrong Choice: ${String(wrongAnswer ?? "")}`,
        `Correct Answer: ${String(correctAnswer ?? "")}`,
        "Return ONLY valid JSON matching:",
        JSON.stringify({
          whyMistakeHappens: "1-2 sentences explaining the trap",
          stepByStepFix: ["step 1", "step 2", "step 3"],
          goldenRule: "1 crisp rule to remember in exams",
        }),
      ].join("\n");

      const { actorId } = readActorContext(req);
      const { data } = await aiRouter.chatJson({
        messages: [{ role: "user", content: prompt }],
        systemPrompt: "You are Kashkool's Mistake Bank Tutor in Egypt. Respond only with valid JSON.",
        actorId,
        preferFast: true,
        temperature: 0.4,
      });
      res.json(data);
    } catch (err) {
      res.status(500).json({ error: errorMessage(err) });
    }
  });

  // 11. Teacher Exam Draft Generator (via kashkool-ai-client)
  app.post("/api/ai/exam-generator", async (req, res) => {
    try {
      const { subject, topic, questionCount = 4, lang } = req.body ?? {};
      const langLabel = lang === "ar" ? "Natural Egyptian Arabic (Thanaweya Amma)" : "Clear English";
      const count = Math.min(8, Math.max(2, Number(questionCount) || 4));
      const prompt = [
        `Output strictly in ${langLabel}.`,
        `Create ${count} high-precision Egyptian Thanaweya Amma exam questions for Subject "${String(subject ?? "")}" on Topic "${String(topic ?? "")}".`,
        "Return ONLY valid JSON matching:",
        JSON.stringify({
          titleAr: "string",
          titleEn: "string",
          questions: [
            {
              topicTagAr: "string",
              topicTagEn: "string",
              promptAr: "string",
              promptEn: "string",
              formula: "ASCII math/physics expression",
              options: ["opt1", "opt2", "opt3", "opt4"],
              correctIndex: 0,
              points: 2,
              remedialAr: "brief explanation in Arabic",
              remedialEn: "brief explanation in English",
            },
          ],
        }),
      ].join("\n");

      const { actorId } = readActorContext(req);
      const { data } = await aiRouter.chatJson({
        messages: [{ role: "user", content: prompt }],
        systemPrompt: "You are Kashkool's official Thanaweya Amma exam author. Output ONLY valid JSON.",
        actorId,
        preferFast: true,
        temperature: 0.4,
      });
      res.json(data);
    } catch (err) {
      res.status(500).json({ error: errorMessage(err) });
    }
  });

  if (!options?.skipVite) {
    const isProd = process.env.NODE_ENV === "production";
    if (!isProd) {
      app.get("/@vite/client", (_req, res) => {
        res.type("application/javascript").send(`
const sheetsMap = new Map();
if ("document" in globalThis) {
  document.querySelectorAll("style[data-vite-dev-id]").forEach((el) => {
    sheetsMap.set(el.getAttribute("data-vite-dev-id"), el);
  });
}
function updateStyle(id, content) {
  if (!("document" in globalThis)) return;
  let style = sheetsMap.get(id);
  if (!style) {
    style = document.createElement("style");
    style.setAttribute("type", "text/css");
    style.setAttribute("data-vite-dev-id", id);
    style.textContent = content;
    document.head.appendChild(style);
    sheetsMap.set(id, style);
  } else {
    style.textContent = content;
  }
}
function removeStyle(id) {
  if (!("document" in globalThis)) return;
  const style = sheetsMap.get(id);
  if (style && style.parentNode) {
    style.parentNode.removeChild(style);
  }
  sheetsMap.delete(id);
}
function createHotContext() {
  const noop = () => {};
  return {
    data: {},
    accept: noop,
    dispose: noop,
    prune: noop,
    decline: noop,
    invalidate: noop,
    on: noop,
    off: noop,
    send: noop,
  };
}
function injectQuery(url, queryToInject) {
  if (url[0] !== "." && url[0] !== "/") return url;
  const pathname = url.replace(/[?#].*$/, "");
  const { search, hash } = new URL(url, "http://vite.dev");
  return pathname + "?" + queryToInject + (search ? "&" + search.slice(1) : "") + (hash || "");
}
class ErrorOverlay {}
export { ErrorOverlay, createHotContext, injectQuery, removeStyle, updateStyle };
`);
      });
      const vite = await createViteServer({
        server: { middlewareMode: true, hmr: false, ws: false },
        appType: "spa",
      });
      app.use(vite.middlewares);
    } else {
      const distDir = path.resolve(__dirname, "dist");
      app.use(express.static(distDir));
      app.use((_req, res) => {
        res.sendFile(path.join(distDir, "index.html"));
      });
    }
  }

  return app;
}

const isEntryModule =
  typeof process.argv[1] === "string" &&
  pathToFileURL(path.resolve(process.argv[1])).href === import.meta.url;

if (isEntryModule && process.env.KASHKOOL_NO_LISTEN !== "1") {
  createKashkoolApp()
    .then((app) => {
      app.listen(PORT, "0.0.0.0", () => {
        console.log(`Kashkool server listening on http://0.0.0.0:${PORT} (kashkool-ai-client + Supabase + ExamFortress)`);
      });
    })
    .catch((err) => {
      console.error("Failed to start server:", err);
      process.exit(1);
    });
}
