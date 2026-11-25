import express from "express";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createServer as createViteServer } from "vite";
import { kashkoolAiRouter, type ChatWireMessage } from "./server/kashkoolAiRouter";
import { readServerSupabaseConfig } from "./server/supabaseServer";

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

async function startServer() {
  const app = express();
  app.use(express.json({ limit: "8mb" }));

  app.get("/api/health", (_req, res) => {
    const stats = kashkoolAiRouter.getStats();
    const supabaseCfg = readServerSupabaseConfig();
    res.json({
      ok: true,
      aiReady: stats.keylessReady,
      engine: "kashkool-ai-client",
      providerStats: stats,
      supabaseConfigured: Boolean(supabaseCfg),
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

  // 1. Multi-turn streaming study helper via kashkool-ai-client (text + optional image)
  app.post("/api/ai/study-chat", async (req, res) => {
    try {
      const { prompt, history = [], photoDataUrl, role, subject, knapsackSummary, certaintyScore, lang } =
        req.body ?? {};
      const langHint = lang === "ar" ? "Arabic (clear Egyptian academic style)" : "English";
      const contextualPrompt = [
        `Language: ${langHint}`,
        `User Role: ${role ?? "student"}`,
        `Lesson / Context: ${subject ?? "Pure Mathematics & Physics"}`,
        `Verified 15-min Rescue Focus: ${knapsackSummary ?? "On track"}`,
        `System Certainty Score: ${certaintyScore ?? 92}%`,
        "",
        "Question / Request:",
        String(prompt ?? ""),
        "",
        "Respond calmly with numbered steps and a concise rule takeaway.",
      ].join("\n");

      const systemPrompt =
        lang === "ar"
          ? [
              "أنت مستشار كشكول الأكاديمي والتربوي في مصر.",
              "تحدث بلهجة مصرية دافئة وواضحة وبأسلوب تعليمي منظم بخطوات مرقمة، واختم بقاعدة واضحة.",
              "لا تذكر أي مصطلحات تقنية مثل AI أو LLM أو API أو تسعير.",
              "عند وجود صورة مسألة مكتوبة باليد أو من كتاب، اقرأ المعادلة أو الرسم بدقة واشرح الحل خطوة بخطوة.",
            ].join("\n")
          : [
              "You are Kashkool's Academic & Operational Advisor in Egypt.",
              "Never mention AI/LLM/APIs or pricing jargon. Respond in crisp, encouraging English with numbered steps and a concise takeaway rule.",
              "When given a student's handwritten or textbook problem photo, transcribe the equation/diagram carefully and walk through the exact solution step by step.",
            ].join("\n");

      res.setHeader("Content-Type", "text/event-stream; charset=utf-8");
      res.setHeader("Cache-Control", "no-cache");
      res.setHeader("Connection", "keep-alive");

      const hasValidPhoto = typeof photoDataUrl === "string" && isValidImageDataUrl(photoDataUrl);
      const historyMessages: ChatWireMessage[] = Array.isArray(history)
        ? history.slice(1).slice(-8).map((m: { fromUser?: boolean; text?: string }) => ({
            role: m.fromUser ? ("user" as const) : ("assistant" as const),
            content: String(m.text ?? "").slice(0, 600),
          }))
        : [];

      const messages: ChatWireMessage[] = hasValidPhoto
        ? [
            ...historyMessages.slice(-4),
            {
              role: "user",
              content: [
                { type: "text", text: contextualPrompt },
                { type: "image_url", image_url: { url: photoDataUrl.trim() } },
              ],
            },
          ]
        : [
            ...historyMessages,
            {
              role: "user",
              content: contextualPrompt,
            },
          ];

      let emitted = false;
      const result = await kashkoolAiRouter.chat({
        messages,
        systemPrompt,
        requireVision: hasValidPhoto,
        preferFast: !hasValidPhoto,
        temperature: 0.5,
        onChunk: (piece) => {
          if (piece) {
            emitted = true;
            res.write(`data: ${JSON.stringify({ chunk: piece })}\n\n`);
          }
        },
      });

      if (!emitted && result.text) {
        res.write(`data: ${JSON.stringify({ chunk: result.text })}\n\n`);
        emitted = true;
      }

      if (!emitted) {
        res.write(`data: ${JSON.stringify({ error: "Empty response from study helper." })}\n\n`);
      } else {
        res.write(`data: ${JSON.stringify({ done: true, model: result.modelId })}\n\n`);
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

      const { data } = await kashkoolAiRouter.chatJson<{ questions?: unknown[] }>({
        messages: [{ role: "user", content: prompt }],
        systemPrompt:
          "You are Kashkool's curriculum quiz author. Output valid JSON strictly following the requested schema.",
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

      const { data } = await kashkoolAiRouter.chatJson({
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

      const { data } = await kashkoolAiRouter.chatJson({
        messages: [{ role: "user", content: prompt }],
        systemPrompt: "You are Kashkool's Egyptian Thanaweya Amma revision designer. Respond only with valid JSON.",
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

      const { data } = await kashkoolAiRouter.chatJson({
        messages: [{ role: "user", content: fullPrompt }],
        systemPrompt: "You are Kashkool's calm Egyptian parent advisor. Respond only with valid JSON.",
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

      const { data } = await kashkoolAiRouter.chatJson({
        messages: [{ role: "user", content: fullPrompt }],
        systemPrompt: "You draft polite Egyptian reception desk messages. Respond only with valid JSON.",
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

      const { data } = await kashkoolAiRouter.chatJson({
        messages: [{ role: "user", content: fullPrompt }],
        systemPrompt: "You are Kashkool's instructional pacing planner. Respond only with valid JSON.",
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

      const { data } = await kashkoolAiRouter.chatJson({
        messages: [{ role: "user", content: fullPrompt }],
        systemPrompt:
          "You are Kashkool's Operations Advisor. Never alter the exact numbers provided. Respond only with valid JSON.",
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

      const { data } = await kashkoolAiRouter.chatJson({
        messages: [{ role: "user", content: fullPrompt }],
        systemPrompt:
          "You are Kashkool's Academic Evaluation & Trust Specialist in Egypt. " +
          "Deliver calm, honest, analytical evaluations that build certainty between students, parents, teachers, and center owners. " +
          "Never use buzzwords like AI, LLM, bot, API, or pricing jargon. Always cite exact verified figures provided in the prompt. Respond only with valid JSON.",
        preferFast: true,
        temperature: 0.4,
      });

      res.json(data);
    } catch (err) {
      res.status(500).json({ error: errorMessage(err) });
    }
  });

  const isProd = process.env.NODE_ENV === "production";
  if (!isProd) {
    const vite = await createViteServer({
      server: { middlewareMode: true, hmr: false },
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

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Kashkool server listening on http://0.0.0.0:${PORT} (kashkool-ai-client + Supabase)`);
  });
}

startServer().catch((err) => {
  console.error("Failed to start server:", err);
  process.exit(1);
});
