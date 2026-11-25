package com.dig.kashkool.aiclient.model

import kotlinx.serialization.Serializable

/**
 * Represents an AI model available in the Kashkool AI Client.
 * Contains all metadata needed for routing, quality assessment, and capability detection.
 */
@Serializable
data class AiModel(
    /** Unique identifier for this model within the client */
    val id: String,
    /** Human-readable display name */
    val name: String,
    /** The upstream model identifier as known by the provider */
    val upstreamModel: String,
    /** Provider ID this model belongs to */
    val providerId: String,
    /** Quality score (0.0 - 1.0), higher = better quality */
    val quality: Double,
    /** Maximum context window in tokens */
    val contextWindow: Int,
    /** Whether this model supports tool/function calling */
    val supportsTools: Boolean,
    /** Minimum output tokens this model typically produces */
    val minOutputTokens: Int,
    /** Model description for user-facing display */
    val description: String = "",
    /** Whether this model is currently available/healthy */
    val isAvailable: Boolean = true,
    /** Tags for categorization (e.g., "reasoning", "vision", "coding", "fast") */
    val tags: List<String> = emptyList(),
    /** Estimated cost per 1K tokens (0 for free models) */
    val costPer1kTokens: Double = 0.0,
    /** Maximum output tokens supported */
    val maxOutputTokens: Int = 4096,
) {
    /** Returns a copy with updated availability status */
    fun withAvailability(available: Boolean): AiModel = copy(isAvailable = available)

    /** Returns a copy with updated quality score */
    fun withQuality(newQuality: Double): AiModel = copy(quality = newQuality.coerceIn(0.0, 1.0))

    /** Checks if model can handle a request of given token count */
    fun canHandle(inputTokens: Int, estimatedOutputTokens: Int = 512): Boolean {
        return (inputTokens + estimatedOutputTokens) <= contextWindow
    }

    /** Gets the effective quality considering availability */
    val effectiveQuality: Double
        get() = if (isAvailable) quality else 0.0
}

/**
 * Predefined model tags for categorization
 */
object ModelTags {
    const val REASONING = "reasoning"
    const val VISION = "vision"
    const val CODING = "coding"
    const val FAST = "fast"
    const val CREATIVE = "creative"
    const val ANALYTICAL = "analytical"
    const val MULTILINGUAL = "multilingual"
    const val LONG_CONTEXT = "long-context"
    const val FREE = "free"
    const val KEYLESS = "keyless"
}