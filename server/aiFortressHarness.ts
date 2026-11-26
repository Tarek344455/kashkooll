import http from "node:http";
import { createKashkoolApp } from "../server";
import { KashkoolAiRouter } from "./kashkoolAiRouter";

type ChaosMode = "healthy" | "failover_429_503" | "malformed_json";

let chaosMode: ChaosMode = "healthy";
const providerHitCounts: Record<string, number> = {};

function detectProviderFromUrl(url: string): string {
  if (url.includes("groq.com")) return "groq";
  if (url.includes("deepseek.com")) return "deepseek";
  if (url.includes("openrouter.ai")) return "openrouter";
  if (url.includes("kilo.ai")) return "kilo";
  if (url.includes("llm7.io")) return "llm7";
  if (url.includes("pollinations.ai")) return "pollinations";
  return "other";
}

function makeSseStream(chunks: string[]): ReadableStream<Uint8Array> {
  const encoder = new TextEncoder();
  return new ReadableStream<Uint8Array>({
    async start(controller) {
      for (const c of chunks) {
        const line = `data: ${JSON.stringify({ choices: [{ delta: { content: c } }] })}\n\n`;
        controller.enqueue(encoder.encode(line));
      }
      controller.enqueue(encoder.encode("data: [DONE]\n\n"));
      controller.close();
    },
  });
}

const simulatedFetch: typeof fetch = async (input, init) => {
  const url = typeof input === "string" ? input : input instanceof URL ? input.toString() : input.url;
  const provider = detectProviderFromUrl(url);
  providerHitCounts[provider] = (providerHitCounts[provider] ?? 0) + 1;

  const rawBody = typeof init?.body === "string" ? init.body : "{}";
  let parsedBody: { stream?: boolean; messages?: Array<{ role: string; content: unknown }> } = {};
  try {
    parsedBody = JSON.parse(rawBody) as typeof parsedBody;
  } catch {
    parsedBody = {};
  }

  // Chaos injection checks
  if (chaosMode === "failover_429_503") {
    if (provider === "groq") {
      return new Response(JSON.stringify({ error: "rate_limit_exceeded" }), { status: 429 });
    }
    if (provider === "deepseek") {
      return new Response("upstream service unavailable", { status: 503 });
    }
    if (provider === "openrouter") {
      return new Response("bad gateway", { status: 503 });
    }
  }

  if (chaosMode === "malformed_json" && !parsedBody.stream) {
    if (provider === "groq" || provider === "kilo") {
      return new Response(JSON.stringify({ choices: [{ message: { content: "{not valid json!!!" } }] }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }
    return new Response(
      JSON.stringify({
        choices: [
          {
            message: {
              content: JSON.stringify({
                questions: [
                  {
                    topicTag: "التفاضل",
                    prompt: "ما مشتقة دالة س²؟",
                    formula: "d/dx(x^2) = 2x",
                    options: ["2x", "x", "x^2", "2"],
                    correctIndex: 0,
                    remedial: "نزل الأس واضربه في س مع طرح ١ من الأس.",
                  },
                ],
              }),
            },
          },
        ],
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  }

  const systemText = String(parsedBody.messages?.find((m) => m.role === "system")?.content ?? "");
  const userText = String(parsedBody.messages?.slice(-1)[0]?.content ?? "");
  const hasAnxiety = systemText.includes("التوتر") || userText.includes("خايف") || userText.includes("بكره");
  const hasFrustration = systemText.includes("الإحباط") || userText.includes("زهقت") || userText.includes("غلطت");
  const hasMemoryTopic = systemText.includes("قانون كيرشوف") || systemText.includes("القيم العظمى");

  const replyChunks = hasAnxiety
    ? [
        "<think>emotional pulse detected: calm student gently first</think>",
        "أهلاً بيك يا بطل، خد نفس عميق واهدى خالص — التوتر ليلة الامتحان طبيعي ومش معناه إنك ناسي. ",
        hasMemoryTopic ? "خلينا نبدأ مع بعض بـ قانون كيرشوف في خطوة واحدة بسيطة ومضمونة: " : "خلينا نبدأ بخطوة واحدة صغيرة ومضمونة: ",
        "١) اكتب المعطيات بهدوء، ٢) طبق القانون الأساسي، ٣) راجع الناتج.",
      ]
    : hasFrustration
      ? [
          "ولا يهمك خالص، الغلط في خطوة معناه إنك قربت تفهم الفكرة! ",
          hasMemoryTopic ? "تعالى نراجع قانون كيرشوف بالراحة خطوة خطوة بدون أي ضغط." : "تعالى نقسمها لخطوتين صغيرين.",
        ]
      : [
          "أهلاً بيك يا صديقي في كشكول! ",
          hasMemoryTopic ? "بناءً على نقاط تركيزك في قانون كيرشوف، " : "",
          "١) نبدأ بالفكرة الأساسية، ٢) نطبق بمثال بسيط، ٣) نأكد بالقاعدة النهائية.",
        ];

  if (parsedBody.stream) {
    return new Response(makeSseStream(replyChunks), {
      status: 200,
      headers: { "Content-Type": "text/event-stream" },
    });
  }

  return new Response(
    JSON.stringify({
      choices: [{ message: { content: replyChunks.join("") } }],
    }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
};

async function startHarness() {
  const router = new KashkoolAiRouter(
    {
      GROQ_API_KEY: "gsk_harness_mock_key_0001",
      DEEPSEEK_API_KEY: "sk-deepseek-harness-0001",
      OPENROUTER_API_KEY: "sk-or-harness-0001",
    },
    { fetchImpl: simulatedFetch, requestTimeoutMs: 5000, baseRetryDelayMs: 5 }
  );

  // Relax per-actor minInterval slightly for 2,000-virtual-student surge while preserving provider caps
  const app = await createKashkoolApp({ skipVite: true, router });

  app.post("/__harness/chaos", (req, res) => {
    const { mode } = (req.body ?? {}) as { mode?: ChaosMode };
    chaosMode = mode ?? "healthy";
    res.json({ ok: true, chaosMode, providerHitCounts });
  });

  app.get("/__harness/stats", (_req, res) => {
    res.json({ chaosMode, providerHitCounts, routerStats: router.getStats() });
  });

  const server = http.createServer(app);
  server.listen(0, "127.0.0.1", () => {
    const addr = server.address();
    if (addr && typeof addr !== "string") {
      console.log(`HARNESS_READY:${addr.port}`);
    }
  });
}

void startHarness();
