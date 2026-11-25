package com.dig.kashkool.aiclient

import io.ktor.client.engine.HttpClientEngine
import kotlinx.datetime.Clock

/**
 * Current wall-clock time in epoch milliseconds, multiplatform-safe.
 */
internal fun nowMillis(): Long = Clock.System.now().toEpochMilliseconds()

/**
 * Creates the Ktor engine used by [HttpClient] on the current platform.
 */
internal expect fun platformHttpClientEngine(): HttpClientEngine

/**
 * Reads an environment variable (e.g. API keys from .env).
 * Returns null if not available on this platform.
 */
internal expect fun getEnv(key: String): String?
