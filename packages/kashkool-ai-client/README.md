# Kashkool AI Client

**Client-side AI package** bundling all free/keyless models with embedded API keys. Runs entirely on the user's device - no server required.

## Features

- 🎯 **7 Live-Verified Models** across 3 sustainable keyless providers
- 🚀 **Strongest-First Routing** with automatic failover
- ⚡ **Provider-Aware Rate Limiting** & Circuit Breakers
- 🔧 **Tool Calling Support** where available
- 🌊 **Streaming Responses**
- 📱 **Kotlin Multiplatform** - Android, iOS, Desktop, Web
- 🇪🇬 **Egyptian Arabic** - Educational, friendly, socially & emotionally intelligent
- 🔒 **Privacy First** - No data leaves the device except to model APIs
- 💰 **Completely Free** - All models use free tiers, no paid APIs

## Providers & Models

| Provider | Models | Type | Rate Limit | Quality |
|----------|--------|------|------------|---------|
| **Kilo** | 5 models | Keyless | Model-scoped (150ms) | 0.75-0.88 |
| **llm7** | 1 model (Codestral) | Keyless | Provider-scoped (1.2s) | 0.70 |
| **Pollinations** | 1 model | Keyless | 45s per IP | 0.40 |
| **Local Gemma** | 1 model | Local server | None | 0.95 |

### Kilo Models (5)
1. **Nemotron 3 Ultra** (0.88) - Flagship reasoning, best quality
2. **Nemotron 3.5 Super VL** (0.82) - Vision-language model
3. **Nemotron 3 Nano Reasoning** (0.80) - Fast reasoning
4. **Nemotron 3.5 Lightning** (0.78) - Optimized for speed
5. **Flint 1.0** (0.75) - General purpose workhorse

### llm7 Models (1)
- **Codestral Latest** (0.70) - Specialized coding model

### Pollinations (1)
- **Pollinations OpenAI** (0.40) - Last resort fallback

### Local (1) - Requires local server
- **Gemma 4 E2B** (0.95) - Highest quality, zero latency, full privacy

## Installation

### Gradle (Kotlin DSL)

```kotlin
// In settings.gradle.kts
include(":kashkool-ai-client")

// In your module's build.gradle.kts
dependencies {
    implementation(project(":kashkool-ai-client"))
}
```

### Version Catalog (libs.versions.toml)

The module uses the project's version catalog. Required entries:
```toml
[versions]
kotlin = "2.2.10"
ktor = "3.0.3"
okio = "3.9.0"
kotlinxCoroutines = "1.8.1"
kotlinxDatetime = "0.6.1"
okhttpSse = "4.12.0"

[libraries]
ktor-client-core = { group = "io.ktor", name = "ktor-client-core", version.ref = "ktor" }
ktor-client-content-negotiation = { group = "io.ktor", name = "ktor-client-content-negotiation", version.ref = "ktor" }
ktor-serialization-kotlinx-json = { group = "io.ktor", name = "ktor-serialization-kotlinx-json", version.ref = "ktor" }
ktor-client-darwin = { group = "io.ktor", name = "ktor-client-darwin", version.ref = "ktor" }
ktor-client-apache = { group = "io.ktor", name = "ktor-client-apache", version.ref = "ktor" }
ktor-client-js = { group = "io.ktor", name = "ktor-client-js", version.ref = "ktor" }
okio = { group = "com.squareup.okio", name = "okio", version.ref = "okio" }
okhttp-sse = { group = "com.squareup.okhttp3", name = "okhttp-sse", version.ref = "okhttpSse" }
kotlinx-coroutines-core = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-core", version.ref = "kotlinxCoroutines" }
kotlinx-datetime = { group = "org.jetbrains.kotlinx", name = "kotlinx-datetime", version.ref = "kotlinxDatetime" }

[plugins]
kotlin-multiplatform = { id = "org.jetbrains.kotlin.multiplatform", version.ref = "kotlin" }
compress = { id = "org.jetbrains.kotlin.plugin.compress", version.ref = "kotlin" }
```

## Usage

### Basic Chat

```kotlin
import com.dig.kashkool.aiclient.KashkoolAiClient
import com.dig.kashkool.aiclient.model.ChatMessage
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val client = KashkoolAiClient.getInstance()
    
    val result = client.chat("مرحباً، كيف يمكنني مساعدتك اليوم؟")
    
    result.onSuccess { response ->
        val message = response.choices.first().message.content.text
        println("AI: $message")
    }.onFailure { error ->
        println("Error: ${error.message}")
    }
}
```

### Streaming Chat

```kotlin
import com.dig.kashkool.aiclient.KashkoolAiClient
import kotlinx.coroutines.runBlocking

fun main() = runBlocking {
    val client = KashkoolAiClient.getInstance()
    
    print("AI: ")
    val result = client.chat(
        message = "اكتب لي قصيدة قصيرة عن مصر",
        onChunk = { chunk ->
            print(chunk) // Print each token as it arrives
        }
    )
    
    println() // New line after streaming
    
    result.onFailure { error ->
        println("\nError: ${error.message}")
    }
}
```

### With Custom Model

```kotlin
val result = client.chat(
    message = "اكتب كود Kotlin لـ RecyclerView",
    modelId = "llm7-codestral", // Force specific model
    temperature = 0.3, // Lower temperature for code
    maxTokens = 2048
)
```

### With Tools/Function Calling

```kotlin
import com.dig.kashkool.aiclient.model.Tool
import com.dig.kashkool.aiclient.model.FunctionDefinition

val tools = listOf(
    Tool(function = FunctionDefinition(
        name = "get_weather",
        description = "Get current weather for a city",
        parameters = mapOf(
            "type" to "object",
            "properties" to mapOf(
                "city" to mapOf("type" to "string", "description" to "City name")
            ),
            "required" to listOf("city")
        )
    ))
)

val result = client.chat(
    message = "كيف الطقس في القاهرة اليوم؟",
    tools = tools,
    modelId = "kilo-nemotron-3-ultra" // Best model for tool calling
)
```

### Get Available Models

```kotlin
val client = KashkoolAiClient.getInstance()

// All models
val allModels = client.getAllModels()

// Only available (healthy) models
val availableModels = client.availableModels.first()

// Filter by capability
val codingModels = client.getModelsByTag("coding")
val reasoningModels = client.getModelsByTag("reasoning")
val freeModels = client.getModelsByTag("free")

// By provider
val kiloModels = client.getModelsByProvider("kilo")
```

### Enable Local Gemma (Highest Quality)

```kotlin
val client = KashkoolAiClient.getInstance()

// Enable local provider (requires litertlm server on localhost:8080)
client.setProviderEnabled("local-gemma", true)

// Now Gemma 4 E2B (quality 0.95) will be preferred
val result = client.chat("مهمة معقدة تحتاج لأعلى جودة")
```

### Client Statistics

```kotlin
val stats = client.getStats()
println("""
    Total Models: ${stats.totalModels}
    Available: ${stats.availableModels}
    Enabled Providers: ${stats.enabledProviders}
    Healthy Providers: ${stats.healthyProviders}
    Current Model: ${stats.currentModel}
    Processing: ${stats.isProcessing}
""")
```

## Architecture

```
KashkoolAiClient (Common)
├── Model Definitions (AiModel, AiProvider, ChatModels)
├── Routing Logic (Strongest-first, Failover, Rate Limiting)
├── Health Monitoring (Circuit Breakers, Provider Health)
└── Platform Implementations (expect/actual)
    ├── Android/JVM → OkHttp + OkHttp-SSE
    ├── iOS/macOS → Ktor Darwin
    ├── Desktop (Linux/Windows) → Ktor Apache
    └── Web/WASM → Browser Fetch API
```

## Egyptian Arabic Personality

The default system prompt makes the AI:
- **Educational** - Explains concepts simply, encourages learning
- **Friendly** - Natural Egyptian Arabic ("انت", "احنا", "خلينا")
- **Socially Intelligent** - Understands context, respects values
- **Emotionally Intelligent** - Empathizes, supports, celebrates
- **Practically Helpful** - Real solutions, Egyptian context examples

## Requirements

- Kotlin 2.2.10+
- Gradle 9.6+
- Android minSdk 24+ (for Android target)
- iOS 14+ (for iOS target)
- JDK 17+ (for desktop targets)

## Building

```bash
# Build all targets
./gradlew :kashkool-ai-client:build

# Build specific target
./gradlew :kashkool-ai-client:compileKotlinAndroid
./gradlew :kashkool-ai-client:compileKotlinIosArm64
./gradlew :kashkool-ai-client:compileKotlinLinuxX64
./gradlew :kashkool-ai-client:compileKotlinMingwX64
./gradlew :kashkool-ai-client:compileKotlinWasmJs

# Run tests
./gradlew :kashkool-ai-client:test
```

## Adding Custom Providers

```kotlin
val client = KashkoolAiClient.getInstance()

// Add a provider with your own API key
client.setProviderApiKey("custom-provider", "your-api-key-here")

// Or enable/disable built-in providers
client.setProviderEnabled("pollinations", false) // Disable slowest provider
```

## License

Part of Kashkool project - Educational EdTech OS for Egypt.

## Contributing

This is a client-side package. All models use free/keyless tiers. 
To add new models: update `initializeBuiltInModels()` in `KashkoolAiClient.kt`.