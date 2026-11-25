package com.dig.kashkool.aiclient

import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.apache.Apache

/**
 * JVM desktop engine backed by Apache HttpClient.
 */
internal actual fun platformHttpClientEngine(): HttpClientEngine = Apache.create()
