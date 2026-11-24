"""
API Server — FastAPI REST API for the Cognitive MCP Architecture.
Exposes all cognitive operations as HTTP endpoints with WebSocket support.
"""
import asyncio
import json
import os
import time
import uuid
from contextlib import asynccontextmanager
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, AsyncGenerator, Dict, List, Optional, Union

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect, BackgroundTasks, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from sse_starlette.sse import EventSourceResponse

# Import cognitive components
import sys
sys.path.insert(0, str(__file__).replace("api_server.py", ""))

from .cognitive_core import (
    MemoryPalace, MemoryType, MemoryNode,
    ReasoningEngine, ReasoningContext, ReasoningStrategy, Thought, ThoughtType, ThoughtChain, ThoughtTree,
    CreativeSynthesis,
    VerificationCore, VerificationLevel, VerificationResult,
    AdaptiveRouter, ServerPerformance,
    ToolOrchestrator, PipelineStep, PipelineResult
)
from .integration import CognitiveMCPBridge, MCPServerConfig, get_bridge
from .models import ScrapeResult, SearchResult, TranscriptResult, PDFResult, ThinkResult
from .persistence import PersistenceManager, PersistenceConfig, create_persistence_manager


# ==================== PYDANTIC MODELS ====================

class MemoryStoreRequest(BaseModel):
    content: Any
    mem_type: str = "semantic"
    tags: List[str] = []
    importance: float = 0.5
    source: str = "api"
    connections: Dict[str, float] = {}

class MemoryRecallRequest(BaseModel):
    query: Any = None
    mem_type: Optional[str] = None
    tags: List[str] = []
    top_k: int = 10
    min_importance: float = 0.0
    spreading_activation: bool = True

class ReasoningRequest(BaseModel):
    problem: str
    strategy: str = "chain_of_thought"
    max_steps: int = 10
    max_branches: int = 3
    temperature: float = 0.7
    require_verification: bool = True

class VerificationRequest(BaseModel):
    claim: str
    level: str = "cross_reference"
    context: Optional[str] = None

class CreativeBlendRequest(BaseModel):
    concept_a: str
    concept_b: str
    blend_type: str = "hybrid"

class CreativeDivergentRequest(BaseModel):
    seed_concept: str
    num_ideas: int = 10
    constraints: List[str] = []

class InvestigationRequest(BaseModel):
    topic: str
    depth: str = "standard"
    strategy: str = "chain_of_thought"

class ProblemSolveRequest(BaseModel):
    problem: str
    method: str = "auto"
    verify: bool = True

class PipelineRequest(BaseModel):
    goal: str
    max_steps: int = 10

class ScrapeRequest(BaseModel):
    url: str
    format: str = "markdown"
    extract_schema: Optional[Dict] = None

class SearchRequest(BaseModel):
    query: str
    limit: int = 10

class YouTubeRequest(BaseModel):
    video_url: str
    language: str = "en"

class ThinkRequest(BaseModel):
    problem: str
    steps: int = 5

class PipelineStepModel(BaseModel):
    id: str
    tool: str
    params: Dict[str, Any] = {}
    depends_on: List[str] = []
    condition: Optional[str] = None
    fallback: Optional[str] = None
    timeout: float = 30.0
    retries: int = 1

class PipelineDefineRequest(BaseModel):
    pipeline_id: str
    steps: List[PipelineStepModel]

class PipelineExecuteRequest(BaseModel):
    pipeline_id: str
    initial_params: Optional[Dict[str, Any]] = None

class ConceptRegisterRequest(BaseModel):
    name: str
    properties: Dict[str, Any]
    domain: str = ""

class ServerConfigModel(BaseModel):
    name: str
    command: List[str]
    tools: List[str]
    env: Dict[str, str] = {}
    timeout: int = 60

class LLMConfigRequest(BaseModel):
    provider: str  # openai, anthropic, ollama, custom
    model: str
    api_key: Optional[str] = None
    base_url: Optional[str] = None
    temperature: float = 0.7
    max_tokens: int = 4000


# ==================== GLOBAL STATE ====================

@dataclass
class ServerState:
    bridge: Optional[CognitiveMCPBridge] = None
    persistence: Optional[PersistenceManager] = None
    llm_function: Optional[callable] = None
    active_websockets: Dict[str, WebSocket] = field(default_factory=dict)
    background_tasks: List[asyncio.Task] = field(default_factory=list)
    startup_time: datetime = field(default_factory=datetime.now)
    request_count: int = 0
    error_count: int = 0


state = ServerState()


# ==================== LLM PROVIDERS ====================

class LLMProvider:
    """Base class for LLM providers."""

    async def __call__(self, prompt: str) -> str:
        raise NotImplementedError


class OpenAIProvider(LLMProvider):
    def __init__(self, api_key: str, model: str = "gpt-4", base_url: Optional[str] = None, temperature: float = 0.7, max_tokens: int = 4000):
        self.api_key = api_key
        self.model = model
        self.base_url = base_url
        self.temperature = temperature
        self.max_tokens = max_tokens
        self._client = None

    def _get_client(self):
        if self._client is None:
            from openai import AsyncOpenAI
            self._client = AsyncOpenAI(
                api_key=self.api_key,
                base_url=self.base_url
            )
        return self._client

    async def __call__(self, prompt: str) -> str:
        client = self._get_client()
        response = await client.chat.completions.create(
            model=self.model,
            messages=[{"role": "user", "content": prompt}],
            temperature=self.temperature,
            max_tokens=self.max_tokens
        )
        return response.choices[0].message.content


class AnthropicProvider(LLMProvider):
    def __init__(self, api_key: str, model: str = "claude-3-opus-20240229", temperature: float = 0.7, max_tokens: int = 4000):
        self.api_key = api_key
        self.model = model
        self.temperature = temperature
        self.max_tokens = max_tokens
        self._client = None

    def _get_client(self):
        if self._client is None:
            from anthropic import AsyncAnthropic
            self._client = AsyncAnthropic(api_key=self.api_key)
        return self._client

    async def __call__(self, prompt: str) -> str:
        client = self._get_client()
        response = await client.messages.create(
            model=self.model,
            max_tokens=self.max_tokens,
            temperature=self.temperature,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.content[0].text


class OllamaProvider(LLMProvider):
    def __init__(self, model: str = "llama3", base_url: str = "http://localhost:11434", temperature: float = 0.7):
        self.model = model
        self.base_url = base_url
        self.temperature = temperature
        self._session = None

    async def _get_session(self):
        if self._session is None:
            import aiohttp
            self._session = aiohttp.ClientSession()
        return self._session

    async def __call__(self, prompt: str) -> str:
        session = await self._get_session()
        async with session.post(
            f"{self.base_url}/api/generate",
            json={
                "model": self.model,
                "prompt": prompt,
                "temperature": self.temperature,
                "stream": False
            }
        ) as resp:
            data = await resp.json()
            return data.get("response", "")


class CustomProvider(LLMProvider):
    def __init__(self, func: callable):
        self.func = func

    async def __call__(self, prompt: str) -> str:
        if asyncio.iscoroutinefunction(self.func):
            return await self.func(prompt)
        else:
            return self.func(prompt)


def create_llm_provider(config: LLMConfigRequest) -> LLMProvider:
    """Factory for LLM providers."""
    providers = {
        "openai": OpenAIProvider,
        "anthropic": AnthropicProvider,
        "ollama": OllamaProvider,
        "custom": CustomProvider
    }

    provider_class = providers.get(config.provider.lower())
    if not provider_class:
        raise ValueError(f"Unknown provider: {config.provider}")

    if provider_class == CustomProvider:
        # For custom, we'd need a function reference - not serializable via API
        raise ValueError("Custom provider must be set programmatically")

    return provider_class(
        api_key=config.api_key,
        model=config.model,
        base_url=config.base_url,
        temperature=config.temperature,
        max_tokens=config.max_tokens
    )


# ==================== LIFESPAN ====================

@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    # Startup
    print("🚀 Starting Kashkool Cognitive MCP API Server...")

    # Initialize bridge with default demo LLM
    def demo_llm(prompt: str) -> str:
        return f"[Demo LLM] {prompt[:100]}..."

    state.bridge = CognitiveMCPBridge(llm_call=demo_llm)
    state.llm_function = demo_llm

    # Initialize persistence
    persist_path = os.getenv("KASHKOOL_PERSIST_PATH", "./cognitive_data")
    state.persistence = create_persistence_manager("sqlite", persist_path)
    state.persistence.register_components(
        memory=state.bridge.memory,
        reasoning=state.bridge.reasoning,
        creative=state.bridge.creative,
        verification=state.bridge.verification,
        router=state.bridge.router,
        orchestrator=state.bridge.orchestrator
    )

    # Load previous state
    load_results = state.persistence.load_all()
    print(f"📂 Loaded state: {load_results}")

    # Start auto-save
    state.persistence.start_auto_save()

    # Start servers
    server_status = state.bridge.start_all_servers()
    print(f"🔧 Servers: {server_status}")

    print("✅ Server ready!")

    yield

    # Shutdown
    print("🛑 Shutting down...")
    state.persistence.close()
    state.bridge.stop_all_servers()
    for task in state.background_tasks:
        task.cancel()
    print("✅ Shutdown complete")


# ==================== FASTAPI APP ====================

app = FastAPI(
    title="Kashkool Cognitive MCP API",
    description="REST API for the Cognitive MCP Architecture - Reasoning, Memory, Creativity, Verification",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==================== DEPENDENCIES ====================

def get_bridge() -> CognitiveMCPBridge:
    if state.bridge is None:
        raise HTTPException(status_code=503, detail="Bridge not initialized")
    return state.bridge


def get_persistence() -> PersistenceManager:
    if state.persistence is None:
        raise HTTPException(status_code=503, detail="Persistence not initialized")
    return state.persistence


def increment_request_count():
    state.request_count += 1


# ==================== HEALTH & STATUS ====================

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "uptime_seconds": (datetime.now() - state.startup_time).total_seconds(),
        "requests": state.request_count,
        "errors": state.error_count,
        "bridge_initialized": state.bridge is not None,
        "persistence_initialized": state.persistence is not None
    }


@app.get("/status")
async def get_status(bridge: CognitiveMCPBridge = Depends(get_bridge)):
    status = bridge.get_system_status()
    status["api"] = {
        "uptime_seconds": (datetime.now() - state.startup_time).total_seconds(),
        "requests": state.request_count,
        "errors": state.error_count,
        "active_websockets": len(state.active_websockets)
    }
    return status


@app.get("/servers")
async def list_servers(bridge: CognitiveMCPBridge = Depends(get_bridge)):
    return bridge.process_manager.get_stats()


# ==================== MEMORY ENDPOINTS ====================

@app.post("/memory/store")
async def store_memory(request: MemoryStoreRequest, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    try:
        mem_type = MemoryType(request.mem_type)
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid memory type: {request.mem_type}")

    node_id = bridge.memory.store(
        content=request.content,
        mem_type=mem_type,
        tags=set(request.tags),
        importance=request.importance,
        source=request.source,
        connections=request.connections
    )

    if state.persistence:
        state.persistence.mark_dirty("memory")

    return {"node_id": node_id, "status": "stored"}


@app.post("/memory/recall")
async def recall_memory(request: MemoryRecallRequest, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    mem_type = None
    if request.mem_type:
        try:
            mem_type = MemoryType(request.mem_type)
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid memory type: {request.mem_type}")

    results = bridge.memory.recall(
        query=request.query,
        mem_type=mem_type,
        tags=set(request.tags) if request.tags else None,
        top_k=request.top_k,
        min_importance=request.min_importance,
        spreading_activation=request.spreading_activation
    )

    return {
        "results": [
            {
                "id": r.id,
                "type": r.type.value,
                "content": r.content,
                "importance": r.importance,
                "tags": list(r.tags),
                "source": r.source,
                "verified": r.verified,
                "access_count": r.access_count,
                "created_at": r.created_at.isoformat(),
                "last_accessed": r.last_accessed.isoformat()
            }
            for r in results
        ],
        "count": len(results)
    }


@app.get("/memory/stats")
async def memory_stats(bridge: CognitiveMCPBridge = Depends(get_bridge)):
    return bridge.memory.get_stats()


@app.post("/memory/consolidate")
async def consolidate_memory(bridge: CognitiveMCPBridge = Depends(get_bridge)):
    bridge.memory.consolidate()
    if state.persistence:
        state.persistence.mark_dirty("memory")
    return {"status": "consolidated"}


# ==================== REASONING ENDPOINTS ====================

@app.post("/reason")
async def reason(request: ReasoningRequest, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    try:
        strategy = ReasoningStrategy(request.strategy)
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid strategy: {request.strategy}")

    context = ReasoningContext(
        problem=request.problem,
        strategy=strategy,
        max_steps=request.max_steps,
        max_branches=request.max_branches,
        temperature=request.temperature,
        require_verification=request.require_verification,
        memory=bridge.memory,
        tools=bridge.orchestrator.tool_executors
    )

    chain = bridge.reasoning.reason(context, bridge.llm_call)

    if state.persistence:
        state.persistence.mark_dirty("reasoning")

    return {
        "chain_id": chain.id,
        "goal": chain.goal,
        "steps": len(chain.thoughts),
        "conclusion": chain.conclusion.content if chain.conclusion else None,
        "confidence": chain.confidence,
        "verified": chain.verified,
        "verification_notes": chain.verification_notes,
        "thoughts": [
            {
                "id": t.id,
                "type": t.type.value,
                "content": t.content,
                "confidence": t.confidence,
                "metadata": t.metadata
            }
            for t in chain.thoughts
        ]
    }


@app.get("/reason/chains")
async def list_reasoning_chains(bridge: CognitiveMCPBridge = Depends(get_bridge)):
    return {
        "chains": [
            {
                "id": cid,
                "goal": chain.goal,
                "steps": len(chain.thoughts),
                "confidence": chain.confidence,
                "verified": chain.verified
            }
            for cid, chain in bridge.reasoning.thought_chains.items()
        ],
        "count": len(bridge.reasoning.thought_chains)
    }


@app.get("/reason/chains/{chain_id}")
async def get_reasoning_chain(chain_id: str, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    chain = bridge.reasoning.thought_chains.get(chain_id)
    if not chain:
        raise HTTPException(status_code=404, detail="Chain not found")

    return {
        "id": chain.id,
        "goal": chain.goal,
        "thoughts": [
            {
                "id": t.id,
                "type": t.type.value,
                "content": t.content,
                "confidence": t.confidence,
                "evidence": t.evidence,
                "contradicts": t.contradicts,
                "metadata": t.metadata,
                "timestamp": t.timestamp.isoformat(),
                "parent_id": t.parent_id,
                "children_ids": t.children_ids
            }
            for t in chain.thoughts
        ],
        "conclusion": {
            "id": chain.conclusion.id,
            "content": chain.conclusion.content,
            "confidence": chain.conclusion.confidence
        } if chain.conclusion else None,
        "confidence": chain.confidence,
        "verified": chain.verified,
        "verification_notes": chain.verification_notes
    }


# ==================== VERIFICATION ENDPOINTS ====================

@app.post("/verify")
async def verify_claim(request: VerificationRequest, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    try:
        level = VerificationLevel[request.level.upper()]
    except KeyError:
        raise HTTPException(status_code=400, detail=f"Invalid verification level: {request.level}")

    result = bridge.verification.verify(
        claim=request.claim,
        level=level,
        context=request.context,
        llm_call=bridge.llm_call
    )

    if state.persistence:
        state.persistence.mark_dirty("verification")

    return {
        "claim": result.claim,
        "verified": result.verified,
        "confidence": result.confidence,
        "level": result.level.value,
        "sources": result.sources,
        "contradictions": result.contradictions,
        "uncertainty_factors": result.uncertainty_factors,
        "method": result.method,
        "timestamp": result.timestamp.isoformat()
    }


@app.get("/verify/calibration")
async def verification_calibration(bridge: CognitiveMCPBridge = Depends(get_bridge)):
    return bridge.verification.get_calibration_curve()


@app.post("/verify/calibrate")
async def calibrate_verification(confidence: float, correct: bool, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    bridge.verification.calibrate(confidence, correct)
    if state.persistence:
        state.persistence.mark_dirty("verification")
    return {"status": "calibrated"}


@app.post("/verify/hallucination")
async def detect_hallucination(
    generated_text: str,
    source_material: str,
    bridge: CognitiveMCPBridge = Depends(get_bridge)
):
    result = bridge.verification.detect_hallucination(
        generated_text=generated_text,
        source_material=source_material,
        llm_call=bridge.llm_call
    )
    return result


# ==================== CREATIVE SYNTHESIS ENDPOINTS ====================

@app.post("/creative/blend")
async def blend_concepts(request: CreativeBlendRequest, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    result = bridge.creative.blend(
        request.concept_a,
        request.concept_b,
        request.blend_type,
        bridge.llm_call
    )

    if state.persistence:
        state.persistence.mark_dirty("creative")

    return result


@app.post("/creative/divergent")
async def divergent_generation(request: CreativeDivergentRequest, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    ideas = bridge.creative.divergent_generation(
        seed_concept=request.seed_concept,
        num_ideas=request.num_ideas,
        constraints=request.constraints,
        llm_call=bridge.llm_call
    )
    return {"ideas": ideas, "count": len(ideas)}


@app.post("/creative/concepts")
async def register_concept(request: ConceptRegisterRequest, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    bridge.creative.register_concept(request.name, request.properties, request.domain)

    # Also store in memory
    bridge.memory.store(
        content={"properties": request.properties, "domain": request.domain},
        mem_type=MemoryType.SEMANTIC,
        tags={"concept", request.domain},
        importance=0.8,
        source="creative_register"
    )

    if state.persistence:
        state.persistence.mark_dirty("creative")
        state.persistence.mark_dirty("memory")

    return {"name": request.name, "status": "registered"}


@app.get("/creative/concepts")
async def list_concepts(bridge: CognitiveMCPBridge = Depends(get_bridge)):
    return {
        "concepts": [
            {
                "name": name,
                "domain": concept["domain"],
                "properties": concept["properties"],
                "registered_at": concept["registered_at"].isoformat()
            }
            for name, concept in bridge.creative.concept_space.items()
        ],
        "count": len(bridge.creative.concept_space)
    }


@app.get("/creative/history")
async def blend_history(bridge: CognitiveMCPBridge = Depends(get_bridge)):
    return {
        "blends": [
            {
                "concept_a": b["concept_a"],
                "concept_b": b["concept_b"],
                "type": b["type"],
                "timestamp": b["timestamp"].isoformat(),
                "result": b["result"]
            }
            for b in bridge.creative.blend_history
        ],
        "count": len(bridge.creative.blend_history)
    }


# ==================== HIGH-LEVEL COGNITIVE OPERATIONS ====================

@app.post("/investigate")
async def investigate(request: InvestigationRequest, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    try:
        strategy = ReasoningStrategy(request.strategy)
    except ValueError:
        raise HTTPException(status_code=400, detail=f"Invalid strategy: {request.strategy}")

    result = bridge.investigate(request.topic, request.depth, strategy)

    if state.persistence:
        state.persistence.mark_dirty("memory")
        state.persistence.mark_dirty("reasoning")
        state.persistence.mark_dirty("verification")

    return result


@app.post("/solve")
async def solve_problem(request: ProblemSolveRequest, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    result = bridge.solve_problem(request.problem, request.method, request.verify)

    if state.persistence:
        state.persistence.mark_dirty("memory")
        state.persistence.mark_dirty("reasoning")
        state.persistence.mark_dirty("verification")

    return result


@app.post("/pipeline/create")
async def create_pipeline(request: PipelineDefineRequest, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    steps = [
        PipelineStep(
            id=s.id,
            tool=s.tool,
            params=s.params,
            depends_on=s.depends_on,
            condition=s.condition,
            fallback=s.fallback,
            timeout=s.timeout,
            retries=s.retries
        )
        for s in request.steps
    ]

    bridge.orchestrator.define_pipeline(request.pipeline_id, steps)

    if state.persistence:
        state.persistence.mark_dirty("orchestrator")

    return {"pipeline_id": request.pipeline_id, "steps": len(steps), "status": "defined"}


@app.post("/pipeline/execute")
async def execute_pipeline(request: PipelineExecuteRequest, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    result = bridge.orchestrator.execute_pipeline(
        request.pipeline_id,
        request.initial_params
    )

    if state.persistence:
        state.persistence.mark_dirty("orchestrator")

    return {
        "pipeline_id": result.pipeline_id,
        "success": result.success,
        "error": result.error,
        "execution_time": result.execution_time,
        "completed_steps": result.completed_steps,
        "failed_steps": result.failed_steps,
        "step_results": result.step_results
    }


@app.post("/pipeline/dynamic")
async def dynamic_pipeline(request: PipelineRequest, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    result = bridge.create_and_execute_pipeline(request.goal, request.max_steps)

    if state.persistence:
        state.persistence.mark_dirty("orchestrator")

    return {
        "pipeline_id": result.pipeline_id,
        "success": result.success,
        "error": result.error,
        "execution_time": result.execution_time,
        "completed_steps": result.completed_steps,
        "failed_steps": result.failed_steps,
        "step_results": result.step_results
    }


# ==================== TOOL ENDPOINTS ====================

@app.post("/tools/scrape")
async def scrape_url(request: ScrapeRequest, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    result = bridge.scrape_url(request.url, request.format)
    return result.__dict__


@app.post("/tools/search")
async def search_web(request: SearchRequest, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    results = bridge.search_web(request.query, request.limit)
    return {"results": results, "count": len(results)}


@app.post("/tools/youtube")
async def youtube_transcript(request: YouTubeRequest, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    result = bridge.get_youtube_transcript(request.video_url)
    return result.__dict__


@app.post("/tools/think")
async def think_through(request: ThinkRequest, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    result = bridge.think_through(request.problem, request.steps)
    return result.__dict__


@app.get("/tools/available")
async def list_tools(bridge: CognitiveMCPBridge = Depends(get_bridge)):
    return {
        "tools": list(bridge.orchestrator.tool_executors.keys()),
        "servers": {
            name: config.tools
            for name, config in bridge.process_manager.configs.items()
        }
    }


# ==================== ROUTER ENDPOINTS ====================

@app.get("/router/stats")
async def router_stats(bridge: CognitiveMCPBridge = Depends(get_bridge)):
    return bridge.router.get_stats()


@app.get("/router/ranking/{tool}")
async def router_ranking(tool: str, bridge: CognitiveMCPBridge = Depends(get_bridge)):
    ranking = bridge.router.get_ranking(tool)
    return {"tool": tool, "ranking": [{"server": s, "score": score} for s, score in ranking]}


# ==================== PERSISTENCE ENDPOINTS ====================

@app.post("/persistence/save")
async def save_state(persistence: PersistenceManager = Depends(get_persistence)):
    results = persistence.save_all(force=True)
    return {"results": results, "status": "saved"}


@app.post("/persistence/load")
async def load_state(persistence: PersistenceManager = Depends(get_persistence)):
    results = persistence.load_all()
    return {"results": results, "status": "loaded"}


@app.get("/persistence/stats")
async def persistence_stats(persistence: PersistenceManager = Depends(get_persistence)):
    return persistence.get_stats()


# ==================== LLM CONFIGURATION ====================

@app.post("/llm/configure")
async def configure_llm(config: LLMConfigRequest):
    try:
        provider = create_llm_provider(config)
        state.llm_function = provider
        if state.bridge:
            state.bridge.llm_call = provider
        return {"status": "configured", "provider": config.provider, "model": config.model}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/llm/current")
async def current_llm():
    return {
        "configured": state.llm_function is not None,
        "type": type(state.llm_function).__name__ if state.llm_function else None
    }


# ==================== WEBSOCKET FOR REAL-TIME ====================

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    client_id = str(uuid.uuid4())[:8]
    state.active_websockets[client_id] = websocket

    try:
        # Send welcome
        await websocket.send_json({
            "type": "welcome",
            "client_id": client_id,
            "timestamp": datetime.now().isoformat()
        })

        while True:
            data = await websocket.receive_json()
            message_type = data.get("type")

            if message_type == "reason":
                # Stream reasoning steps
                request = ReasoningRequest(**data.get("payload", {}))
                try:
                    strategy = ReasoningStrategy(request.strategy)
                except ValueError:
                    await websocket.send_json({"type": "error", "message": f"Invalid strategy: {request.strategy}"})
                    continue

                context = ReasoningContext(
                    problem=request.problem,
                    strategy=strategy,
                    max_steps=request.max_steps,
                    max_branches=request.max_branches,
                    temperature=request.temperature,
                    require_verification=request.require_verification,
                    memory=state.bridge.memory,
                    tools=state.bridge.orchestrator.tool_executors
                )

                # Stream each thought as it's generated
                # For demo, we'll send the final result
                chain = state.bridge.reasoning.reason(context, state.bridge.llm_call)

                await websocket.send_json({
                    "type": "reasoning_complete",
                    "chain_id": chain.id,
                    "conclusion": chain.conclusion.content if chain.conclusion else None,
                    "confidence": chain.confidence,
                    "verified": chain.verified,
                    "steps": len(chain.thoughts)
                })

            elif message_type == "investigate":
                request = InvestigationRequest(**data.get("payload", {}))
                try:
                    strategy = ReasoningStrategy(request.strategy)
                except ValueError:
                    await websocket.send_json({"type": "error", "message": f"Invalid strategy: {request.strategy}"})
                    continue

                result = state.bridge.investigate(request.topic, request.depth, strategy)
                await websocket.send_json({
                    "type": "investigation_complete",
                    "result": result
                })

            elif message_type == "ping":
                await websocket.send_json({"type": "pong", "timestamp": datetime.now().isoformat()})

            else:
                await websocket.send_json({"type": "error", "message": f"Unknown message type: {message_type}"})

    except WebSocketDisconnect:
        pass
    except Exception as e:
        await websocket.send_json({"type": "error", "message": str(e)})
    finally:
        state.active_websockets.pop(client_id, None)


# ==================== SERVER SENT EVENTS ====================

@app.get("/events/stream")
async def event_stream(
    bridge: CognitiveMCPBridge = Depends(get_bridge),
    event_types: str = Query("all", description="Comma-separated: reasoning,memory,verification,creative,tools")
):
    """Server-Sent Events stream for real-time updates."""
    types = set(event_types.split(","))

    async def event_generator():
        # Send initial state
        yield {
            "event": "state",
            "data": json.dumps({
                "memory": bridge.memory.get_stats(),
                "reasoning_chains": len(bridge.reasoning.thought_chains),
                "verification_cache": len(bridge.verification.verification_cache),
                "router": bridge.router.get_stats()
            })
        }

        # In a real implementation, this would subscribe to events
        # For now, send periodic updates
        while True:
            await asyncio.sleep(5)
            yield {
                "event": "heartbeat",
                "data": json.dumps({
                    "timestamp": datetime.now().isoformat(),
                    "requests": state.request_count,
                    "errors": state.error_count
                })
            }

    return EventSourceResponse(event_generator())


# ==================== BATCH OPERATIONS ====================

@app.post("/batch/reason")
async def batch_reason(requests: List[ReasoningRequest], bridge: CognitiveMCPBridge = Depends(get_bridge)):
    results = []
    for req in requests:
        try:
            strategy = ReasoningStrategy(req.strategy)
        except ValueError:
            results.append({"error": f"Invalid strategy: {req.strategy}"})
            continue

        context = ReasoningContext(
            problem=req.problem,
            strategy=strategy,
            max_steps=req.max_steps,
            max_branches=req.max_branches,
            temperature=req.temperature,
            require_verification=req.require_verification,
            memory=bridge.memory,
            tools=bridge.orchestrator.tool_executors
        )

        chain = bridge.reasoning.reason(context, bridge.llm_call)
        results.append({
            "chain_id": chain.id,
            "conclusion": chain.conclusion.content if chain.conclusion else None,
            "confidence": chain.confidence,
            "verified": chain.verified
        })

    if state.persistence:
        state.persistence.mark_dirty("reasoning")

    return {"results": results, "count": len(results)}


@app.post("/batch/verify")
async def batch_verify(requests: List[VerificationRequest], bridge: CognitiveMCPBridge = Depends(get_bridge)):
    results = []
    for req in requests:
        try:
            level = VerificationLevel[req.level.upper()]
        except KeyError:
            results.append({"error": f"Invalid level: {req.level}"})
            continue

        result = bridge.verification.verify(req.claim, level, req.context, bridge.llm_call)
        results.append({
            "claim": result.claim,
            "verified": result.verified,
            "confidence": result.confidence,
            "level": result.level.value
        })

    if state.persistence:
        state.persistence.mark_dirty("verification")

    return {"results": results, "count": len(results)}


# ==================== EXPORT/IMPORT ====================

@app.get("/export")
async def export_state(persistence: PersistenceManager = Depends(get_persistence)):
    """Export entire cognitive state as JSON."""
    persistence.save_all(force=True)

    # Collect all data
    export_data = {}
    for key in persistence.backend.list_keys():
        value = persistence.backend.load(key)
        if value is not None:
            export_data[key] = value

    return export_data


@app.post("/import")
async def import_state(data: Dict[str, Any], persistence: PersistenceManager = Depends(get_persistence)):
    """Import cognitive state from JSON."""
    for key, value in data.items():
        persistence.backend.save(key, value)

    # Reload into components
    results = persistence.load_all()
    return {"results": results, "status": "imported"}


# ==================== MAIN ====================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "kashkool_mcp_client.api_server:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )