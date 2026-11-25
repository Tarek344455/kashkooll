package com.dig.kashkool.aiclient

import com.dig.kashkool.aiclient.model.ChatCompletionRequest
import com.dig.kashkool.aiclient.model.ChatCompletionResponse
import com.dig.kashkool.aiclient.model.ChatMessage
import com.dig.kashkool.aiclient.model.ModelTags
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class KashkoolAiClientTest {

    private lateinit var client: KashkoolAiClient

    /** Shared encoders/decoders: one instance per usage is needlessly slow. */
    private val encodeJson = Json { encodeDefaults = true }
    private val decodeJson = Json { ignoreUnknownKeys = true }

    private fun newClient(): KashkoolAiClient = KashkoolAiClient().also { client = it }

    @Test
    fun `client registers all built-in models`() {
        val client = newClient()
        assertEquals(11, client.getAllModels().size) // 5 Kilo + 1 llm7 + 1 Pollinations + 3 new + 1 local
    }

    @Test
    fun `seven keyless models are available by default`() {
        val client = newClient()
        assertEquals(7, client.availableModels.value.size) // local Gemma + 3 key-required providers disabled by default
        assertTrue(client.availableModels.value.none { it.providerId == "local-gemma" })
        assertTrue(client.availableModels.value.none { it.providerId == "openrouter" })
        assertTrue(client.availableModels.value.none { it.providerId == "nvidia" })
        assertTrue(client.availableModels.value.none { it.providerId == "opencode" })
    }

    @Test
    fun `models carry correct metadata`() {
        val client = newClient()
        val models = client.getAllModels()

        val ultra = models.find { it.id == "kilo-nemotron-3-ultra" }
        assertNotNull(ultra)
        assertEquals("kilo", ultra.providerId)
        assertEquals(0.88, ultra.quality)
        assertTrue(ultra.supportsTools)
        assertTrue(ModelTags.REASONING in ultra.tags)
        assertTrue(ModelTags.FREE in ultra.tags)
        assertTrue(ModelTags.KEYLESS in ultra.tags)

        val codestral = models.find { it.id == "llm7-codestral" }
        assertNotNull(codestral)
        assertEquals("llm7", codestral.providerId)
        assertEquals(0.70, codestral.quality)
        assertFalse(codestral.supportsTools)
        assertTrue(ModelTags.CODING in codestral.tags)

        val pollinations = models.find { it.id == "pollinations-openai" }
        assertNotNull(pollinations)
        assertEquals("pollinations", pollinations.providerId)
        assertEquals(0.40, pollinations.quality)

        val local = models.find { it.id == "local-gemma-4-e2b" }
        assertNotNull(local)
        assertEquals("local-gemma", local.providerId)
        assertEquals(0.95, local.quality)
    }

    @Test
    fun `stats reflect the default catalog`() {
        val client = newClient()
        val stats = client.getStats()
        assertEquals(11, stats.totalModels) // 5 Kilo + 1 llm7 + 1 Pollinations + 3 key-required + 1 local
        assertEquals(7, stats.availableModels) // only keyless ones available without API keys
        assertEquals(3, stats.enabledProviders) // kilo, llm7, pollinations (key-required ones disabled without keys)
        assertNotNull(stats.currentModel)
    }

    @Test
    fun `tag filtering works`() {
        val client = newClient()

        assertTrue(client.getModelsByTag(ModelTags.REASONING).size >= 3)
        assertTrue(client.getModelsByTag(ModelTags.CODING).size >= 3)
        assertEquals(7, client.getModelsByTag(ModelTags.FREE).size)
        assertEquals(7, client.getModelsByTag(ModelTags.KEYLESS).size)
    }

    @Test
    fun `provider enable and disable reshapes availability`() = runTest {
        val client = newClient()

        client.setProviderEnabled("kilo", false)
        assertTrue(client.availableModels.value.none { it.providerId == "kilo" })

        client.setProviderEnabled("kilo", true)
        assertTrue(client.availableModels.value.any { it.providerId == "kilo" })
    }

    @Test
    fun `default system prompt is Egyptian Arabic and educational`() {
        val prompt = newClient().defaultSystemPrompt()
        assertTrue(prompt.contains("مصري"))
        assertTrue(prompt.contains("تعليمي"))
        assertTrue(prompt.contains("ودود"))
        assertTrue(prompt.contains("ذكي اجتماعياً"))
        assertTrue(prompt.contains("ذكي عاطفياً"))
    }

    @Test
    fun `chat request serializes with OpenAI wire names only`() {
        val request = ChatCompletionRequest(
            model = "test/model",
            messages = listOf(ChatMessage.system("s"), ChatMessage.user("u")),
            temperature = 0.2,
            maxTokens = 128,
        )
        val json = encodeJson.encodeToString(request)

        assertTrue("\"max_tokens\":128" in json)
        assertTrue("\"role\":\"system\"" in json)
        assertTrue("\"role\":\"user\"" in json)
        // OpenAI-only switches must never be emitted to keyless upstreams.
        // The colon keeps the check on the field itself, not the "user" role value.
        assertFalse("\"tool_choice\":" in json)
        assertFalse("\"metadata\":" in json)
        assertFalse("\"user\":" in json)
    }

    @Test
    fun `openai response payload parses into models`() {
        val payload = """
            {
              "id": "chatcmpl-1",
              "object": "chat.completion",
              "created": 1700000000,
              "model": "nvidia/nemotron-3-ultra-550b-a55b:free",
              "choices": [
                {
                  "index": 0,
                  "message": { "role": "assistant", "content": "أهلاً بيك! إزيك؟" },
                  "finish_reason": "stop"
                }
              ],
              "usage": { "prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15 }
            }
        """.trimIndent()

        val parsed = decodeJson.decodeFromString<ChatCompletionResponse>(payload)

        assertEquals("chatcmpl-1", parsed.id)
        assertEquals("chat.completion", parsed.objectType)
        assertEquals("أهلاً بيك! إزيك؟", parsed.choices.first().message.content)
        assertEquals(15, parsed.usage?.totalTokens)
    }
}
