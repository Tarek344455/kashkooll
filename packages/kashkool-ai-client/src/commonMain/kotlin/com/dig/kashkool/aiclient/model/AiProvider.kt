package com.dig.kashkool.aiclient.model

import kotlinx.serialization.Serializable
import com.dig.kashkool.aiclient.nowMillis

/**
 * Represents an AI provider (upstream service) in the Kashkool AI Client.
 * Contains configuration for connecting to the provider's API.
 */
@Serializable
data class AiProvider(
    /** Unique provider identifier */
    val id: String,
    /** Human-readable display name */
    val name: String,
    /** Base URL for the provider's OpenAI-compatible API */
    val baseUrl: String,
    /** API key for authentication (empty for keyless providers) */
    val apiKey: String = "",
    /** Whether this provider requires an API key to function */
    val requiresApiKey: Boolean = false,
    /** Maximum concurrent requests allowed */
    val maxConcurrent: Int = 1,
    /** Minimum interval between requests in milliseconds */
    val minIntervalMs: Long = 100,
    /** Cooldown period after errors in milliseconds */
    val cooldownMs: Long = 5000,
    /** Cooldown period after auth errors in milliseconds */
    val authCooldownMs: Long = 3600000,
    /** Rate limit scope: provider-wide or per-model */
    val rateLimitScope: RateLimitScope = RateLimitScope.PROVIDER,
    /** Whether this provider is enabled */
    val enabled: Boolean = true,
    /** Provider type for request formatting */
    val type: ProviderType = ProviderType.OPENAI_COMPATIBLE,
    /** Additional headers to include in requests */
    val extraHeaders: Map<String, String> = emptyMap(),
    /** Request timeout in milliseconds */
    val requestTimeoutMs: Long = 300000,
    /** Maximum request body size in bytes */
    val maxBodyBytes: Long = 67108864,
    /** Provider description/notes */
    val note: String = "",
) {
    /** Creates a copy with updated enabled status */
    fun withEnabled(enabled: Boolean): AiProvider = copy(enabled = enabled)

    /** Creates a copy with updated API key */
    fun withApiKey(newApiKey: String): AiProvider = copy(apiKey = newApiKey)
}

/**
 * Rate limit scope enumeration
 */
enum class RateLimitScope {
    PROVIDER,
    MODEL
}

/**
 * Provider type enumeration for request formatting
 */
enum class ProviderType {
    OPENAI_COMPATIBLE,
    ANTHROPIC,
    GOOGLE,
    CUSTOM
}

/**
 * Provider health status with a 3-failure circuit breaker.
 */
@Serializable
data class ProviderHealth(
    val providerId: String,
    val isHealthy: Boolean = true,
    val lastCheck: Long = nowMillis(),
    val consecutiveFailures: Int = 0,
    val lastError: String? = null,
    val averageLatencyMs: Double = 0.0,
) {
    fun withFailure(error: String): ProviderHealth = copy(
        isHealthy = false,
        consecutiveFailures = consecutiveFailures + 1,
        lastError = error,
        lastCheck = nowMillis(),
    )

    fun withSuccess(latencyMs: Double): ProviderHealth = copy(
        isHealthy = true,
        consecutiveFailures = 0,
        lastError = null,
        lastCheck = nowMillis(),
        averageLatencyMs = (averageLatencyMs * 0.7) + (latencyMs * 0.3),
    )

    /** Circuit breaker: opens after 3 consecutive failures */
    val isCircuitOpen: Boolean
        get() = consecutiveFailures >= 3
}
