package com.dig.kashkool.aiclient

import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.winhttp.WinHttp

/**
 * Windows native engine backed by WinHTTP.
 */
internal actual fun platformHttpClientEngine(): HttpClientEngine = WinHttp.create()
