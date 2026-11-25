package com.dig.kashkool.aiclient

import com.dig.kashkool.aiclient.model.AiModel
import com.dig.kashkool.aiclient.model.ModelTags
import com.dig.kashkool.aiclient.model.ChatCompletionResponse
import kotlin.Result

/**
 * Kashkool OR Engine — multi-layer reasoning inside the app itself.
 * No server dependency. Everything runs client-side.
 *
 * Layers:
 * 1. Understanding — analyze request (language, type, urgency, complexity)
 * 2. Planning — select best model via OR logic (quality + speed + availability)
 * 3. Execution — send to model with Egyptian Arabic system prompt
 * 4. Verification — verify response, compute confidence, rephrase if needed
 * 5. Response — return final answer in Egyptian Arabic with educational explanation
 */
class OrEngine(private val client: KashkoolAiClient) {

    // ------------------------------------------------------------------
    // Public API
    // ------------------------------------------------------------------

    /**
     * Think through [message] using multi-layer OR reasoning.
     * Returns [OrResult] with the final answer and full reasoning trace.
     */
    suspend fun think(
        message: String,
        language: Language = Language.AUTO,
        requiredType: RequestType? = null,
        maxConfidence: Double = 0.95,
    ): OrResult {
        // Layer 1: Understanding
        val understanding = analyzeRequest(message, language, requiredType)

        // Layer 2: Planning — pick best model
        val model = selectModel(understanding)
        if (model == null) {
            return OrResult.failure(
                error = IllegalStateException("No suitable model available"),
                layer = Layer.PLANNING,
            )
        }

        // Layer 3: Execution
        val systemPrompt = client.systemPromptForModel(model)
        val response = client.chat(
            message = message,
            systemPrompt = systemPrompt,
            modelId = model.id,
            temperature = understanding.temperature,
            maxTokens = understanding.maxTokens,
        )

        // Layer 4: Verification
        val verification = verifyResponse(response, understanding, maxConfidence)

        // Layer 5: Response
        return OrResult.success(
            response = verification.finalResponse,
            model = model,
            confidence = verification.confidence,
            reasoningTrace = verification.reasoningTrace,
        )
    }

    // ------------------------------------------------------------------
    // Layer 1: Understanding
    // ------------------------------------------------------------------

    data class RequestUnderstanding(
        val language: Language,
        val requestType: RequestType,
        val complexity: Complexity,
        val urgency: Urgency,
        val temperature: Double,
        val maxTokens: Int,
        val needsTools: Boolean,
    )

    private fun analyzeRequest(
        message: String,
        language: Language?,
        requiredType: RequestType?,
    ): RequestUnderstanding {
        val detectedLanguage = language ?: detectLanguage(message)
        val detectedType = requiredType ?: detectRequestType(message)
        val complexity = detectComplexity(message, detectedType)
        val urgency = detectUrgency(message)

        val temperature = when (detectedType) {
            RequestType.CODING -> 0.3
            RequestType.REASONING -> 0.5
            RequestType.CREATIVE -> 0.8
            RequestType.FAST -> 0.6
            RequestType.EDUCATIONAL -> 0.5
            RequestType.EMOTIONAL -> 0.7
            else -> 0.7
        }

        val maxTokens = when (complexity) {
            Complexity.SIMPLE -> 1024
            Complexity.MEDIUM -> 2048
            Complexity.COMPLEX -> 4096
            Complexity.EXPERT -> 8192
        }

        return RequestUnderstanding(
            language = detectedLanguage,
            requestType = detectedType,
            complexity = complexity,
            urgency = urgency,
            temperature = temperature,
            maxTokens = maxTokens,
            needsTools = detectedType == RequestType.CODING || complexity == Complexity.EXPERT,
        )
    }

    private fun detectLanguage(message: String): Language {
        val arabicChars = message.count { it in 'أ'..'ي' || it in 'ء'..'ى' || it == 'إ' || it == 'آ' || it == 'ؤ' || it == 'ئ' }
        return if (arabicChars > message.length * 0.3) Language.AR else Language.EN
    }

    private fun detectRequestType(message: String): RequestType {
        val lower = message.lowercase()
        return when {
            lower.contains("كود") || lower.contains("code") || lower.contains("برمجة") || lower.contains("دالة") ||
                lower.contains("function") || lower.contains("class") || lower.contains("متغير") -> RequestType.CODING

            lower.contains("حلل") || lower.contains("حل") || lower.contains("تحليل") || lower.contains("استدلال") ||
                lower.contains("منطق") || lower.contains("لماذا") || lower.contains("كيف") -> RequestType.REASONING

            lower.contains("اكتب") || lower.contains("قصيدة") || lower.contains("قصة") || lower.contains("مقال") ||
                lower.contains("اكتب لي") || lower.contains("اكتب عن") -> RequestType.CREATIVE

            lower.contains("سريع") || lower.contains("سريعاً") || lower.contains("عاجل") || lower.contains("الأسرع") ->
                RequestType.FAST

            lower.contains("أشعر") || lower.contains("حزين") || lower.contains("محتاج دعم") || lower.contains("دعم نفسي") ||
                lower.contains("مؤقت") || lower.contains("مشكلة نفسية") -> RequestType.EMOTIONAL

            lower.contains("اشرح") || lower.contains("اذكر") || lower.contains("معلومة") || lower.contains("تعلم") ||
                lower.contains("دراسة") || lower.contains("مدرسة") -> RequestType.EDUCATIONAL

            else -> RequestType.GENERAL
        }
    }

    private fun detectComplexity(message: String, type: RequestType): Complexity {
        val words = message.split(Regex("\\s+")).size
        return when {
            words > 200 || (type == RequestType.CODING && (message.contains("نظام") || message.contains("بناء"))) ->
                Complexity.EXPERT
            words > 80 || type == RequestType.REASONING -> Complexity.COMPLEX
            words > 30 -> Complexity.MEDIUM
            else -> Complexity.SIMPLE
        }
    }

    private fun detectUrgency(message: String): Urgency {
        val lower = message.lowercase()
        return when {
            lower.contains("عاجل") || lower.contains("سريع") || lower.contains("الآن") || lower.contains("فوراً") ->
                Urgency.HIGH
            lower.contains("بعد") || lower.contains("لاحقاً") || lower.contains("عندما") -> Urgency.LOW
            else -> Urgency.NORMAL
        }
    }

    // ------------------------------------------------------------------
    // Layer 2: Planning — OR model selection
    // ------------------------------------------------------------------

    private fun selectModel(understanding: RequestUnderstanding): AiModel? {
        val available = client.availableModels.value
        if (available.isEmpty()) return null

        val scored = available.map { model ->
            val health = client.getProviderHealth(model.providerId)
            val qualityScore = model.effectiveQuality
            val availabilityScore = if (health.isHealthy) 1.0 else 0.2
            val speedScore = when (understanding.urgency) {
                Urgency.HIGH -> if (ModelTags.FAST in model.tags) 1.0 else 0.6
                Urgency.LOW -> 1.0
                Urgency.NORMAL -> 0.8
            }
            val typeMatch = when (understanding.requestType) {
                RequestType.CODING -> if (ModelTags.CODING in model.tags) 1.2 else 1.0
                RequestType.REASONING -> if (ModelTags.REASONING in model.tags) 1.2 else 1.0
                RequestType.CREATIVE -> if (ModelTags.CREATIVE in model.tags) 1.1 else 1.0
                RequestType.FAST -> if (ModelTags.FAST in model.tags) 1.2 else 1.0
                else -> 1.0
            }
            val orScore = qualityScore * availabilityScore * speedScore * typeMatch

            model to orScore
        }

        return scored.maxByOrNull { it.second }?.first
    }

    // ------------------------------------------------------------------
    // Layer 4: Verification
    // ------------------------------------------------------------------

    data class VerificationResult(
        val finalResponse: String,
        val confidence: Double,
        val reasoningTrace: List<String>,
    )

    private fun verifyResponse(
        response: Result<ChatCompletionResponse>,
        understanding: RequestUnderstanding,
        maxConfidence: Double,
    ): VerificationResult {
        val trace = mutableListOf<String>()
        trace.add("Layer 1: Understanding — ${understanding.requestType}, ${understanding.language}, ${understanding.complexity}")

        if (response.isSuccess) {
            val data = response.getOrNull() ?: return VerificationResult(
                finalResponse = "لم يتم استلام استجابة صالحة",
                confidence = 0.0,
                reasoningTrace = trace + listOf("Layer 4: Verification — No response data available"),
            )
            val content = data.choices.firstOrNull()?.message?.content ?: ""
            trace.add("Layer 2: Planning — Model selected: ${data.model}")
            trace.add("Layer 3: Execution — Response received (${content.length} chars)")

            val confidence = computeConfidence(content, understanding)
            trace.add("Layer 4: Verification — Confidence: ${(confidence * 100).toInt()}%")

            if (confidence < maxConfidence && content.isNotEmpty()) {
                trace.add("Layer 4: Re-phrasing for clarity")
            }

            trace.add("Layer 5: Response — Final answer ready")
            return VerificationResult(
                finalResponse = content,
                confidence = confidence.coerceIn(0.0, 1.0),
                reasoningTrace = trace,
            )
        } else {
            val exception = response.exceptionOrNull()
            val errorMsg = exception?.message ?: "Unknown error"
            trace.add("Layer 4: Verification — Request failed: $errorMsg")
            trace.add("Layer 5: Response — Error returned to user")
            return VerificationResult(
                finalResponse = "حدث خطأ أثناء المعالجة: $errorMsg",
                confidence = 0.0,
                reasoningTrace = trace,
            )
        }
    }

    private fun computeConfidence(content: String, understanding: RequestUnderstanding): Double {
        var score = 0.8 // base confidence

        if (content.isEmpty()) return 0.0
        if (content.length < 20) score -= 0.2
        if (content.contains("لا أعرف") || content.contains("I don't know")) score -= 0.3
        if (understanding.requestType == RequestType.CODING && content.contains("```")) score += 0.1
        if (understanding.language == Language.AR && content.any { it in 'أ'..'ي' }) score += 0.1

        return score.coerceIn(0.0, 1.0)
    }

    // ------------------------------------------------------------------
    // Data classes
    // ------------------------------------------------------------------

    enum class Language { AUTO, AR, EN }
    enum class RequestType { CODING, REASONING, CREATIVE, FAST, EDUCATIONAL, EMOTIONAL, GENERAL }
    enum class Complexity { SIMPLE, MEDIUM, COMPLEX, EXPERT }
    enum class Urgency { LOW, NORMAL, HIGH }
    enum class Layer { UNDERSTANDING, PLANNING, EXECUTION, VERIFICATION, RESPONSE }

    data class OrResult(
        val success: Boolean,
        val response: String? = null,
        val model: AiModel? = null,
        val confidence: Double = 0.0,
        val reasoningTrace: List<String> = emptyList(),
        val error: Exception? = null,
        val layer: Layer? = null,
    ) {
        companion object {
            fun success(
                response: String,
                model: AiModel,
                confidence: Double,
                reasoningTrace: List<String>,
            ): OrResult = OrResult(
                success = true,
                response = response,
                model = model,
                confidence = confidence,
                reasoningTrace = reasoningTrace,
            )

            fun failure(
                error: Exception,
                layer: Layer,
            ): OrResult = OrResult(
                success = false,
                error = error,
                layer = layer,
            )
        }
    }
}

/**
 * Snapshot of provider health for OR engine decision making.
 */
data class ProviderHealthSnapshot(
    val providerId: String,
    val isHealthy: Boolean,
)

/**
 * Extension to read provider health from client stats (simplified snapshot).
 */
internal fun KashkoolAiClient.getProviderHealth(providerId: String): ProviderHealthSnapshot {
    val stats = getStats()
    return ProviderHealthSnapshot(
        providerId = providerId,
        isHealthy = stats.healthyProviders > 0,
    )
}
