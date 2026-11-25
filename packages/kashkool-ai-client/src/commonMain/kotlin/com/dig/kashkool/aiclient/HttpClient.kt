package com.dig.kashkool.aiclient

import com.dig.kashkool.aiclient.model.AiProvider
import com.dig.kashkool.aiclient.model.ChatCompletionChunk
import com.dig.kashkool.aiclient.model.ChatCompletionRequest
import com.dig.kashkool.aiclient.model.ChatCompletionResponse
import com.dig.kashkool.aiclient.model.Choice
import com.dig.kashkool.aiclient.model.ChatMessage
import io.ktor.client.HttpClient as KtorHttpClient
import io.ktor.client.request.header
import io.ktor.client.request.post
import io.ktor.client.request.setBody
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsChannel
import io.ktor.client.statement.bodyAsText
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.contentType
import io.ktor.http.isSuccess
import io.ktor.utils.io.readUTF8Line
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Multiplatform HTTP transport for OpenAI-compatible chat completion APIs.
 *
 * A single Ktor code path serves every target; only the engine is platform
 * specific (OkHttp on Android, Darwin on Apple, Curl/WinHttp on desktop
 * native, Apache on JVM desktop, Js on WebAssembly).
 */
class HttpClient internal constructor(
    private val client: KtorHttpClient,
    private val json: Json,
    private val config: ClientConfig,
) {
    constructor(config: ClientConfig = ClientConfig()) : this(
        client = KtorHttpClient(platformHttpClientEngine()) {
            expectSuccess = false
            install(io.ktor.client.plugins.HttpTimeout) {
                requestTimeoutMillis = config.defaultRequestTimeoutMs
                connectTimeoutMillis = config.defaultConnectTimeoutMs
                socketTimeoutMillis = config.defaultSocketTimeoutMs
            }
        },
        json = Json {
            ignoreUnknownKeys = true
            isLenient = true
            explicitNulls = false
            encodeDefaults = true
        },
        config = config,
    )

    /**
     * Non-streaming chat completion.
     */
    suspend fun chat(
        provider: AiProvider,
        request: ChatCompletionRequest,
    ): ChatCompletionResponse {
        val response = post(provider, request)
        val body = response.bodyAsText()
        if (!response.status.isSuccess()) {
            throw HttpException(response.status.value, body)
        }
        return json.decodeFromString<ChatCompletionResponse>(body)
    }

    /**
     * Streaming chat completion. Each content delta is forwarded to [onChunk]
     * and the accumulated answer is returned as a regular response.
     */
    suspend fun streamChat(
        provider: AiProvider,
        request: ChatCompletionRequest,
        onChunk: (String) -> Unit,
    ): ChatCompletionResponse {
        val response = post(provider, request.copy(stream = true))
        if (!response.status.isSuccess()) {
            throw HttpException(response.status.value, response.bodyAsText())
        }

        val channel = response.bodyAsChannel()
        val full = StringBuilder()

        while (true) {
            val line = channel.readUTF8Line() ?: break
            if (!line.startsWith("data:")) continue
            val data = line.removePrefix("data:").trim()
            if (data.isEmpty()) continue
            if (data == "[DONE]") break

            val chunk = runCatching {
                json.decodeFromString<ChatCompletionChunk>(data)
            }.getOrNull() ?: continue

            val content = chunk.choices.firstOrNull()?.delta?.content ?: continue
            if (content.isNotEmpty()) {
                full.append(content)
                onChunk(content)
            }
        }

        return ChatCompletionResponse(
            id = "stream-" + nowMillis(),
            model = request.model,
            choices = listOf(
                Choice(
                    index = 0,
                    message = ChatMessage.assistant(full.toString()),
                    finishReason = "stop",
                ),
            ),
        )
    }

    private suspend fun post(
        provider: AiProvider,
        request: ChatCompletionRequest,
    ): HttpResponse {
        val body = json.encodeToString(request)
        return client.post(provider.chatCompletionsUrl()) {
            contentType(ContentType.Application.Json)
            header(HttpHeaders.Accept, if (request.stream) "text/event-stream" else "application/json")
            header(HttpHeaders.UserAgent, config.userAgent)
            if (provider.apiKey.isNotBlank()) {
                header(HttpHeaders.Authorization, "Bearer ${provider.apiKey}")
            }
            provider.extraHeaders.forEach { (key, value) -> header(key, value) }
            setBody(body)
        }
    }

    /** Closes the underlying HTTP client and releases resources. */
    fun close() {
        client.close()
    }
}

/**
 * Raised when an upstream returns a non-2xx status.
 */
class HttpException(
    val statusCode: Int,
    message: String,
) : Exception("HTTP $statusCode: $message")

/**
 * Normalizes the provider base URL and appends the completions path once.
 */
internal fun AiProvider.chatCompletionsUrl(): String =
    baseUrl.trimEnd('/') + "/chat/completions"
