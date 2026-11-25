package com.dig.kashkool.aiclient

import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.okhttp.OkHttp

/**
 * Android engine backed by OkHttp (battle-tested, HTTP/2, connection pooling).
 */
internal actual fun platformHttpClientEngine(): HttpClientEngine = OkHttp.create()
