package com.dig.kashkool.aiclient

import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.curl.Curl

/**
 * Linux native engine backed by libcurl.
 */
internal actual fun platformHttpClientEngine(): HttpClientEngine = Curl.create()
