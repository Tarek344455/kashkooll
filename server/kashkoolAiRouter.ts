export type RateLimitScope = "PROVIDER" | "MODEL";

export const ModelTags = {
  REASONING: "reasoning",
  VISION: "vision",
  CODING: "coding",
  FAST: "fast",
  CREATIVE: "creative",
  ANALYTICAL: "analytical",
  MULTILINGUAL: "multilingual",
  LONG_CONTEXT: "long-context",
  FREE: "free",
  KEYLESS: "keyless",
} as const;

export interface AiProviderConfig {
  id: string;
  name: string;
  baseUrl: string;
  apiKey: string;
  requiresApiKey: boolean;
  maxConcurrent: number;
  minIntervalMs: number;
  cooldownMs: number;
  authCooldownMs: number;
  rateLimitScope: RateLimitScope;
  enabled: boolean;
  note: string;
}

export interface AiModelConfig {
  id: string;
  name: string;
  upstreamModel: string;
  providerId: string;
  quality: number;
  contextWindow: number;
  supportsTools: boolean;
  minOutputTokens: number;
  maxOutputTokens: number;
  isAvailable: boolean;
  tags: string[];
  description: string;
}

export interface ProviderHealthState {
  id: string;
  isHealthy: boolean;
  lastCheck: number;
  consecutiveFailures: number;
  lastError: string | null;
  averageLatencyMs: number;
}

export type ChatContentPart =
  | { type: "text"; text: string }
  | { type: "image_url"; image_url: { url: string } };

export interface ChatWireMessage {
  role: "system" | "user" | "assistant";
  content: string | ChatContentPart[];
}

export interface ChatWirePayload {
  model: string;
  messages: ChatWireMessage[];
  temperature: number;
  max_tokens: number;
  stream: boolean;
  tools?: unknown[];
}

export interface ClientStatsSnapshot {
  totalModels: number;
  availableModels: number;
  enabledProviders: number;
  healthyProviders: number;
  currentModel: string | null;
  isProcessing: boolean;
  keylessReady: boolean;
}

export const SYSTEM_PROMPTS = {
  default: [
    "أنت مساعد ذكي تعليمي وودود ومتعاطف، مصمم خصيصاً لبيئة تعليمية مصرية.",
    "شخصيتك:",
    "- تعليمي: تشرح المفاهيم ببساطة ووضوح، وتشجع على التعلم والاستكشاف.",
    '- ودود: تتحدث بلهجة مصرية طبيعية ودافئة، وتستخدم "انت" و"احنا" و"خلينا".',
    "- ذكي اجتماعياً: تفهم السياق الاجتماعي، وتحترم القيم، وتتجنب المواضيع الحساسة.",
    "- ذكي عاطفياً: تتعاطف مع مشاعر المستخدم، وتقدم الدعم المعنوي، وتحتفل بالنجاحات.",
    "- مفيد عملياً: تقدم حلولاً عملية وخطوات واضحة وأمثلة من الواقع المصري.",
    "إرشادات الرد:",
    "1. ابدأ بتحية دافئة إذا كانت أول رسالة.",
    "2. استخدم لغة عربية مصرية بسيطة وواضحة.",
    "3. قسم الردود الطويلة لنقاط مرقمة أو فقرات قصيرة.",
    "4. قدم أمثلة عملية من الحياة اليومية في مصر.",
    "5. شجع المستخدم واطمئن عليه.",
    "6. إذا لم تعرف الإجابة، قل ذلك بصراحة واقترح بدائل.",
    "7. احترم الخصوصية ولا تطلب معلومات شخصية حساسة.",
    "8. كن شاملاً وراعِ اختلاف المستويات والخلفيات.",
    "تذكّر: هدفك أن يخرج المستخدم من المحادثة وهو مستفيد ومطمئن ومتحمس للتعلم أكثر.",
  ].join("\n"),
  openrouter: [
    "أنت مساعد ذكي تعليمي ومتعاطف من كاشكول، تتحدث بلهجة مصرية طبيعية.",
    '- ودود: تستخدم "انت" و"احنا" و"خلينا"، وتكون دافئ مع المستخدم.',
    "- مفيد عملياً: تقدم حلولاً عملية وخطوات واضحة وأمثلة من الحياة اليومية في مصر.",
    "تذكّر: هدفك أن يخرج المستخدم من المحادثة وهو مستفيد ومطمئن ومتحمس للتعلم أكثر.",
  ].join("\n"),
  nvidia: [
    "أنت مساعد ذكي تعليمي من كاشكول، تعمل على موديلات إنفيديا، وتحدث بلهجة مصرية طبيعية.",
    "- دقيق وموثوق: تقدم معلومات صحيحة ولا تخترع إجابات.",
    "هدفك: أن يشعر المستخدم بالاستفادة والطمأنينة والحماس للتعلم.",
  ].join("\n"),
  opencode: [
    "أنت مساعد برمجي وتعليمي ذكي من كاشكول، تتحدث بلهجة مصرية طبيعية.",
    "هدفك: أن يصبح المستخدم مبرمجاً أفضل وأكثر ثقة في نفسه.",
  ].join("\n"),
};

/**
 * Protocol rule #3 from kashkool-ai-client:
 * Only fields that every keyless upstream accepts are emitted.
 * Never emit tool_choice, parallel_tool_calls, metadata, or user.
 */
export function buildOpenAiWirePayload(params: {
  model: string;
  messages: ChatWireMessage[];
  temperature?: number;
  maxTokens?: number;
  stream?: boolean;
  tools?: unknown[];
}): ChatWirePayload {
  const payload: ChatWirePayload = {
    model: params.model,
    messages: params.messages,
    temperature: params.temperature ?? 0.7,
    max_tokens: params.maxTokens ?? 4096,
    stream: Boolean(params.stream),
  };
  if (params.tools && params.tools.length > 0) {
    payload.tools = params.tools;
  }
  return payload;
}

export function extractJsonFromText<T>(rawText: string): T {
  const trimmed = rawText.trim();
  const withoutThink = trimmed.replace(/<think>[\s\S]*?<\/think>/gi, "").trim();

  const tryParse = (candidate: string): T | null => {
    try {
      return JSON.parse(candidate) as T;
    } catch {
      return null;
    }
  };

  const direct = tryParse(withoutThink);
  if (direct !== null) return direct;

  const fencedMatch = /```(?:json)?\s*([\s\S]*?)```/i.exec(withoutThink);
  if (fencedMatch?.[1]) {
    const fencedParsed = tryParse(fencedMatch[1].trim());
    if (fencedParsed !== null) return fencedParsed;
  }

  const firstBrace = withoutThink.indexOf("{");
  const lastBrace = withoutThink.lastIndexOf("}");
  if (firstBrace !== -1 && lastBrace > firstBrace) {
    const sliced = tryParse(withoutThink.slice(firstBrace, lastBrace + 1));
    if (sliced !== null) return sliced;
  }

  const firstBracket = withoutThink.indexOf("[");
  const lastBracket = withoutThink.lastIndexOf("]");
  if (firstBracket !== -1 && lastBracket > firstBracket) {
    const slicedArr = tryParse(withoutThink.slice(firstBracket, lastBracket + 1));
    if (slicedArr !== null) return slicedArr;
  }

  throw new Error("Could not parse structured JSON from Kashkool AI response.");
}

export interface KashkoolChatOptions {
  messages: ChatWireMessage[];
  systemPrompt?: string;
  modelId?: string;
  requireVision?: boolean;
  preferFast?: boolean;
  requireJson?: boolean;
  temperature?: number;
  maxTokens?: number;
  onChunk?: (chunk: string) => void;
}

export interface KashkoolChatResult {
  text: string;
  modelId: string;
  modelName: string;
  providerId: string;
  upstreamModel: string;
}

export class KashkoolAiRouter {
  private providers = new Map<string, AiProviderConfig>();
  private models = new Map<string, AiModelConfig>();
  private health = new Map<string, ProviderHealthState>();
  private inFlight = new Map<string, number>();
  private lastRequestAt = new Map<string, number>();
  private currentModel: AiModelConfig | null = null;
  private processingCount = 0;

  private readonly userAgent = "KashkoolAiClient/1.0";
  private readonly requestTimeoutMs = 15_000;
  private readonly maxRetries = 1;
  private readonly baseRetryDelayMs = 300;

  constructor(private readonly env: Record<string, string | undefined> = process.env) {
    this.initializeBuiltInProviders();
    this.initializeBuiltInModels();
    this.refreshAvailable();
  }

  private initializeBuiltInProviders() {
    const openrouterKey = this.env.OPENROUTER_API_KEY?.trim() ?? "";
    const nvidiaKey = this.env.NVIDIA_API_KEY?.trim() ?? "";
    const opencodeKey = this.env.OPENCODE_API_KEY?.trim() ?? "";
    const localEnabled = this.env.LOCAL_GEMMA_ENABLED === "true";

    const list: AiProviderConfig[] = [
      {
        id: "kilo",
        name: "Kilo AI Gateway",
        baseUrl: "https://ai-gateway.kilo.ai/api/v1",
        apiKey: "",
        requiresApiKey: false,
        maxConcurrent: 3,
        minIntervalMs: 150,
        cooldownMs: 60_000,
        authCooldownMs: 3_600_000,
        rateLimitScope: "MODEL",
        enabled: true,
        note: "Kilo anonymous free tier. Five verified models, model-scoped cooldown.",
      },
      {
        id: "llm7",
        name: "llm7.io",
        baseUrl: "https://api.llm7.io/v1",
        apiKey: "",
        requiresApiKey: false,
        maxConcurrent: 1,
        minIntervalMs: 1200,
        cooldownMs: 15_000,
        authCooldownMs: 3_600_000,
        rateLimitScope: "PROVIDER",
        enabled: true,
        note: "llm7 keyless. codestral-latest stays open without a key.",
      },
      {
        id: "pollinations",
        name: "Pollinations AI",
        baseUrl: "https://text.pollinations.ai/openai",
        apiKey: "",
        requiresApiKey: false,
        maxConcurrent: 1,
        minIntervalMs: 45_000,
        cooldownMs: 45_000,
        authCooldownMs: 3_600_000,
        rateLimitScope: "PROVIDER",
        enabled: true,
        note: "Pollinations keyless last-resort fallback.",
      },
      {
        id: "local-gemma",
        name: "Local Gemma 4 E2B",
        baseUrl: "http://127.0.0.1:8080/v1",
        apiKey: "",
        requiresApiKey: false,
        maxConcurrent: 2,
        minIntervalMs: 100,
        cooldownMs: 5_000,
        authCooldownMs: 3_600_000,
        rateLimitScope: "PROVIDER",
        enabled: localEnabled,
        note: "Local Gemma 4 E2B via litertlm server on port 8080.",
      },
      {
        id: "openrouter",
        name: "OpenRouter",
        baseUrl: "https://openrouter.ai/api/v1",
        apiKey: openrouterKey,
        requiresApiKey: true,
        maxConcurrent: 2,
        minIntervalMs: 200,
        cooldownMs: 30_000,
        authCooldownMs: 3_600_000,
        rateLimitScope: "MODEL",
        enabled: Boolean(openrouterKey),
        note: "OpenRouter aggregator (requires OPENROUTER_API_KEY).",
      },
      {
        id: "nvidia",
        name: "NVIDIA Build",
        baseUrl: "https://integrate.api.nvidia.com/v1",
        apiKey: nvidiaKey,
        requiresApiKey: true,
        maxConcurrent: 2,
        minIntervalMs: 300,
        cooldownMs: 30_000,
        authCooldownMs: 3_600_000,
        rateLimitScope: "MODEL",
        enabled: Boolean(nvidiaKey),
        note: "NVIDIA API catalog (requires NVIDIA_API_KEY).",
      },
      {
        id: "opencode",
        name: "OpenCode",
        baseUrl: "https://api.opencode.sh/v1",
        apiKey: opencodeKey,
        requiresApiKey: true,
        maxConcurrent: 2,
        minIntervalMs: 200,
        cooldownMs: 30_000,
        authCooldownMs: 3_600_000,
        rateLimitScope: "MODEL",
        enabled: Boolean(opencodeKey),
        note: "OpenCode models (requires OPENCODE_API_KEY).",
      },
    ];

    for (const p of list) {
      this.providers.set(p.id, p);
      this.health.set(p.id, {
        id: p.id,
        isHealthy: p.enabled,
        lastCheck: Date.now(),
        consecutiveFailures: 0,
        lastError: null,
        averageLatencyMs: 0,
      });
      this.inFlight.set(p.id, 0);
    }
  }

  private initializeBuiltInModels() {
    const builtIn: AiModelConfig[] = [
      {
        id: "kilo-nemotron-3-ultra",
        name: "Nemotron 3 Ultra",
        upstreamModel: "nvidia/nemotron-3-ultra-550b-a55b:free",
        providerId: "kilo",
        quality: 0.88,
        contextWindow: 131072,
        supportsTools: true,
        minOutputTokens: 512,
        maxOutputTokens: 8192,
        isAvailable: true,
        tags: [ModelTags.REASONING, ModelTags.CODING, ModelTags.ANALYTICAL, ModelTags.FREE, ModelTags.KEYLESS],
        description: "NVIDIA flagship reasoning model via Kilo keyless gateway.",
      },
      {
        id: "kilo-nemotron-3.5-super-vl",
        name: "Nemotron 3.5 Super VL",
        upstreamModel: "nvidia/nemotron-3.5-super-vl:free",
        providerId: "kilo",
        quality: 0.82,
        contextWindow: 131072,
        supportsTools: true,
        minOutputTokens: 512,
        maxOutputTokens: 8192,
        isAvailable: true,
        tags: [ModelTags.VISION, ModelTags.REASONING, ModelTags.MULTILINGUAL, ModelTags.FREE, ModelTags.KEYLESS],
        description: "Vision-language model for receipt and handwritten problem analysis.",
      },
      {
        id: "kilo-nemotron-3-nano-reasoning",
        name: "Nemotron 3 Nano Reasoning",
        upstreamModel: "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free",
        providerId: "kilo",
        quality: 0.8,
        contextWindow: 131072,
        supportsTools: true,
        minOutputTokens: 512,
        maxOutputTokens: 8192,
        isAvailable: true,
        tags: [ModelTags.REASONING, ModelTags.FAST, ModelTags.CODING, ModelTags.FREE, ModelTags.KEYLESS],
        description: "Fast reasoning model with strong logical capability.",
      },
      {
        id: "kilo-nemotron-3.5-lightning",
        name: "Nemotron 3.5 Lightning",
        upstreamModel: "nvidia/nemotron-3.5-lightning:free",
        providerId: "kilo",
        quality: 0.78,
        contextWindow: 131072,
        supportsTools: true,
        minOutputTokens: 512,
        maxOutputTokens: 8192,
        isAvailable: true,
        tags: [ModelTags.FAST, ModelTags.CREATIVE, ModelTags.MULTILINGUAL, ModelTags.FREE, ModelTags.KEYLESS],
        description: "Optimized for speed and real-time Egyptian Arabic chat.",
      },
      {
        id: "kilo-flint-1.0",
        name: "Flint 1.0",
        upstreamModel: "recursive/flint-v1.0:free",
        providerId: "kilo",
        quality: 0.75,
        contextWindow: 131072,
        supportsTools: true,
        minOutputTokens: 2048,
        maxOutputTokens: 8192,
        isAvailable: true,
        tags: [ModelTags.CREATIVE, ModelTags.ANALYTICAL, ModelTags.LONG_CONTEXT, ModelTags.FREE, ModelTags.KEYLESS],
        description: "General-purpose instruction-following workhorse.",
      },
      {
        id: "llm7-codestral",
        name: "Codestral Latest",
        upstreamModel: "codestral-latest",
        providerId: "llm7",
        quality: 0.7,
        contextWindow: 131072,
        supportsTools: false,
        minOutputTokens: 0,
        maxOutputTokens: 8192,
        isAvailable: true,
        tags: [ModelTags.CODING, ModelTags.REASONING, ModelTags.FREE, ModelTags.KEYLESS],
        description: "Mistral specialized coding and technical model via llm7.",
      },
      {
        id: "pollinations-openai",
        name: "Pollinations OpenAI",
        upstreamModel: "openai",
        providerId: "pollinations",
        quality: 0.4,
        contextWindow: 131072,
        supportsTools: true,
        minOutputTokens: 0,
        maxOutputTokens: 4096,
        isAvailable: true,
        tags: [ModelTags.FAST, ModelTags.FREE, ModelTags.KEYLESS],
        description: "Last-resort keyless fallback via Pollinations.",
      },
      {
        id: "openrouter-nemotron",
        name: "Nemotron via OpenRouter",
        upstreamModel: "nvidia/nemotron-3-ultra-550b-a55b:free",
        providerId: "openrouter",
        quality: 0.88,
        contextWindow: 131072,
        supportsTools: true,
        minOutputTokens: 512,
        maxOutputTokens: 8192,
        isAvailable: true,
        tags: [ModelTags.REASONING, ModelTags.CODING, ModelTags.ANALYTICAL],
        description: "Nemotron 3 Ultra via OpenRouter.",
      },
      {
        id: "nvidia-nemotron",
        name: "Nemotron via NVIDIA",
        upstreamModel: "nvidia/nemotron-3-ultra-550b-a55b",
        providerId: "nvidia",
        quality: 0.88,
        contextWindow: 131072,
        supportsTools: true,
        minOutputTokens: 512,
        maxOutputTokens: 8192,
        isAvailable: true,
        tags: [ModelTags.REASONING, ModelTags.CODING, ModelTags.ANALYTICAL],
        description: "Nemotron 3 Ultra direct from NVIDIA API.",
      },
      {
        id: "opencode-default",
        name: "OpenCode Default",
        upstreamModel: "default",
        providerId: "opencode",
        quality: 0.85,
        contextWindow: 131072,
        supportsTools: true,
        minOutputTokens: 512,
        maxOutputTokens: 8192,
        isAvailable: true,
        tags: [ModelTags.REASONING, ModelTags.CODING, ModelTags.MULTILINGUAL],
        description: "OpenCode educational assistant model.",
      },
      {
        id: "local-gemma-4-e2b",
        name: "Gemma 4 E2B (Local)",
        upstreamModel: "gemma-4-e2b-it",
        providerId: "local-gemma",
        quality: 0.95,
        contextWindow: 131072,
        supportsTools: true,
        minOutputTokens: 512,
        maxOutputTokens: 8192,
        isAvailable: true,
        tags: [ModelTags.REASONING, ModelTags.CODING, ModelTags.ANALYTICAL, ModelTags.LONG_CONTEXT],
        description: "Local Gemma 4 2B model via litertlm on port 8080.",
      },
    ];

    for (const m of builtIn) {
      this.models.set(m.id, m);
    }
  }

  getAllModels(): AiModelConfig[] {
    return Array.from(this.models.values());
  }

  getAvailableModels(): AiModelConfig[] {
    const now = Date.now();
    return Array.from(this.models.values())
      .filter((model) => {
        const provider = this.providers.get(model.providerId);
        if (!provider || !provider.enabled || !model.isAvailable) return false;
        if (provider.requiresApiKey && !provider.apiKey.trim()) return false;
        const h = this.health.get(this.healthKey(provider, model));
        if (h && h.consecutiveFailures >= 3 && now - h.lastCheck < provider.cooldownMs) {
          return false;
        }
        return true;
      })
      .sort((a, b) => b.quality - a.quality);
  }

  getModelsByTag(tag: string): AiModelConfig[] {
    return this.getAllModels().filter((m) => m.tags.includes(tag));
  }

  setProviderEnabled(providerId: string, enabled: boolean): void {
    const p = this.providers.get(providerId);
    if (!p) return;
    p.enabled = enabled;
    const h = this.health.get(providerId);
    if (h) h.isHealthy = enabled;
    this.refreshAvailable();
  }

  setProviderApiKey(providerId: string, apiKey: string): void {
    const p = this.providers.get(providerId);
    if (!p) return;
    p.apiKey = apiKey.trim();
    if (p.apiKey) p.enabled = true;
    this.refreshAvailable();
  }

  getStats(): ClientStatsSnapshot {
    const available = this.getAvailableModels();
    const enabledProviders = Array.from(this.providers.values()).filter((p) => p.enabled).length;
    const healthyProviders = Array.from(this.providers.values()).filter((p) => {
      if (!p.enabled) return false;
      const h = this.health.get(p.id);
      return h ? h.isHealthy : true;
    }).length;
    return {
      totalModels: this.models.size,
      availableModels: available.length,
      enabledProviders,
      healthyProviders,
      currentModel: this.currentModel?.name ?? null,
      isProcessing: this.processingCount > 0,
      keylessReady: available.length > 0,
    };
  }

  systemPromptForModel(model: AiModelConfig): string {
    switch (model.providerId) {
      case "openrouter":
        return SYSTEM_PROMPTS.openrouter;
      case "nvidia":
        return SYSTEM_PROMPTS.nvidia;
      case "opencode":
        return SYSTEM_PROMPTS.opencode;
      default:
        return SYSTEM_PROMPTS.default;
    }
  }

  private healthKey(provider: AiProviderConfig, model?: AiModelConfig): string {
    return provider.rateLimitScope === "MODEL" && model ? `${provider.id}:${model.id}` : provider.id;
  }

  private refreshAvailable(): void {
    const available = this.getAvailableModels();
    if (!this.currentModel || !available.some((m) => m.id === this.currentModel?.id)) {
      this.currentModel = available[0] ?? null;
    }
  }

  private eligibleModels(options: {
    modelId?: string;
    requireVision?: boolean;
    preferFast?: boolean;
  }): AiModelConfig[] {
    const base = this.getAvailableModels();
    if (options.requireVision) {
      const vision = base.filter((m) => m.tags.includes(ModelTags.VISION));
      const rest = base.filter((m) => !m.tags.includes(ModelTags.VISION));
      const combined = [...vision, ...rest];
      if (options.modelId) {
        const chosen = combined.find((m) => m.id === options.modelId);
        return chosen ? [chosen, ...combined.filter((m) => m.id !== options.modelId)] : combined;
      }
      return combined;
    }
    if (options.preferFast) {
      const fast = base.filter((m) => m.tags.includes(ModelTags.FAST));
      const rest = base.filter((m) => !m.tags.includes(ModelTags.FAST));
      const combined = [...fast, ...rest];
      if (options.modelId) {
        const chosen = combined.find((m) => m.id === options.modelId);
        return chosen ? [chosen, ...combined.filter((m) => m.id !== options.modelId)] : combined;
      }
      return combined;
    }
    if (options.modelId) {
      const chosen = base.find((m) => m.id === options.modelId);
      return chosen ? [chosen, ...base.filter((m) => m.id !== options.modelId)] : base;
    }
    return base;
  }

  private tryAcquire(provider: AiProviderConfig, model: AiModelConfig): boolean {
    const now = Date.now();
    const active = this.inFlight.get(provider.id) ?? 0;
    if (active >= provider.maxConcurrent) return false;

    const lastProvider = this.lastRequestAt.get(provider.id);
    if (lastProvider !== undefined && now - lastProvider < provider.minIntervalMs) return false;

    if (provider.rateLimitScope === "MODEL") {
      const mk = `${provider.id}:${model.id}`;
      const lastModel = this.lastRequestAt.get(mk);
      if (lastModel !== undefined && now - lastModel < provider.minIntervalMs) return false;
      this.lastRequestAt.set(mk, now);
    }

    this.inFlight.set(provider.id, active + 1);
    this.lastRequestAt.set(provider.id, now);
    return true;
  }

  private release(providerId: string): void {
    const active = this.inFlight.get(providerId) ?? 1;
    this.inFlight.set(providerId, Math.max(0, active - 1));
  }

  markFailure(provider: AiProviderConfig, model: AiModelConfig, errorMsg: string): void {
    const key = this.healthKey(provider, model);
    const prev = this.health.get(key) ?? {
      id: key,
      isHealthy: true,
      lastCheck: Date.now(),
      consecutiveFailures: 0,
      lastError: null,
      averageLatencyMs: 0,
    };
    const nextFailures = prev.consecutiveFailures + 1;
    this.health.set(key, {
      ...prev,
      isHealthy: nextFailures < 3,
      consecutiveFailures: nextFailures,
      lastError: errorMsg,
      lastCheck: Date.now(),
    });
  }

  private markSuccess(provider: AiProviderConfig, model: AiModelConfig, latencyMs: number): void {
    const key = this.healthKey(provider, model);
    const prev = this.health.get(key);
    this.health.set(key, {
      id: key,
      isHealthy: true,
      lastCheck: Date.now(),
      consecutiveFailures: 0,
      lastError: null,
      averageLatencyMs: prev ? prev.averageLatencyMs * 0.7 + latencyMs * 0.3 : latencyMs,
    });
    this.currentModel = model;
  }

  async chat(options: KashkoolChatOptions): Promise<KashkoolChatResult> {
    this.processingCount++;
    try {
      const candidates = this.eligibleModels({
        modelId: options.modelId,
        requireVision: options.requireVision,
        preferFast: options.preferFast,
      });

      if (candidates.length === 0) {
        throw new Error("No eligible Kashkool AI models available.");
      }

      let lastError: Error | null = null;

      for (const model of candidates) {
        const provider = this.providers.get(model.providerId);
        if (!provider || !provider.enabled) continue;

        const systemContent = options.systemPrompt ?? this.systemPromptForModel(model);
        const fullMessages: ChatWireMessage[] = [
          { role: "system", content: systemContent },
          ...options.messages.filter((m) => m.role !== "system"),
        ];

        for (let attempt = 0; attempt <= this.maxRetries; attempt++) {
          if (!this.tryAcquire(provider, model)) {
            lastError = new Error(`Rate limit reached for ${provider.id}:${model.id}`);
            break;
          }

          const startedAt = Date.now();
          try {
            const wantStream = Boolean(options.onChunk) && !options.requireJson;
            const payload = buildOpenAiWirePayload({
              model: model.upstreamModel,
              messages: fullMessages,
              temperature: options.temperature ?? 0.6,
              maxTokens: options.maxTokens ?? model.maxOutputTokens,
              stream: wantStream,
            });

            const text = wantStream && options.onChunk
              ? await this.executeStreamingRequest(provider, payload, options.onChunk)
              : await this.executeJsonRequest(provider, payload);

            if (!text.trim()) {
              throw new Error(`Empty reply from ${model.id}`);
            }

            if (options.requireJson) {
              extractJsonFromText(text);
            }

            this.markSuccess(provider, model, Date.now() - startedAt);
            return {
              text,
              modelId: model.id,
              modelName: model.name,
              providerId: provider.id,
              upstreamModel: model.upstreamModel,
            };
          } catch (err) {
            lastError = err instanceof Error ? err : new Error(String(err));
            this.markFailure(provider, model, lastError.message);
            const isRateOrTimeout =
              lastError.message.includes("HTTP 429") || lastError.name === "TimeoutError";
            if (attempt < this.maxRetries && !isRateOrTimeout) {
              const delayMs = this.baseRetryDelayMs * (1 << attempt);
              await new Promise((r) => setTimeout(r, delayMs));
            } else {
              break;
            }
          } finally {
            this.release(provider.id);
          }
        }
      }

      throw lastError ?? new Error("All Kashkool AI providers failed.");
    } finally {
      this.processingCount = Math.max(0, this.processingCount - 1);
    }
  }

  async chatJson<T>(options: Omit<KashkoolChatOptions, "onChunk" | "requireJson">): Promise<{ data: T; meta: KashkoolChatResult }> {
    const result = await this.chat({
      ...options,
      requireJson: true,
    });
    return {
      data: extractJsonFromText<T>(result.text),
      meta: result,
    };
  }

  private async executeJsonRequest(provider: AiProviderConfig, payload: ChatWirePayload): Promise<string> {
    const url = `${provider.baseUrl.replace(/\/+$/, "")}/chat/completions`;
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      Accept: "application/json",
      "User-Agent": this.userAgent,
    };
    if (provider.apiKey) {
      headers.Authorization = `Bearer ${provider.apiKey}`;
    }

    const resp = await fetch(url, {
      method: "POST",
      headers,
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(this.requestTimeoutMs),
    });

    const rawBody = await resp.text();
    if (!resp.ok) {
      throw new Error(`HTTP ${resp.status} from ${provider.id}: ${rawBody.slice(0, 200)}`);
    }

    const parsed = JSON.parse(rawBody) as {
      choices?: Array<{ message?: { content?: string | null } }>;
    };
    return parsed.choices?.[0]?.message?.content ?? "";
  }

  private async executeStreamingRequest(
    provider: AiProviderConfig,
    payload: ChatWirePayload,
    onChunk: (chunk: string) => void
  ): Promise<string> {
    const url = `${provider.baseUrl.replace(/\/+$/, "")}/chat/completions`;
    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      Accept: "text/event-stream",
      "User-Agent": this.userAgent,
    };
    if (provider.apiKey) {
      headers.Authorization = `Bearer ${provider.apiKey}`;
    }

    const resp = await fetch(url, {
      method: "POST",
      headers,
      body: JSON.stringify({ ...payload, stream: true }),
      signal: AbortSignal.timeout(this.requestTimeoutMs),
    });

    if (!resp.ok) {
      const errText = await resp.text().catch(() => "");
      throw new Error(`HTTP ${resp.status} from ${provider.id}: ${errText.slice(0, 200)}`);
    }

    if (!resp.body) {
      return this.executeJsonRequest(provider, { ...payload, stream: false });
    }

    const reader = resp.body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";
    let full = "";

    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split(/\r?\n/);
      buffer = lines.pop() ?? "";

      for (const line of lines) {
        if (!line.startsWith("data:")) continue;
        const data = line.slice(5).trim();
        if (!data || data === "[DONE]") continue;
        try {
          const parsed = JSON.parse(data) as {
            choices?: Array<{ delta?: { content?: string | null } }>;
          };
          const delta = parsed.choices?.[0]?.delta?.content;
          if (delta) {
            full += delta;
            onChunk(delta);
          }
        } catch {
          // Ignore malformed SSE comment or keepalive frame
        }
      }
    }

    return full;
  }
}

export const kashkoolAiRouter = new KashkoolAiRouter();
