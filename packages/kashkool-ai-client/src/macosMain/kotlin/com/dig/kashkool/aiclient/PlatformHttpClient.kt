package com.dig.kashkool.aiclient

import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.darwin.Darwin

/**
 * macOS engine backed by NSURLSession (Darwin).
 */
internal actual fun platformHttpClientEngine(): HttpClientEngine = Darwin.create()
