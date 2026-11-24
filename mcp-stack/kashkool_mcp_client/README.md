# 🧠 Kashkool Cognitive MCP Architecture

> **Not a wrapper. A genuine cognitive architecture with reasoning, memory, creativity, and verification.**

## Overview

The Kashkool Cognitive MCP Architecture is a **complete cognitive system** that integrates 14 MCP servers with advanced AI capabilities:

- **🧠 Reasoning Engine** — Chain-of-Thought, Tree-of-Thoughts, Self-Consistency, ReAct, First Principles, Analogical
- **🏛️ Memory Palace** — Three-tier memory (Semantic, Episodic, Procedural) with associative recall
- **🎨 Creative Synthesis** — Concept blending, analogical transfer, divergent generation
- **✅ Verification Core** — Multi-level verification, hallucination detection, confidence calibration
- **🎯 Adaptive Router** — Learns optimal server-tool mappings via multi-armed bandit
- **⚙️ Tool Orchestrator** — Dynamic pipeline composition with parallel execution, fallbacks, retries
- **💾 Persistence Layer** — JSON, SQLite, Redis backends with auto-save
- **🌐 API Server** — FastAPI REST + WebSocket + SSE for real-time cognitive operations

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        COGNITIVE LAYER                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │  REASONING   │  │   MEMORY     │  │  CREATIVE    │  │ VERIFICATION │   │
│  │   ENGINE     │  │   PALACE     │  │  SYNTHESIS   │  │    CORE      │   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │
│         │                 │                 │                 │            │
│         └─────────────────┼─────────────────┼─────────────────┘            │
│                           ▼                 ▼                              │
│                  ┌─────────────────────────────────────┐                   │
│                  │      ADAPTIVE ROUTER + ORCHESTRATOR │                   │
│                  └─────────────────┬──────────────────┘                   │
└─────────────────────────────────────┼─────────────────────────────────────┘
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        EXECUTION LAYER                                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐        │
│  │Firecrawl │ │ Zenrows  │ │ Playwright│ │  Jina    │ │  Apify   │  ...  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘        │
│  14 MCP Servers via stdio JSON-RPC                                        │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

### Installation

```bash
cd N:\spaceship-ai\projects\kashkool\mcp-stack\kashkool_mcp_client
pip install -r requirements.txt
```

### Basic Usage (Python)

```python
from kashkool_mcp_client import CognitiveMCPBridge

# Initialize with demo LLM (replace with real LLM)
def my_llm(prompt: str) -> str:
    # Your LLM call here
    return "LLM response..."

bridge = CognitiveMCPBridge(llm_call=my_llm)

# Start servers
bridge.start_all_servers()

# High-level cognitive operations
result = bridge.investigate("AI-powered web scraping", depth="standard")
print(result["reasoning_chain"]["conclusion"])

result = bridge.solve_problem("How to build a self-healing scraper?", method="first_principles")
print(result["conclusion"])

result = bridge.verify_claim("Firecrawl handles JavaScript sites well", level=VerificationLevel.DEEP)
print(f"Verified: {result.verified}, Confidence: {result.confidence}")

# Creative operations
blend = bridge.blend_concepts("web_scraping", "reasoning", "hybrid")
print(blend["result"]["name"])

ideas = bridge.creative.divergent_generation("web_scraping", num_ideas=5, llm_call=my_llm)
for idea in ideas:
    print(idea["name"])

# Cleanup
bridge.stop_all_servers()
```

### Convenience Functions

```python
from kashkool_mcp_client import investigate, solve, verify, search, scrape, think, pipeline, blend, status

# One-liners
result = investigate("quantum computing", depth="quick")
result = solve("How to optimize database queries?", method="analogical")
result = verify("Python is slower than C", level=VerificationLevel.CROSS_REFERENCE)
results = search("machine learning", limit=5)
result = scrape("https://example.com")
result = youtube_transcript("https://youtube.com/watch?v=...")
result = think("Design a cache invalidation strategy", steps=3)
result = blend("web_scraping", "reasoning", "hybrid")
result = pipeline("Research and summarize AI trends", max_steps=5)
sys_status = status()
```

## API Server

### Start the Server

```bash
# Development
uvicorn kashkool_mcp_client.api_server:app --reload --port 8000

# Production
uvicorn kashkool_mcp_client.api_server:app --host 0.0.0.0 --port 8000 --workers 4
```

### API Endpoints

| Category | Endpoints |
|----------|-----------|
| **Health** | `GET /health`, `GET /status`, `GET /servers` |
| **Memory** | `POST /memory/store`, `POST /memory/recall`, `GET /memory/stats`, `POST /memory/consolidate` |
| **Reasoning** | `POST /reason`, `GET /reason/chains`, `GET /reason/chains/{id}` |
| **Verification** | `POST /verify`, `GET /verify/calibration`, `POST /verify/calibrate`, `POST /verify/hallucination` |
| **Creative** | `POST /creative/blend`, `POST /creative/divergent`, `POST /creative/concepts`, `GET /creative/concepts` |
| **High-Level** | `POST /investigate`, `POST /solve`, `POST /pipeline/create`, `POST /pipeline/execute`, `POST /pipeline/dynamic` |
| **Tools** | `POST /tools/scrape`, `POST /tools/search`, `POST /tools/youtube`, `POST /tools/think`, `GET /tools/available` |
| **Router** | `GET /router/stats`, `GET /router/ranking/{tool}` |
| **Persistence** | `POST /persistence/save`, `POST /persistence/load`, `GET /persistence/stats` |
| **LLM** | `POST /llm/configure`, `GET /llm/current` |
| **Real-time** | `WS /ws`, `GET /events/stream` |
| **Batch** | `POST /batch/reason`, `POST /batch/verify` |
| **Export/Import** | `GET /export`, `POST /import` |

### Example API Calls

```bash
# Investigate a topic
curl -X POST http://localhost:8000/investigate \
  -H "Content-Type: application/json" \
  -d '{"topic": "self-healing web scrapers", "depth": "standard"}'

# Solve a problem
curl -X POST http://localhost:8000/solve \
  -H "Content-Type: application/json" \
  -d '{"problem": "How to extract structured data from any website?", "method": "first_principles"}'

# Verify a claim
curl -X POST http://localhost:8000/verify \
  -H "Content-Type: application/json" \
  -d '{"claim": "Firecrawl can scrape JavaScript sites", "level": "deep"}'

# Creative blend
curl -X POST http://localhost:8000/creative/blend \
  -H "Content-Type: application/json" \
  -d '{"concept_a": "web_scraping", "concept_b": "reasoning", "blend_type": "hybrid"}'

# WebSocket for streaming reasoning
ws://localhost:8000/ws
```

## Configuration

### Environment Variables

```bash
# LLM
KASHKOOL_LLM_PROVIDER=openai
KASHKOOL_LLM_MODEL=gpt-4
KASHKOOL_LLM_API_KEY=sk-...
KASHKOOL_LLM_TEMPERATURE=0.7

# Persistence
KASHKOOL_PERSISTENCE_BACKEND=sqlite
KASHKOOL_PERSISTENCE_PATH=./cognitive_data

# API
KASHKOOL_API_HOST=0.0.0.0
KASHKOOL_API_PORT=8000
KASHKOOL_ENVIRONMENT=production
KASHKOOL_DEBUG=false

# MCP Server API Keys
FIRECRAWL_API_KEY=fc-...
JINA_API_KEY=jina-...
APIFY_TOKEN=apify-...
STRING_API_KEY=string-...
```

### Config File (config.json)

```json
{
  "servers": [
    {"name": "firecrawl", "command": ["npx", "-y", "firecrawl-mcp"], "tools": ["scrape", "search"], "priority": 15}
  ],
  "llm": {"provider": "openai", "model": "gpt-4", "temperature": 0.7},
  "memory": {"capacity": 10000, "consolidation_threshold": 0.7},
  "reasoning": {"default_strategy": "chain_of_thought", "max_steps": 10},
  "verification": {"default_level": "cross_reference", "cache_size": 5000},
  "persistence": {"backend": "sqlite", "path": "./cognitive_data"},
  "api": {"host": "0.0.0.0", "port": 8000, "workers": 4}
}
```

Load config:
```python
from kashkool_mcp_client.config import load_config, create_config

config = load_config("config.json")
# or
config = create_config("production")
```

## MCP Servers (14 Total)

| Server | Package | Tools | Purpose |
|--------|---------|-------|---------|
| **Firecrawl** | `firecrawl-mcp` | scrape, search, crawl, map | JS-heavy sites, anti-bot |
| **Zenrows** | `@zenrows/mcp` | scrape, screenshot, extract | Anti-bot bypass, extraction |
| **Playwright** | `@playwright/mcp` | navigate, click, fill, screenshot, evaluate | Browser automation |
| **Jina Reader** | `jina-reader-mcp-server` | read, search | Clean content extraction |
| **Apify** | `@apify/actors-mcp-server` | run_actor, get_dataset | 3000+ pre-built actors |
| **YouTube** | `@fabriqa.ai/youtube-transcript-mcp` | get_transcript, search_videos | Video transcripts |
| **Sequential** | `@modelcontextprotocol/server-sequential-thinking` | think | Structured reasoning |
| **Fetch** | `mcp-fetch-server` | fetch | Simple HTTP fetch |
| **String** | `@usestring/mcp` | search, fetch | Web search + fetch |
| **Everything** | `@modelcontextprotocol/server-everything` | all | Reference implementation |
| **PDF** | `@modelcontextprotocol/server-pdf` | pdf | PDF processing |
| **Inspector** | `@modelcontextprotocol/inspector` | inspect | Debugging |

## Advanced Features

### Persistence

```python
from kashkool_mcp_client.persistence import create_persistence_manager, save_cognitive_state, load_cognitive_state

# Auto-save every 30 seconds
pm = create_persistence_manager("sqlite", "./cognitive_data")
pm.register_components(memory=bridge.memory, reasoning=bridge.reasoning, ...)
pm.start_auto_save()

# Manual save/load
save_cognitive_state(bridge, "sqlite", "./cognitive_data")
load_cognitive_state(bridge, "sqlite", "./cognitive_data")
```

### Advanced Verification

```python
from kashkool_mcp_client.advanced_verification import (
    AdvancedVerificationOrchestrator, VerificationStrategy, advanced_verify
)

orchestrator = AdvancedVerificationOrchestrator(llm_call, memory=bridge.memory)

result = await orchestrator.verify(
    claim="Human CO2 causes global warming",
    strategies=[
        VerificationStrategy.CONSENSUS,
        VerificationStrategy.LOGICAL_CONSISTENCY,
        VerificationStrategy.ADVERSARIAL,
        VerificationStrategy.CAUSAL
    ]
)

# Or quick one-liner
result = await advanced_verify(claim, llm_call, memory=bridge.memory)
```

### Dynamic Pipelines

```python
# Define manually
steps = [
    PipelineStep(id="search", tool="search_firecrawl", params={"query": "AI trends 2024"}, depends_on=[]),
    PipelineStep(id="scrape", tool="scrape_firecrawl", params={"url": "{{search.results[0].url}}"}, depends_on=["search"]),
    PipelineStep(id="verify", tool="call_tool", params={"server": "sequential", "tool": "think", "problem": "Verify accuracy"}, depends_on=["scrape"])
]
bridge.orchestrator.define_pipeline("research_pipeline", steps)
result = bridge.orchestrator.execute_pipeline("research_pipeline")

# Or let LLM create it
result = bridge.create_and_execute_pipeline("Research AI trends and verify key claims", max_steps=5)
```

## Project Structure

```
kashkool_mcp_client/
├── __init__.py              # Main exports
├── __main__.py              # Demo entry point
├── models.py                # Data models (ScrapeResult, SearchResult, etc.)
├── client.py                # Original MCP client (wrapper)
├── cognitive_core.py        # 🧠 Core cognitive architecture
├── integration.py           # 🔗 Bridge to MCP servers
├── persistence.py           # 💾 Persistence layer (JSON/SQLite/Redis)
├── api_server.py            # 🌐 FastAPI REST + WebSocket + SSE
├── config.py                # ⚙️ Configuration system
├── advanced_verification.py # ✅ Advanced verification strategies
├── requirements.txt         # Dependencies
└── README.md               # This file
```

## Running the Demo

```bash
cd N:\spaceship-ai\projects\kashkool\mcp-stack\kashkool_mcp_client
python -m kashkool_mcp_client
```

This runs a comprehensive demo showing all cognitive components in action with a simulated LLM.

## Extending the Architecture

### Custom Reasoning Strategy

```python
from kashkool_mcp_client.cognitive_core import ReasoningEngine, ReasoningContext, ReasoningStrategy, Thought, ThoughtType

class MyReasoningEngine(ReasoningEngine):
    def my_custom_strategy(self, context: ReasoningContext, llm_call: Callable) -> ThoughtChain:
        # Implement your strategy
        pass

# Register
ReasoningStrategy.MY_CUSTOM = "my_custom"
```

### Custom Verification Strategy

```python
from kashkool_mcp_client.advanced_verification import VerificationStrategy, EvidenceGatherer

class MyVerifier:
    async def verify(self, claim: str, context: VerificationContext) -> VerificationReport:
        # Implement verification
        pass

VerificationStrategy.MY_CUSTOM = "my_custom"
```

### Custom MCP Server

Add to config:
```python
ServerConfig(
    name="my_server",
    command=["npx", "-y", "my-mcp-server"],
    tools=["my_tool"],
    env={"MY_API_KEY": "${MY_API_KEY}"},
    priority=10
)
```

## Performance Tips

1. **Use SQLite/Redis persistence** for production (not JSON)
2. **Enable auto-save** with appropriate interval
3. **Configure router** with exploration factor for your workload
4. **Use connection pooling** for LLM providers
5. **Batch operations** when possible (`/batch/reason`, `/batch/verify`)
6. **Monitor calibration** to improve confidence accuracy

## Testing

```bash
# Run tests
pytest tests/ -v

# With coverage
pytest tests/ --cov=kashkool_mcp_client --cov-report=html
```

## License

Part of the Kashkool project. See main project license.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

---

**Built with 🧠 for the Kashkool project** — *Where cognitive architecture meets MCP*