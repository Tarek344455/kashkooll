package com.dig.kashkool.aiclient

import com.dig.kashkool.aiclient.model.AiModel
import com.dig.kashkool.aiclient.model.AiProvider
import com.dig.kashkool.aiclient.model.ChatCompletionRequest
import com.dig.kashkool.aiclient.model.ChatCompletionResponse
import com.dig.kashkool.aiclient.model.ChatMessage
import com.dig.kashkool.aiclient.model.ModelTags
import com.dig.kashkool.aiclient.model.ProviderHealth
import com.dig.kashkool.aiclient.model.RateLimitScope
import com.dig.kashkool.aiclient.model.Tool
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.concurrent.Volatile

/**
 * Main entry point for the Kashkool AI Client.
 *
 * A **client-side** package that bundles every free/keyless model with its
 * provider metadata and runs entirely on the user's device — no server needed.
 *
 * Features:
 * - 7 live-verified keyless models across 3 sustainable providers
 * - Strongest-first routing with automatic failover
 * - Provider-aware rate limiting and circuit breakers
 * - Tool calling support where available
 * - Streaming responses
 * - Educational, friendly, socially & emotionally intelligent replies
 *
 * Providers included:
 * 1. **Kilo** (5 models) — ai-gateway.kilo.ai — keyless, model-scoped limits
 * 2. **llm7** (1 model) — api.llm7.io — keyless, provider-scoped, 1 concurrent
 * 3. **Pollinations** (1 model) — text.pollinations.ai — keyless, 45s per IP
 *
 * Usage:
 * ```kotlin
 * val client = KashkoolAiClient()
 * when (val result = client.chat("مرحباً، كيف يمكنني مساعدتك اليوم؟")) {
 *     is Result.Success -> println(result.value.choices.first().message.content)
 *     is Result.Failure -> println(result.exception.message)
 * }
 * ```
 */
class KashkoolAiClient(
    private val config: ClientConfig = ClientConfig(),
) {
    private val httpClient = HttpClient(config)

    private val stateMutex = Mutex()
    private val providers = mutableMapOf<String, AiProvider>()
    private val models = mutableMapOf<String, AiModel>()
    private val health = mutableMapOf<String, ProviderHealth>()
    private val inFlight = mutableMapOf<String, Int>()
    private val lastRequestAt = mutableMapOf<String, Long>()

    private val _availableModels = MutableStateFlow<List<AiModel>>(emptyList())
    /** Models currently eligible for routing, strongest first. */
    val availableModels: StateFlow<List<AiModel>> = _availableModels

    private val _currentModel = MutableStateFlow<AiModel?>(null)
    /** Last model that produced a successful response. */
    val currentModel: StateFlow<AiModel?> = _currentModel

    private val _isProcessing = MutableStateFlow(false)
    /** True while a chat call is in flight. */
    val isProcessing: StateFlow<Boolean> = _isProcessing

    init {
        initializeBuiltInProviders()
        initializeBuiltInModels()
        refreshAvailableLocked()
    }

    companion object {
        @Volatile
        private var INSTANCE: KashkoolAiClient? = null

        /** Returns a process-wide singleton built with [config]. */
        fun getInstance(config: ClientConfig = ClientConfig()): KashkoolAiClient =
            INSTANCE ?: KashkoolAiClient(config).also { INSTANCE = it }

        /** Drops the singleton so the next call rebuilds it. */
        fun resetInstance() {
            INSTANCE?.close()
            INSTANCE = null
        }
    }

    // ------------------------------------------------------------------
    // Built-in catalog
    // ------------------------------------------------------------------

    private fun initializeBuiltInProviders() {
        val kilo = AiProvider(
            id = "kilo",
            name = "Kilo AI Gateway",
            baseUrl = "https://ai-gateway.kilo.ai/api/v1",
            maxConcurrent = 3,
            minIntervalMs = 150,
            cooldownMs = 60000,
            authCooldownMs = 3600000,
            rateLimitScope = RateLimitScope.MODEL,
            note = "Kilo anonymous free tier. One provider, five verified models. " +
                "A 429 is model-scoped here, so only the busy model cools down.",
        )
        val llm7 = AiProvider(
            id = "llm7",
            name = "llm7.io",
            baseUrl = "https://api.llm7.io/v1",
            maxConcurrent = 1,
            minIntervalMs = 1200,
            cooldownMs = 15000,
            authCooldownMs = 3600000,
            rateLimitScope = RateLimitScope.PROVIDER,
            note = "llm7 keyless. codestral-latest is the only frontier-class model " +
                "that stays open without a key. One concurrent request is the hard rule.",
        )
        val pollinations = AiProvider(
            id = "pollinations",
            name = "Pollinations AI",
            baseUrl = "https://text.pollinations.ai/openai",
            maxConcurrent = 1,
            minIntervalMs = 45000,
            cooldownMs = 45000,
            authCooldownMs = 3600000,
            rateLimitScope = RateLimitScope.PROVIDER,
            note = "Pollinations keyless. Absolute last resort: one reply every " +
                "45 seconds per IP, spaced so a burst never burns it.",
        )
        val localGemma = AiProvider(
            id = "local-gemma",
            name = "Local Gemma 4 E2B",
            baseUrl = "http://127.0.0.1:8080/v1",
            maxConcurrent = 2,
            minIntervalMs = 100,
            cooldownMs = 5000,
            rateLimitScope = RateLimitScope.PROVIDER,
            note = "Local Gemma 4 E2B via litertlm server. Highest quality, zero " +
                "latency, full privacy. Requires a local server on port 8080.",
            enabled = false,
        )
        val openrouter = AiProvider(
            id = "openrouter",
            name = "OpenRouter",
            baseUrl = "https://openrouter.ai/api/v1",
            apiKey = getEnv("OPENROUTER_API_KEY") ?: "",
            requiresApiKey = true,
            enabled = false,
            maxConcurrent = 2,
            minIntervalMs = 200,
            cooldownMs = 30000,
            authCooldownMs = 3600000,
            rateLimitScope = RateLimitScope.MODEL,
            note = "OpenRouter aggregator. Access to many free models via one key. " +
                "Requires OPENROUTER_API_KEY in .env",
        )
        val nvidia = AiProvider(
            id = "nvidia",
            name = "NVIDIA Build",
            baseUrl = "https://integrate.api.nvidia.com/v1",
            apiKey = getEnv("NVIDIA_API_KEY") ?: "",
            requiresApiKey = true,
            enabled = false,
            maxConcurrent = 2,
            minIntervalMs = 300,
            cooldownMs = 30000,
            authCooldownMs = 3600000,
            rateLimitScope = RateLimitScope.MODEL,
            note = "NVIDIA API catalog. Nemotron and other NVIDIA models. " +
                "Requires NVIDIA_API_KEY in .env",
        )
        val opencode = AiProvider(
            id = "opencode",
            name = "OpenCode",
            baseUrl = "https://api.opencode.sh/v1",
            apiKey = getEnv("OPENCODE_API_KEY") ?: "",
            requiresApiKey = true,
            enabled = false,
            maxConcurrent = 2,
            minIntervalMs = 200,
            cooldownMs = 30000,
            authCooldownMs = 3600000,
            rateLimitScope = RateLimitScope.MODEL,
            note = "OpenCode models. Requires OPENCODE_API_KEY in .env",
        )

        listOf(kilo, llm7, pollinations, localGemma, openrouter, nvidia, opencode).forEach { provider ->
            providers[provider.id] = provider
            health[provider.id] = ProviderHealth(providerId = provider.id, isHealthy = provider.enabled)
            inFlight[provider.id] = 0
        }
    }

    private fun initializeBuiltInModels() {
        val kiloModels = listOf(
            AiModel(
                id = "kilo-nemotron-3-ultra",
                name = "Nemotron 3 Ultra",
                upstreamModel = "nvidia/nemotron-3-ultra-550b-a55b:free",
                providerId = "kilo",
                quality = 0.88,
                contextWindow = 131072,
                supportsTools = true,
                minOutputTokens = 512,
                description = "NVIDIA's flagship reasoning model. Excellent for complex analysis, " +
                    "coding, and multi-step reasoning. Best quality in the free tier.",
                tags = listOf(
                    ModelTags.REASONING, ModelTags.CODING, ModelTags.ANALYTICAL,
                    ModelTags.FREE, ModelTags.KEYLESS,
                ),
                maxOutputTokens = 8192,
            ),
            AiModel(
                id = "kilo-nemotron-3.5-super-vl",
                name = "Nemotron 3.5 Super VL",
                upstreamModel = "nvidia/nemotron-3.5-super-vl:free",
                providerId = "kilo",
                quality = 0.82,
                contextWindow = 131072,
                supportsTools = true,
                minOutputTokens = 512,
                description = "Vision-language model with strong visual reasoning. Great for " +
                    "image analysis, document understanding, and multimodal tasks.",
                tags = listOf(
                    ModelTags.VISION, ModelTags.REASONING, ModelTags.MULTILINGUAL,
                    ModelTags.FREE, ModelTags.KEYLESS,
                ),
                maxOutputTokens = 8192,
            ),
            AiModel(
                id = "kilo-nemotron-3-nano-reasoning",
                name = "Nemotron 3 Nano Reasoning",
                upstreamModel = "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free",
                providerId = "kilo",
                quality = 0.80,
                contextWindow = 131072,
                supportsTools = true,
                minOutputTokens = 512,
                description = "Compact but powerful reasoning model. Faster than Ultra with " +
                    "strong logical capabilities — a good speed/quality balance.",
                tags = listOf(
                    ModelTags.REASONING, ModelTags.FAST, ModelTags.CODING,
                    ModelTags.FREE, ModelTags.KEYLESS,
                ),
                maxOutputTokens = 8192,
            ),
            AiModel(
                id = "kilo-nemotron-3.5-lightning",
                name = "Nemotron 3.5 Lightning",
                upstreamModel = "nvidia/nemotron-3.5-lightning:free",
                providerId = "kilo",
                quality = 0.78,
                contextWindow = 131072,
                supportsTools = true,
                minOutputTokens = 512,
                description = "Optimized for speed. Fastest Nemotron variant — great for " +
                    "real-time chat, quick answers, and high-throughput scenarios.",
                tags = listOf(
                    ModelTags.FAST, ModelTags.CREATIVE, ModelTags.MULTILINGUAL,
                    ModelTags.FREE, ModelTags.KEYLESS,
                ),
                maxOutputTokens = 8192,
            ),
            AiModel(
                id = "kilo-flint-1.0",
                name = "Flint 1.0",
                upstreamModel = "recursive/flint-v1.0:free",
                providerId = "kilo",
                quality = 0.75,
                contextWindow = 131072,
                supportsTools = true,
                minOutputTokens = 2048,
                description = "Recursive's Flint model. Strong general-purpose capabilities " +
                    "with good instruction following — a reliable workhorse.",
                tags = listOf(
                    ModelTags.CREATIVE, ModelTags.ANALYTICAL, ModelTags.LONG_CONTEXT,
                    ModelTags.FREE, ModelTags.KEYLESS,
                ),
                maxOutputTokens = 8192,
            ),
        )

        val llm7Models = listOf(
            AiModel(
                id = "llm7-codestral",
                name = "Codestral Latest",
                upstreamModel = "codestral-latest",
                providerId = "llm7",
                quality = 0.70,
                contextWindow = 131072,
                supportsTools = false,
                minOutputTokens = 0,
                description = "Mistral's specialized coding model. Excellent for code " +
                    "generation, debugging, and technical tasks.",
                tags = listOf(ModelTags.CODING, ModelTags.REASONING, ModelTags.FREE, ModelTags.KEYLESS),
                maxOutputTokens = 8192,
            ),
        )

        val pollinationsModels = listOf(
            AiModel(
                id = "pollinations-openai",
                name = "Pollinations OpenAI",
                upstreamModel = "openai",
                providerId = "pollinations",
                quality = 0.40,
                contextWindow = 131072,
                supportsTools = true,
                minOutputTokens = 0,
                description = "Pollinations' OpenAI-compatible endpoint. Last-resort " +
                    "fallback, limited to one request per 45 seconds per IP.",
                tags = listOf(ModelTags.FAST, ModelTags.FREE, ModelTags.KEYLESS),
                maxOutputTokens = 4096,
            ),
        )

        val openrouterModels = listOf(
            AiModel(
                id = "openrouter-nemotron",
                name = "Nemotron via OpenRouter",
                upstreamModel = "nvidia/nemotron-3-ultra-550b-a55b:free",
                providerId = "openrouter",
                quality = 0.88,
                contextWindow = 131072,
                supportsTools = true,
                minOutputTokens = 512,
                description = "Nemotron 3 Ultra via OpenRouter. Best reasoning quality " +
                    "in the free tier. Requires OPENROUTER_API_KEY.",
                tags = listOf(
                    ModelTags.REASONING, ModelTags.CODING, ModelTags.ANALYTICAL,
                ),
                maxOutputTokens = 8192,
            ),
        )

        val nvidiaModels = listOf(
            AiModel(
                id = "nvidia-nemotron",
                name = "Nemotron via NVIDIA",
                upstreamModel = "nvidia/nemotron-3-ultra-550b-a55b",
                providerId = "nvidia",
                quality = 0.88,
                contextWindow = 131072,
                supportsTools = true,
                minOutputTokens = 512,
                description = "Nemotron 3 Ultra via NVIDIA API. Direct from NVIDIA. " +
                    "Requires NVIDIA_API_KEY.",
                tags = listOf(
                    ModelTags.REASONING, ModelTags.CODING, ModelTags.ANALYTICAL,
                ),
                maxOutputTokens = 8192,
            ),
        )

        val opencodeModels = listOf(
            AiModel(
                id = "opencode-default",
                name = "OpenCode Default",
                upstreamModel = "default",
                providerId = "opencode",
                quality = 0.85,
                contextWindow = 131072,
                supportsTools = true,
                minOutputTokens = 512,
                description = "OpenCode assistant model. Educational and helpful. " +
                    "Requires OPENCODE_API_KEY.",
                tags = listOf(
                    ModelTags.REASONING, ModelTags.CODING, ModelTags.MULTILINGUAL,
                ),
                maxOutputTokens = 8192,
            ),
        )

        val localModels = listOf(
            AiModel(
                id = "local-gemma-4-e2b",
                name = "Gemma 4 E2B (Local)",
                upstreamModel = "gemma-4-e2b-it",
                providerId = "local-gemma",
                quality = 0.95,
                contextWindow = 131072,
                supportsTools = true,
                minOutputTokens = 512,
                description = "Local Gemma 4 2B model. Highest quality, zero latency, full " +
                    "privacy. Requires a local litertlm server on port 8080.",
                tags = listOf(
                    ModelTags.REASONING, ModelTags.CODING, ModelTags.ANALYTICAL, ModelTags.LONG_CONTEXT,
                ),
                maxOutputTokens = 8192,
            ),
        )

        (kiloModels + llm7Models + pollinationsModels + openrouterModels + nvidiaModels + opencodeModels + localModels).forEach { model ->
            models[model.id] = model
        }
    }

    // ------------------------------------------------------------------
    // Public chat API
    // ------------------------------------------------------------------

    /**
     * Sends [message] and returns the model's reply, using strongest-first
     * routing with automatic failover down the ladder.
     *
     * @param systemPrompt null keeps the built-in Egyptian-Arabic educational persona.
     * @param onChunk when non-null the reply is streamed chunk by chunk.
     */
    suspend fun chat(
        message: String,
        systemPrompt: String? = null,
        modelId: String? = null,
        temperature: Double = config.defaultTemperature,
        maxTokens: Int? = null,
        tools: List<Tool>? = null,
        onChunk: ((String) -> Unit)? = null,
    ): Result<ChatCompletionResponse> {
        _isProcessing.value = true
        try {
            val candidates = stateMutex.withLock { eligibleModelsLocked(modelId) }
            if (candidates.isEmpty()) {
                return Result.failure(IllegalStateException("No eligible models available"))
            }

            var lastError: Exception? = null

            for (model in candidates) {
                val provider = stateMutex.withLock { providers[model.providerId] } ?: continue
                if (!provider.enabled) continue

                val effectivePrompt = systemPrompt ?: systemPromptForModel(model)

                // Try with retries for this model
                var attempt = 0
                while (attempt <= config.maxRetries) {
                    val acquired = stateMutex.withLock { tryAcquireLocked(provider, model) }
                    if (!acquired) {
                        lastError = IllegalStateException("Rate limit reached for provider '${provider.id}'")
                        break // Don't retry if rate limited, failover to next model
                    }

                    try {
                        val request = ChatCompletionRequest(
                            model = model.upstreamModel,
                            messages = buildMessages(message, effectivePrompt),
                            temperature = temperature,
                            maxTokens = maxTokens ?: config.defaultMaxTokens ?: model.maxOutputTokens,
                            stream = onChunk != null && config.enableStreaming,
                            tools = if (model.supportsTools) tools else null,
                        )
                        val response = if (onChunk != null && config.enableStreaming) {
                            httpClient.streamChat(provider, request, onChunk)
                        } else {
                            httpClient.chat(provider, request)
                        }
                        stateMutex.withLock {
                            markHealthyLocked(provider.id)
                            _currentModel.value = model
                        }
                        return Result.success(response)
                    } catch (e: Exception) {
                        lastError = e
                        stateMutex.withLock { markFailureLocked(provider.id, e) }
                        attempt++
                        if (attempt <= config.maxRetries && config.enableAutoFailover) {
                            // Exponential backoff before retry
                            val delay = config.baseRetryDelayMs * (2L shl (attempt - 1))
                            kotlinx.coroutines.delay(delay)
                        }
                    } finally {
                        stateMutex.withLock { releaseLocked(provider.id, model) }
                    }
                }
            }

            return Result.failure(
                lastError ?: IllegalStateException("All models failed without a reported error"),
            )
        } finally {
            _isProcessing.value = false
        }
    }

    // ------------------------------------------------------------------
    // Introspection & administration
    // ------------------------------------------------------------------

    /** All models, including unavailable ones. */
    fun getAllModels(): List<AiModel> = models.values.toList()

    fun getModelsByProvider(providerId: String): List<AiModel> =
        models.values.filter { it.providerId == providerId }

    fun getModelsByTag(tag: String): List<AiModel> =
        models.values.filter { tag in it.tags }

    /** Enables or disables a provider; disabled providers are skipped. */
    suspend fun setProviderEnabled(providerId: String, enabled: Boolean) = stateMutex.withLock {
        val provider = providers[providerId] ?: return@withLock
        providers[providerId] = provider.withEnabled(enabled)
        health[providerId] = health[providerId]?.copy(isHealthy = enabled)
            ?: ProviderHealth(providerId = providerId, isHealthy = enabled)
        refreshAvailableLocked()
    }

    /** Sets or replaces the API key of a provider. */
    suspend fun setProviderApiKey(providerId: String, apiKey: String) = stateMutex.withLock {
        val provider = providers[providerId] ?: return@withLock
        providers[providerId] = provider.withApiKey(apiKey)
    }

    /** Resets circuit breakers and re-evaluates provider health. */
    suspend fun refreshHealth() = stateMutex.withLock {
        providers.values.forEach { provider ->
            health[provider.id] = (health[provider.id]
                ?: ProviderHealth(providerId = provider.id))
                .copy(
                    isHealthy = provider.enabled,
                    consecutiveFailures = 0,
                    lastError = null,
                    lastCheck = nowMillis(),
                )
        }
        refreshAvailableLocked()
    }

    /** Snapshot of the client state. */
    fun getStats(): ClientStats {
        val available = _availableModels.value
        return ClientStats(
            totalModels = models.size,
            availableModels = available.size,
            enabledProviders = providers.values.count { it.enabled },
            healthyProviders = health.values.count { it.isHealthy },
            currentModel = _currentModel.value?.name,
            isProcessing = _isProcessing.value,
        )
    }

    /** Closes the client and releases all resources. */
    fun close() {
        httpClient.close()
    }

    /** The built-in Egyptian-Arabic educational persona. */
    fun defaultSystemPrompt(): String = Prompt.DEFAULT_SYSTEM_PROMPT

    /** Egyptian-Arabic system prompt for OpenRouter models. */
    fun openrouterSystemPrompt(): String = Prompt.OPENROUTER_SYSTEM_PROMPT

    /** Egyptian-Arabic system prompt for NVIDIA models. */
    fun nvidiaSystemPrompt(): String = Prompt.NVIDIA_SYSTEM_PROMPT

    /** Egyptian-Arabic system prompt for OpenCode models. */
    fun opencodeSystemPrompt(): String = Prompt.OPENCODE_SYSTEM_PROMPT

    // ------------------------------------------------------------------
    // Routing internals (all *Locked methods require stateMutex)
    // ------------------------------------------------------------------

    private fun eligibleModelsLocked(modelId: String?): List<AiModel> {
        val now = nowMillis()
        val eligible = models.values.filter { model ->
            val provider = providers[model.providerId] ?: return@filter false
            if (!provider.enabled || !model.isAvailable) return@filter false
            // Providers that require an API key are skipped if no key is configured
            if (provider.requiresApiKey && provider.apiKey.isBlank()) return@filter false
            val state = health[model.providerId]
            if (state != null && state.isCircuitOpen && now - state.lastCheck < provider.cooldownMs) {
                return@filter false
            }
            true
        }.sortedByDescending { it.effectiveQuality }

        if (modelId == null) return eligible

        val explicit = eligible.firstOrNull { it.id == modelId }
        return if (explicit == null) eligible else listOf(explicit) + eligible.filter { it.id != modelId }
    }

    private fun tryAcquireLocked(provider: AiProvider, model: AiModel? = null): Boolean {
        val now = nowMillis()
        
        // Check provider-level concurrency
        if ((inFlight[provider.id] ?: 0) >= provider.maxConcurrent) return false
        
        // Check provider-level min interval
        val lastProvider = lastRequestAt[provider.id]
        if (lastProvider != null && now - lastProvider < provider.minIntervalMs) return false
        
        // Check model-level rate limit for Kilo (model-scoped)
        if (provider.rateLimitScope == RateLimitScope.MODEL && model != null) {
            val modelKey = "${provider.id}:${model.id}"
            val lastModel = lastRequestAt[modelKey]
            if (lastModel != null && now - lastModel < provider.minIntervalMs) return false
            lastRequestAt[modelKey] = now
        }
        
        inFlight[provider.id] = (inFlight[provider.id] ?: 0) + 1
        lastRequestAt[provider.id] = now
        return true
    }

    private fun releaseLocked(providerId: String, model: AiModel? = null) {
        inFlight[providerId] = ((inFlight[providerId] ?: 1) - 1).coerceAtLeast(0)
        // Model-level tracking doesn't need release, just timestamp
    }

    private fun markHealthyLocked(providerId: String) {
        val state = health[providerId] ?: ProviderHealth(providerId = providerId)
        health[providerId] = state.withSuccess(0.0)
        refreshAvailableLocked()
    }

    private fun markFailureLocked(providerId: String, error: Exception) {
        val state = health[providerId] ?: ProviderHealth(providerId = providerId)
        health[providerId] = state.withFailure(error.message ?: "Unknown error")
        refreshAvailableLocked()
    }

    private fun refreshAvailableLocked() {
        val available = models.values.filter { model ->
            providers[model.providerId]?.enabled == true &&
                health[model.providerId]?.isHealthy == true &&
                model.isAvailable
        }.sortedByDescending { it.effectiveQuality }

        _availableModels.value = available
        if (_currentModel.value?.let { current -> available.any { it.id == current.id } } != true) {
            _currentModel.value = available.firstOrNull()
        }
    }

    private fun buildMessages(userMessage: String, systemPrompt: String): List<ChatMessage> =
        listOf(ChatMessage.system(systemPrompt), ChatMessage.user(userMessage))

    /** Chooses the right Egyptian-Arabic system prompt based on the model's provider. */
    internal fun systemPromptForModel(model: AiModel): String =
        when (model.providerId) {
            "openrouter" -> openrouterSystemPrompt()
            "nvidia" -> nvidiaSystemPrompt()
            "opencode" -> opencodeSystemPrompt()
            else -> defaultSystemPrompt()
        }
}

/**
 * Built-in persona text, kept outside the class because a Kotlin class may
 * declare only one companion object.
 */
private object Prompt {
    val DEFAULT_SYSTEM_PROMPT: String = """
            أنت مساعد ذكي تعليمي وودود ومتعاطف، مصمم خصيصاً لبيئة تعليمية مصرية.

            شخصيتك:
            - تعليمي: تشرح المفاهيم ببساطة ووضوح، وتشجع على التعلم والاستكشاف.
            - ودود: تتحدث بلهجة مصرية طبيعية ودافئة، وتستخدم "انت" و"احنا" و"خلينا".
            - ذكي اجتماعياً: تفهم السياق الاجتماعي، وتحترم القيم، وتتجنب المواضيع الحساسة.
            - ذكي عاطفياً: تتعاطف مع مشاعر المستخدم، وتقدم الدعم المعنوي، وتحتفل بالنجاحات.
            - مفيد عملياً: تقدم حلولاً عملية وخطوات واضحة وأمثلة من الواقع المصري.

            إرشادات الرد:
            1. ابدأ بتحية دافئة إذا كانت أول رسالة.
            2. استخدم لغة عربية مصرية بسيطة وواضحة.
            3. قسم الردود الطويلة لنقاط مرقمة أو فقرات قصيرة.
            4. قدم أمثلة عملية من الحياة اليومية في مصر.
            5. شجع المستخدم واطمئن عليه.
            6. إذا لم تعرف الإجابة، قل ذلك بصراحة واقترح بدائل.
            7. احترم الخصوصية ولا تطلب معلومات شخصية حساسة.
            8. كن شاملاً وراعِ اختلاف المستويات والخلفيات.

            تذكّر: هدفك أن يخرج المستخدم من المحادثة وهو مستفيد ومطمئن ومتحمس للتعلم أكثر.
        """.trimIndent()

    /** Egyptian-Arabic educational persona for OpenRouter models. */
    val OPENROUTER_SYSTEM_PROMPT: String = """
        أنت مساعد ذكي تعليمي ومتعاطف من كاشكول، تتحدث بلهجة مصرية طبيعية.

        شخصيتك:
        - تعليمي: تشرح المفاهيم ببساطة ووضوح، وتشجع على التعلم والاستكشاف.
        - ودود: تستخدم "انت" و"احنا" و"خلينا"، وتكون دافئ مع المستخدم.
        - ذكي اجتماعياً: تفهم السياق المصري، وتحترم العادات والقيم.
        - ذكي عاطفياً: تتعاطف مع مشاعر المستخدم، وتدعمه المعنوياً، تحتفل بنجاحاته.
        - مفيد عملياً: تقدم حلولاً عملية وخطوات واضحة وأمثلة من الحياة اليومية في مصر.

        إرشادات الرد:
        1. ابدأ بتحية دافئة مصرية إذا كانت أول رسالة.
        2. تحدث بالعربية المصرية البسيطة والواضحة.
        3. قسم الردود الطويلة لنقاط مرقمة أو فقرات قصيرة.
        4. قدم أمثلة من الواقع المصري (القاهرة، الإسكندرية، الصعيد، إلخ).
        5. شجع المستخدم واطمئن عليه.
        6. إذا لم تعرف الإجابة، قل ذلك بصراحة واقترح بدائل.
        7. احترم الخصوصية ولا تطلب معلومات شخصية حساسة.

        تذكّر: هدفك أن يخرج المستخدم وهو مستفيد ومطمئن ومتحمس للتعلم أكثر.
    """.trimIndent()

    /** Egyptian-Arabic educational persona for NVIDIA models. */
    val NVIDIA_SYSTEM_PROMPT: String = """
        أنت مساعد ذكي تعليمي من كاشكول، تعمل على موديلات إنفيديا، وتحدث بلهجة مصرية طبيعية.

        شخصيتك:
        - تعليمي قوي: تشرح المفاهيم الصعبة ببساطة، مع أمثلة عملية من الحياة اليومية.
        - ودود مصرى: تتحدث باحترام ودفء، وتستخدم "انت" و"احنا".
        - ذكي اجتماعياً وعاطفياً: تفهم مزاج المستخدم وتدعمه conنفسية.
        - دقيق وموثوق: تقدم معلومات صحيحة ولا تخترع إجابات.

        إرشادات الرد:
        1. تحية مصرية دافئة في بداية المحادثة.
        2. لغة عربية مصرية بسيطة وواضحة.
        3. ردود منظمة بنقاط مرقمة أو فقرات قصيرة.
        4. أمثلة واقعية من البيئات والمدارس والمراكز التعليمية في مصر.
        5. شجع المتعلمين واطمئن على تقدمهم.
        6. إذا لم تكن متأكداً من الإجابة، اعترف بذلك اقترح بديل.

        هدفك: أن يشعر المستخدم بالاستفادة والطمأنينة والحماس للتعلم.
    """.trimIndent()

    /** Egyptian-Arabic educational persona for OpenCode models. */
    val OPENCODE_SYSTEM_PROMPT: String = """
        أنت مساعد برمجي وتعليمي ذكي من كاشكول، تتحدث بلهجة مصرية طبيعية.

        شخصيتك:
        - تعليم تقني بسيط: تشرح الكود والبرمجة بلغة عربية مصرية مفهومة.
        - ودود ومتعاطف: تدعم المبرمج المبتدئ والمحترف على حد سواء.
        - ذكي اجتماعياً: تفهم سياق العمل والمشاريع في مصر.
        - عملي: تقدم كود قابل للتشغيل وأمثلة واقعية.

        إرشادات الرد:
        1. تحية مصرية دافئة إذا كانت أول رسالة.
        2. تحدث بالعربية المصرية الواضحة، مع تعليقات عربية في الكود عند الحاجة.
        3. قسم الشرح إلى خطوات مرقمة.
        4. قدم أمثلة كود عملية من الواقع المصري (تطبيقات محلية، مواقع، إلخ).
        5. شجع على التعلم الذاتي والاستكشاف.
        6. إذا لم تعرف الإجابة، قل ذلك بصراحة واقترح موارد بديلة.

        هدفك: أن يصبح المستخدم مبرمجاً أفضل وأكثر ثقة في نفسه.
    """.trimIndent()
}

/**
 * Client configuration.
 */
data class ClientConfig(
    val defaultTemperature: Double = 0.7,
    val defaultMaxTokens: Int? = null,
    val enableAutoFailover: Boolean = true,
    val enableStreaming: Boolean = true,
    val userAgent: String = "KashkoolAiClient/1.0",
    val defaultRequestTimeoutMs: Long = 300_000,
    val defaultConnectTimeoutMs: Long = 30_000,
    val defaultSocketTimeoutMs: Long = 300_000,
    val maxRetries: Int = 2,
    val baseRetryDelayMs: Long = 1_000,
) {
    companion object {
        fun default(): ClientConfig = ClientConfig()
    }
}

/**
 * Client statistics snapshot.
 */
data class ClientStats(
    val totalModels: Int,
    val availableModels: Int,
    val enabledProviders: Int,
    val healthyProviders: Int,
    val currentModel: String?,
    val isProcessing: Boolean,
)
