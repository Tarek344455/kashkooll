package com.dig.kashkool.aiclient.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

/**
 * Chat message role, serialized with the OpenAI wire names.
 */
@Serializable
enum class MessageRole {
    @SerialName("system") SYSTEM,
    @SerialName("user") USER,
    @SerialName("assistant") ASSISTANT,
    @SerialName("tool") TOOL,
    @SerialName("function") FUNCTION,
}

/**
 * A single chat message in an OpenAI-compatible conversation.
 */
@Serializable
data class ChatMessage(
    val role: MessageRole,
    val content: String? = null,
    val name: String? = null,
    @SerialName("tool_calls") val toolCalls: List<ToolCall>? = null,
    @SerialName("tool_call_id") val toolCallId: String? = null,
) {
    companion object {
        fun system(text: String) = ChatMessage(MessageRole.SYSTEM, text)
        fun user(text: String) = ChatMessage(MessageRole.USER, text)
        fun assistant(text: String? = null) = ChatMessage(MessageRole.ASSISTANT, text)
        fun tool(result: String, toolCallId: String) =
            ChatMessage(MessageRole.TOOL, result, toolCallId = toolCallId)

        fun functionCall(name: String, arguments: String, id: String) = ChatMessage(
            role = MessageRole.ASSISTANT,
            content = null,
            toolCalls = listOf(ToolCall(id = id, function = FunctionCall(name, arguments))),
        )
    }
}

/**
 * Tool call emitted by the model.
 */
@Serializable
data class ToolCall(
    val id: String,
    val type: String = "function",
    val function: FunctionCall,
)

@Serializable
data class FunctionCall(
    val name: String,
    val arguments: String,
)

/**
 * Tool definition sent with a request (function calling).
 */
@Serializable
data class Tool(
    val type: String = "function",
    val function: FunctionDefinition,
)

@Serializable
data class FunctionDefinition(
    val name: String,
    val description: String,
    val parameters: JsonObject = JsonObject(emptyMap()),
)

/**
 * OpenAI-compatible chat completion request.
 *
 * Only fields that every keyless upstream accepts are emitted:
 * OpenAI-only switches such as `tool_choice`, `parallel_tool_calls`,
 * `metadata` or `user` are intentionally absent (router protocol rule #3).
 */
@Serializable
data class ChatCompletionRequest(
    val model: String,
    val messages: List<ChatMessage>,
    val temperature: Double? = 0.7,
    @SerialName("max_tokens") val maxTokens: Int? = null,
    val stream: Boolean = false,
    val tools: List<Tool>? = null,
)

/**
 * Chat completion response.
 */
@Serializable
data class ChatCompletionResponse(
    val id: String,
    @SerialName("object") val objectType: String = "chat.completion",
    val created: Long = 0L,
    val model: String,
    val choices: List<Choice> = emptyList(),
    val usage: Usage? = null,
)

@Serializable
data class Choice(
    val index: Int = 0,
    val message: ChatMessage,
    @SerialName("finish_reason") val finishReason: String? = null,
)

@Serializable
data class Usage(
    @SerialName("prompt_tokens") val promptTokens: Int = 0,
    @SerialName("completion_tokens") val completionTokens: Int = 0,
    @SerialName("total_tokens") val totalTokens: Int = 0,
)

/**
 * Streaming response chunk.
 */
@Serializable
data class ChatCompletionChunk(
    val id: String,
    @SerialName("object") val objectType: String = "chat.completion.chunk",
    val created: Long = 0L,
    val model: String,
    val choices: List<ChunkChoice> = emptyList(),
)

@Serializable
data class ChunkChoice(
    val index: Int = 0,
    val delta: DeltaMessage = DeltaMessage(),
    @SerialName("finish_reason") val finishReason: String? = null,
)

@Serializable
data class DeltaMessage(
    val role: MessageRole? = null,
    val content: String? = null,
)
