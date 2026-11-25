package com.dig.kashkool.aiclient

import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.js.Js

/**
 * WebAssembly/JS engine backed by the browser fetch API.
 */
internal actual fun platformHttpClientEngine(): HttpClientEngine = Js.create()
