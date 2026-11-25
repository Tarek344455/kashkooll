import test from "node:test";
import assert from "node:assert/strict";
import {
  KashkoolAiRouter,
  ModelTags,
  SYSTEM_PROMPTS,
  buildOpenAiWirePayload,
  extractJsonFromText,
} from "./kashkoolAiRouter";

test("registers all 11 built-in models with 7 keyless models available by default", () => {
  const client = new KashkoolAiRouter({});
  assert.equal(client.getAllModels().length, 11);
  const available = client.getAvailableModels();
  assert.equal(available.length, 7);
  assert.equal(available.some((m) => m.providerId === "openrouter"), false);
  assert.equal(available.some((m) => m.providerId === "nvidia"), false);
  assert.equal(available.some((m) => m.providerId === "opencode"), false);
  assert.equal(available.some((m) => m.providerId === "local-gemma"), false);

  const stats = client.getStats();
  assert.equal(stats.totalModels, 11);
  assert.equal(stats.availableModels, 7);
  assert.equal(stats.enabledProviders, 3);
  assert.equal(stats.keylessReady, true);
  assert.equal(stats.currentModel, "Nemotron 3 Ultra");
});

test("strongest-first sorting places Kilo Nemotron 3 Ultra first and Pollinations last", () => {
  const client = new KashkoolAiRouter({});
  const available = client.getAvailableModels();
  assert.equal(available[0].id, "kilo-nemotron-3-ultra");
  assert.equal(available[1].id, "kilo-nemotron-3.5-super-vl");
  assert.equal(available[available.length - 1].id, "pollinations-openai");
  assert.equal(client.getModelsByTag(ModelTags.FREE).length, 7);
  assert.equal(client.getModelsByTag(ModelTags.KEYLESS).length, 7);
});

test("enabling API-keyed provider activates its models", () => {
  const client = new KashkoolAiRouter({ OPENROUTER_API_KEY: "test-key" });
  const available = client.getAvailableModels();
  assert.equal(available.some((m) => m.id === "openrouter-nemotron"), true);
});

test("circuit breaker opens after 3 consecutive failures", () => {
  const client = new KashkoolAiRouter({});
  const codestral = client.getAllModels().find((m) => m.id === "llm7-codestral")!;
  const provider = {
    id: "llm7",
    name: "llm7.io",
    baseUrl: "https://api.llm7.io/v1",
    apiKey: "",
    requiresApiKey: false,
    maxConcurrent: 1,
    minIntervalMs: 1200,
    cooldownMs: 15_000,
    authCooldownMs: 3_600_000,
    rateLimitScope: "PROVIDER" as const,
    enabled: true,
    note: "",
  };
  client.markFailure(provider, codestral, "fail 1");
  client.markFailure(provider, codestral, "fail 2");
  assert.equal(client.getAvailableModels().some((m) => m.id === "llm7-codestral"), true);
  client.markFailure(provider, codestral, "fail 3");
  assert.equal(client.getAvailableModels().some((m) => m.id === "llm7-codestral"), false);
});

test("OpenAI wire payload respects Protocol Rule #3 (no forbidden fields)", () => {
  const payload = buildOpenAiWirePayload({
    model: "nvidia/nemotron-3-ultra-550b-a55b:free",
    messages: [
      { role: "system", content: SYSTEM_PROMPTS.default },
      { role: "user", content: "اهلا" },
    ],
    temperature: 0.4,
    maxTokens: 1024,
  });
  const json = JSON.stringify(payload);
  assert.equal(json.includes('"max_tokens":1024'), true);
  assert.equal(json.includes('"tool_choice":'), false);
  assert.equal(json.includes('"parallel_tool_calls":'), false);
  assert.equal(json.includes('"metadata":'), false);
  assert.equal(json.includes('"user":'), false);
});

test("Egyptian Arabic default system prompt matches kashkool-ai-client persona", () => {
  assert.equal(SYSTEM_PROMPTS.default.includes("مصري"), true);
  assert.equal(SYSTEM_PROMPTS.default.includes("تعليمي"), true);
  assert.equal(SYSTEM_PROMPTS.default.includes("ودود"), true);
  assert.equal(SYSTEM_PROMPTS.default.includes("ذكي اجتماعياً"), true);
  assert.equal(SYSTEM_PROMPTS.default.includes("ذكي عاطفياً"), true);
});

test("extractJsonFromText parses fenced and think-wrapped JSON cleanly", () => {
  const raw = `<think>reasoning...</think>\n\`\`\`json\n{"headline":"ملخص اليوم","overallScore":92}\n\`\`\``;
  const parsed = extractJsonFromText<{ headline: string; overallScore: number }>(raw);
  assert.equal(parsed.headline, "ملخص اليوم");
  assert.equal(parsed.overallScore, 92);
});
