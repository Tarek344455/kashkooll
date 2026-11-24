"""
Integration Layer — Connects Cognitive Core to actual MCP servers.
This is where thinking meets doing.
"""
import asyncio
import json
import os
import subprocess
import time
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Callable, Dict, List, Optional, Union
from pathlib import Path

from .cognitive_core import (
    MemoryPalace, MemoryType, MemoryNode,
    ReasoningEngine, ReasoningContext, ReasoningStrategy, Thought, ThoughtChain,
    CreativeSynthesis,
    VerificationCore, VerificationLevel, VerificationResult,
    AdaptiveRouter, ServerPerformance,
    ToolOrchestrator, PipelineStep, PipelineResult
)
from .models import ScrapeResult, SearchResult, TranscriptResult, PDFResult, ThinkResult


@dataclass
class MCPServerConfig:
    """Configuration for an MCP server."""
    name: str
    command: List[str]
    tools: List[str]
    env: Dict[str, str] = field(default_factory=dict)
    timeout: int = 60
    health_check: Optional[str] = None


class MCPProcessManager:
    """Manages MCP server processes with health monitoring."""
    
    def __init__(self, npx_path: Optional[str] = None):
        self.npx_path = npx_path or self._find_npx()
        self.processes: Dict[str, subprocess.Popen] = {}
        self.configs: Dict[str, MCPServerConfig] = {}
        self.health_status: Dict[str, bool] = {}
        self.request_counts: Dict[str, int] = {}
        self.error_counts: Dict[str, int] = {}
    
    def _find_npx(self) -> str:
        candidates = [
            r"N:\spaceship-ai\tools\node-v26.13.1-win-x64\npx.cmd",
            r"C:\Program Files\nodejs\npx.cmd",
            "npx",
        ]
        for c in candidates:
            if Path(c).exists() or c == "npx":
                return c
        return "npx"
    
    def register_server(self, config: MCPServerConfig):
        """Register an MCP server configuration."""
        self.configs[config.name] = config
        self.health_status[config.name] = False
        self.request_counts[config.name] = 0
        self.error_counts[config.name] = 0
    
    def start_server(self, name: str) -> bool:
        """Start an MCP server process."""
        if name in self.processes:
            return True
        
        config = self.configs.get(name)
        if not config:
            return False
        
        env = {**os.environ, **config.env}
        try:
            proc = subprocess.Popen(
                config.command,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=env,
                text=True,
                bufsize=1
            )
            self.processes[name] = proc
            
            # Wait for startup
            time.sleep(2)
            
            # Health check
            if config.health_check:
                self.health_status[name] = self._health_check(name, config.health_check)
            else:
                self.health_status[name] = proc.poll() is None
            
            return self.health_status[name]
        except Exception as e:
            print(f"Failed to start {name}: {e}")
            self.health_status[name] = False
            return False
    
    def _health_check(self, name: str, check: str) -> bool:
        """Perform health check on server."""
        # Simplified: just check if process is alive
        proc = self.processes.get(name)
        return proc is not None and proc.poll() is None
    
    def call_tool(
        self,
        server_name: str,
        tool: str,
        params: Dict[str, Any],
        timeout: Optional[int] = None
    ) -> Dict[str, Any]:
        """Call a tool on an MCP server via stdio JSON-RPC."""
        if server_name not in self.processes:
            if not self.start_server(server_name):
                return {"error": f"Server {server_name} not running"}
        
        proc = self.processes[server_name]
        config = self.configs[server_name]
        timeout = timeout or config.timeout
        
        # Build JSON-RPC request
        request = {
            "jsonrpc": "2.0",
            "id": self.request_counts[server_name] + 1,
            "method": "tools/call",
            "params": {
                "name": tool,
                "arguments": params
            }
        }
        
        self.request_counts[server_name] += 1
        
        try:
            # Send request
            request_json = json.dumps(request) + "\n"
            proc.stdin.write(request_json)
            proc.stdin.flush()
            
            # Read response with timeout
            start = time.time()
            while time.time() - start < timeout:
                if proc.stdout.readable():
                    line = proc.stdout.readline()
                    if line:
                        try:
                            response = json.loads(line.strip())
                            if "result" in response:
                                return response["result"]
                            elif "error" in response:
                                self.error_counts[server_name] += 1
                                return {"error": response["error"]}
                        except json.JSONDecodeError:
                            continue
                time.sleep(0.05)
            
            self.error_counts[server_name] += 1
            return {"error": f"Timeout calling {server_name}.{tool}"}
            
        except Exception as e:
            self.error_counts[server_name] += 1
            return {"error": f"MCP call failed: {e}"}
    
    def stop_server(self, name: str):
        """Stop an MCP server."""
        proc = self.processes.pop(name, None)
        if proc:
            try:
                proc.terminate()
                proc.wait(timeout=5)
            except:
                try:
                    proc.kill()
                except:
                    pass
        self.health_status[name] = False
    
    def stop_all(self):
        """Stop all servers."""
        for name in list(self.processes.keys()):
            self.stop_server(name)
    
    def get_stats(self) -> Dict[str, Any]:
        return {
            name: {
                "running": name in self.processes,
                "healthy": self.health_status.get(name, False),
                "requests": self.request_counts.get(name, 0),
                "errors": self.error_counts.get(name, 0),
                "tools": self.configs[name].tools if name in self.configs else []
            }
            for name in self.configs
        }


class CognitiveMCPBridge:
    """
    The bridge between Cognitive Core and MCP servers.
    Translates cognitive operations into tool calls and vice versa.
    """
    
    # Default server configurations for Kashkool stack
    DEFAULT_SERVERS = [
        MCPServerConfig(
            name="zenrows",
            command=["npx", "-y", "@zenrows/mcp"],
            tools=["scrape", "screenshot", "extract"],
            env={}
        ),
        MCPServerConfig(
            name="playwright",
            command=["npx", "-y", "@playwright/mcp"],
            tools=["navigate", "click", "fill", "screenshot", "evaluate"],
            env={}
        ),
        MCPServerConfig(
            name="firecrawl",
            command=["npx", "-y", "firecrawl-mcp"],
            tools=["scrape", "search", "crawl", "map"],
            env={"FIRECRAWL_API_KEY": os.getenv("FIRECRAWL_API_KEY", "")}
        ),
        MCPServerConfig(
            name="jina",
            command=["npx", "-y", "jina-reader-mcp-server"],
            tools=["read", "search"],
            env={"JINA_API_KEY": os.getenv("JINA_API_KEY", "")}
        ),
        MCPServerConfig(
            name="apify",
            command=["npx", "-y", "@apify/actors-mcp-server"],
            tools=["run_actor", "get_dataset"],
            env={"APIFY_TOKEN": os.getenv("APIFY_TOKEN", "")}
        ),
        MCPServerConfig(
            name="youtube",
            command=["npx", "-y", "@fabriqa.ai/youtube-transcript-mcp"],
            tools=["get_transcript", "search_videos"],
            env={}
        ),
        MCPServerConfig(
            name="sequential",
            command=["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"],
            tools=["think"],
            env={}
        ),
        MCPServerConfig(
            name="fetch",
            command=["npx", "-y", "mcp-fetch-server"],
            tools=["fetch"],
            env={}
        ),
        MCPServerConfig(
            name="string",
            command=["npx", "-y", "@usestring/mcp"],
            tools=["search", "fetch"],
            env={"STRING_API_KEY": os.getenv("STRING_API_KEY", "")}
        ),
    ]
    
    def __init__(
        self,
        npx_path: Optional[str] = None,
        custom_servers: Optional[List[MCPServerConfig]] = None,
        llm_call: Optional[Callable[[str], str]] = None
    ):
        self.llm_call = llm_call or self._default_llm
        self.process_manager = MCPProcessManager(npx_path)
        self.router = AdaptiveRouter()
        
        # Register servers
        for config in (custom_servers or self.DEFAULT_SERVERS):
            self.process_manager.register_server(config)
            self.router.register_server(config.name, config.tools)
        
        # Initialize cognitive components
        self.memory = MemoryPalace()
        self.reasoning = ReasoningEngine(self.memory)
        self.creative = CreativeSynthesis(self.memory)
        self.verification = VerificationCore(self.memory)
        self.orchestrator = ToolOrchestrator(
            tool_executors=self._build_executors(),
            router=self.router
        )
        
        # Register core concepts for creative synthesis
        self._register_core_concepts()
    
    def _default_llm(self, prompt: str) -> str:
        """Default LLM call - override with real LLM."""
        return f"[LLM Response to: {prompt[:100]}...]"
    
    def _build_executors(self) -> Dict[str, Callable]:
        """Build tool executors that call MCP servers."""
        executors = {}
        
        # Scrape tools
        for server in ["firecrawl", "zenrows", "jina", "fetch", "playwright"]:
            executors[f"scrape_{server}"] = lambda params, s=server: self._execute_scrape(s, params)
        
        # Search tools
        for server in ["firecrawl", "jina", "string", "apify"]:
            executors[f"search_{server}"] = lambda params, s=server: self._execute_search(s, params)
        
        # YouTube
        executors["youtube_transcript"] = lambda params: self._execute_youtube(params)
        
        # Thinking
        executors["think"] = lambda params: self._execute_think(params)
        
        # Generic tool caller
        executors["call_tool"] = lambda params: self._execute_generic(params)
        
        return executors
    
    def _execute_scrape(self, server: str, params: Dict) -> Dict:
        result = self.process_manager.call_tool(server, "scrape", params)
        return self._normalize_scrape_result(result, server)
    
    def _execute_search(self, server: str, params: Dict) -> Dict:
        tool = "search" if server != "apify" else "run_actor"
        result = self.process_manager.call_tool(server, tool, params)
        return self._normalize_search_result(result, server)
    
    def _execute_youtube(self, params: Dict) -> Dict:
        result = self.process_manager.call_tool("youtube", "get_transcript", params)
        return self._normalize_youtube_result(result)
    
    def _execute_think(self, params: Dict) -> Dict:
        result = self.process_manager.call_tool("sequential", "think", params)
        return {"thinking": result, "server": "sequential"}
    
    def _execute_generic(self, params: Dict) -> Dict:
        """Generic tool call: {server, tool, params}"""
        server = params.pop("server", "")
        tool = params.pop("tool", "")
        return self.process_manager.call_tool(server, tool, params)
    
    def _normalize_scrape_result(self, result: Dict, server: str) -> Dict:
        """Normalize scrape results from different servers."""
        if "error" in result:
            return {"error": result["error"], "server": server}
        
        return {
            "markdown": result.get("markdown", result.get("content", "")),
            "html": result.get("html", ""),
            "text": result.get("text", result.get("content", "")),
            "metadata": result.get("metadata", {}),
            "links": result.get("links", []),
            "images": result.get("images", []),
            "server": server,
            "quality": 0.8 if "markdown" in result else 0.5
        }
    
    def _normalize_search_result(self, result: Dict, server: str) -> Dict:
        if "error" in result:
            return {"error": result["error"], "server": server}
        
        results = result.get("results", result.get("data", []))
        normalized = []
        for r in results:
            normalized.append({
                "title": r.get("title", r.get("name", "")),
                "url": r.get("url", r.get("link", "")),
                "snippet": r.get("snippet", r.get("description", r.get("content", ""))),
                "source": server
            })
        
        return {
            "results": normalized,
            "server": server,
            "quality": 0.8 if normalized else 0.3
        }
    
    def _normalize_youtube_result(self, result: Dict) -> Dict:
        if "error" in result:
            return {"error": result["error"], "server": "youtube"}
        
        transcript = result.get("transcript", result.get("segments", []))
        full_text = " ".join([seg.get("text", "") for seg in transcript])
        
        return {
            "transcript": transcript,
            "full_text": full_text,
            "server": "youtube",
            "quality": 0.9 if transcript else 0.2
        }
    
    def _register_core_concepts(self):
        """Register core concepts for creative synthesis."""
        concepts = {
            "web_scraping": {
                "properties": {
                    "input": "URL",
                    "output": "structured_data",
                    "operations": ["fetch", "parse", "extract", "transform"],
                    "challenges": ["anti_bot", "dynamic_content", "rate_limits", "structure_changes"],
                    "relations": {"enables": ["data_analysis", "monitoring", "aggregation", "research"]}
                },
                "domain": "engineering"
            },
            "search": {
                "properties": {
                    "input": "query",
                    "output": "ranked_results",
                    "operations": ["index", "retrieve", "rank", "filter"],
                    "challenges": ["relevance", "freshness", "spam", "bias"],
                    "relations": {"enables": ["discovery", "research", "fact_checking", "learning"]}
                },
                "domain": "information_retrieval"
            },
            "youtube_transcript": {
                "properties": {
                    "input": "video_id",
                    "output": "timestamped_text",
                    "operations": ["fetch", "align", "segment", "translate"],
                    "challenges": ["availability", "accuracy", "language", "timestamps"],
                    "relations": {"enables": ["summarization", "search", "analysis", "accessibility"]}
                },
                "domain": "media"
            },
            "reasoning": {
                "properties": {
                    "input": "problem",
                    "output": "solution",
                    "operations": ["decompose", "infer", "verify", "synthesize"],
                    "challenges": ["hallucination", "logical_gaps", "bias", "complexity"],
                    "relations": {"enables": ["planning", "decision_making", "creativity", "debugging"]}
                },
                "domain": "cognitive_science"
            },
            "memory": {
                "properties": {
                    "input": "experience",
                    "output": "retrievable_knowledge",
                    "operations": ["encode", "store", "consolidate", "recall", "associate"],
                    "challenges": ["capacity", "forgetting", "interference", "reconsolidation"],
                    "relations": {"enables": ["learning", "personalization", "context", "wisdom"]}
                },
                "domain": "cognitive_science"
            },
            "verification": {
                "properties": {
                    "input": "claim",
                    "output": "truth_value",
                    "operations": ["decompose", "source_check", "cross_reference", "calibrate"],
                    "challenges": ["source_reliability", "ambiguity", "context_dependence", "adversarial"],
                    "relations": {"enables": ["trust", "safety", "accuracy", "accountability"]}
                },
                "domain": "epistemology"
            }
        }
        
        for name, concept in concepts.items():
            self.creative.register_concept(name, concept["properties"], concept["domain"])
            # Also store in memory
            self.memory.store(
                content=concept,
                mem_type=MemoryType.SEMANTIC,
                tags={"core_concept", concept["domain"]},
                importance=0.9,
                source="cognitive_core_init"
            )
    
    # ==================== HIGH-LEVEL COGNITIVE OPERATIONS ====================
    
    def investigate(
        self,
        topic: str,
        depth: str = "standard",  # quick, standard, deep
        strategy: ReasoningStrategy = ReasoningStrategy.CHAIN_OF_THOUGHT
    ) -> Dict[str, Any]:
        """
        Deep investigation of a topic using full cognitive stack.
        """
        # Adjust parameters by depth
        depth_config = {
            "quick": {"max_steps": 5, "max_branches": 2, "verify_level": VerificationLevel.BASIC},
            "standard": {"max_steps": 10, "max_branches": 3, "verify_level": VerificationLevel.CROSS_REFERENCE},
            "deep": {"max_steps": 20, "max_branches": 4, "verify_level": VerificationLevel.DEEP}
        }
        config = depth_config.get(depth, depth_config["standard"])
        
        # Phase 1: Search & Gather
        search_results = self.search_web(topic, limit=10)
        
        # Store in episodic memory
        episode_id = self.memory.store(
            content={"topic": topic, "search_results": search_results, "timestamp": datetime.now()},
            mem_type=MemoryType.EPISODIC,
            tags={"investigation", topic},
            importance=0.8,
            source="investigate"
        )
        
        # Phase 2: Reason
        context = ReasoningContext(
            problem=f"Investigate and synthesize comprehensive understanding of: {topic}",
            strategy=strategy,
            max_steps=config["max_steps"],
            max_branches=config["max_branches"],
            require_verification=True,
            memory=self.memory,
            tools=self.orchestrator.tool_executors
        )
        
        chain = self.reasoning.reason(context, self.llm_call)
        
        # Phase 3: Verify key claims
        verified_claims = []
        if chain.conclusion:
            verification = self.verification.verify(
                chain.conclusion.content,
                level=config["verify_level"],
                context=topic,
                llm_call=self.llm_call
            )
            verified_claims.append({
                "claim": chain.conclusion.content,
                "verification": verification.__dict__
            })
        
        # Phase 4: Creative synthesis - generate novel insights
        creative_insights = self.creative.divergent_generation(
            seed_concept="web_scraping",
            num_ideas=5,
            constraints=[f"related to {topic}", "actionable", "novel"],
            llm_call=self.llm_call
        )
        
        return {
            "topic": topic,
            "depth": depth,
            "search_results": search_results,
            "reasoning_chain": {
                "id": chain.id,
                "steps": len(chain.thoughts),
                "conclusion": chain.conclusion.content if chain.conclusion else None,
                "confidence": chain.confidence,
                "verified": chain.verified
            },
            "verified_claims": verified_claims,
            "creative_insights": creative_insights,
            "episode_id": episode_id,
            "timestamp": datetime.now().isoformat()
        }
    
    def solve_problem(
        self,
        problem: str,
        method: str = "auto",  # auto, first_principles, analogical, react, plan_and_solve
        verify: bool = True
    ) -> Dict[str, Any]:
        """Solve a problem using the best reasoning strategy."""
        
        strategy_map = {
            "first_principles": ReasoningStrategy.FIRST_PRINCIPLES,
            "analogical": ReasoningStrategy.ANALOGICAL,
            "react": ReasoningStrategy.REACT,
            "plan_and_solve": ReasoningStrategy.PLAN_AND_SOLVE,
            "self_consistency": ReasoningStrategy.SELF_CONSISTENCY,
            "tree_of_thoughts": ReasoningStrategy.TREE_OF_THOUGHTS,
        }
        
        if method == "auto":
            # Choose strategy based on problem type
            strategy = self._choose_strategy(problem)
        else:
            strategy = strategy_map.get(method, ReasoningStrategy.CHAIN_OF_THOUGHT)
        
        context = ReasoningContext(
            problem=problem,
            strategy=strategy,
            max_steps=15,
            max_branches=3,
            require_verification=verify,
            memory=self.memory,
            tools=self.orchestrator.tool_executors
        )
        
        chain = self.reasoning.reason(context, self.llm_call)
        
        result = {
            "problem": problem,
            "strategy": strategy.value,
            "chain_id": chain.id,
            "steps": len(chain.thoughts),
            "conclusion": chain.conclusion.content if chain.conclusion else None,
            "confidence": chain.confidence,
            "verified": chain.verified,
            "verification_notes": chain.verification_notes
        }
        
        if verify and chain.conclusion:
            verification = self.verification.verify(
                chain.conclusion.content,
                level=VerificationLevel.DEEP,
                context=problem,
                llm_call=self.llm_call
            )
            result["verification"] = verification.__dict__
        
        # Store in procedural memory if successful
        if chain.confidence > 0.7:
            self.memory.store(
                content={"problem": problem, "solution": chain.conclusion.content, "method": strategy.value},
                mem_type=MemoryType.PROCEDURAL,
                tags={"solution", "procedure"},
                importance=0.8,
                source="solve_problem"
            )
        
        return result
    
    def _choose_strategy(self, problem: str) -> ReasoningStrategy:
        """Heuristically choose reasoning strategy."""
        problem_lower = problem.lower()
        
        if any(kw in problem_lower for kw in ["why", "fundamental", "root cause", "first principle", "assumption"]):
            return ReasoningStrategy.FIRST_PRINCIPLES
        elif any(kw in problem_lower for kw in ["like", "similar to", "analogy", "compare", "metaphor"]):
            return ReasoningStrategy.ANALOGICAL
        elif any(kw in problem_lower for kw in ["step by step", "plan", "how to", "procedure", "execute"]):
            return ReasoningStrategy.PLAN_AND_SOLVE
        elif any(kw in problem_lower for kw in ["tool", "api", "call", "fetch", "search", "act"]):
            return ReasoningStrategy.REACT
        elif any(kw in problem_lower for kw in ["complex", "multiple", "options", "explore", "branches"]):
            return ReasoningStrategy.TREE_OF_THOUGHTS
        else:
            return ReasoningStrategy.CHAIN_OF_THOUGHT
    
    def create_and_execute_pipeline(
        self,
        goal: str,
        max_steps: int = 10
    ) -> PipelineResult:
        """Dynamically create and execute a pipeline for a goal."""
        steps = self.orchestrator.create_dynamic_pipeline(
            goal=goal,
            available_tools=list(self.orchestrator.tool_executors.keys()),
            llm_call=self.llm_call,
            max_steps=max_steps
        )
        
        pipeline_id = f"pipeline_{int(time.time())}"
        self.orchestrator.define_pipeline(pipeline_id, steps)
        
        return self.orchestrator.execute_pipeline(pipeline_id)
    
    def blend_concepts(
        self,
        concept_a: str,
        concept_b: str,
        blend_type: str = "hybrid"
    ) -> Dict[str, Any]:
        """Creative concept blending."""
        return self.creative.blend(concept_a, concept_b, blend_type, self.llm_call)
    
    def verify_claim(
        self,
        claim: str,
        level: VerificationLevel = VerificationLevel.CROSS_REFERENCE,
        context: Optional[str] = None
    ) -> VerificationResult:
        """Verify a claim."""
        return self.verification.verify(claim, level, context, self.llm_call)
    
    def search_web(self, query: str, limit: int = 10) -> List[Dict]:
        """Search using best available search server."""
        server = self.router.select_server("search")
        result = self.process_manager.call_tool(server, "search", {"query": query, "limit": limit})
        return self._normalize_search_result(result, server).get("results", [])
    
    def scrape_url(self, url: str, format: str = "markdown") -> ScrapeResult:
        """Scrape using best available scrape server."""
        server = self.router.select_server("scrape")
        result = self.process_manager.call_tool(server, "scrape", {"url": url, "format": format})
        normalized = self._normalize_scrape_result(result, server)
        
        return ScrapeResult(
            url=url,
            markdown=normalized.get("markdown", ""),
            html=normalized.get("html", ""),
            text=normalized.get("text", ""),
            metadata=normalized.get("metadata", {}),
            links=normalized.get("links", []),
            images=normalized.get("images", []),
            success="error" not in normalized,
            error=normalized.get("error"),
            server_used=server
        )
    
    def get_youtube_transcript(self, video_url: str) -> TranscriptResult:
        """Get YouTube transcript."""
        result = self.process_manager.call_tool("youtube", "get_transcript", {"video_url": video_url})
        normalized = self._normalize_youtube_result(result)
        
        import re
        video_id = video_url
        if "youtube.com" in video_url or "youtu.be" in video_url:
            patterns = [r"(?:v=|/)([0-9A-Za-z_-]{11}).*", r"youtu\.be/([0-9A-Za-z_-]{11})"]
            for p in patterns:
                m = re.search(p, video_url)
                if m:
                    video_id = m.group(1)
                    break
        
        return TranscriptResult(
            video_id=video_id,
            video_url=video_url,
            transcript=normalized.get("transcript", []),
            full_text=normalized.get("full_text", ""),
            success="error" not in normalized,
            error=normalized.get("error"),
            server_used="youtube"
        )
    
    def think_through(self, problem: str, steps: int = 5) -> ThinkResult:
        """Use sequential thinking server."""
        result = self.process_manager.call_tool("sequential", "think", {"problem": problem, "steps": steps})
        
        return ThinkResult(
            steps=result.get("thinking", {}).get("steps", []),
            conclusion=result.get("thinking", {}).get("conclusion", ""),
            success="error" not in result,
            error=result.get("error"),
            server_used="sequential"
        )
    
    def get_system_status(self) -> Dict[str, Any]:
        """Get comprehensive system status."""
        return {
            "servers": self.process_manager.get_stats(),
            "router": self.router.get_stats(),
            "memory": self.memory.get_stats(),
            "reasoning_chains": len(self.reasoning.thought_chains),
            "thought_trees": len(self.reasoning.thought_trees),
            "verification_cache": len(self.verification.verification_cache),
            "calibration": self.verification.get_calibration_curve(),
            "pipelines": len(self.orchestrator.pipelines),
            "execution_history": len(self.orchestrator.execution_history)
        }
    
    def start_all_servers(self) -> Dict[str, bool]:
        """Start all registered servers."""
        results = {}
        for name in self.process_manager.configs:
            results[name] = self.process_manager.start_server(name)
        return results
    
    def stop_all_servers(self):
        """Stop all servers."""
        self.process_manager.stop_all()
    
    def __enter__(self):
        self.start_all_servers()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.stop_all_servers()


# ==================== CONVENIENCE FUNCTIONS ====================

_default_bridge: Optional[CognitiveMCPBridge] = None


def get_bridge(
    npx_path: Optional[str] = None,
    llm_call: Optional[Callable[[str], str]] = None
) -> CognitiveMCPBridge:
    """Get or create the default bridge instance."""
    global _default_bridge
    if _default_bridge is None:
        _default_bridge = CognitiveMCPBridge(npx_path=npx_path, llm_call=llm_call)
    return _default_bridge


def investigate(topic: str, depth: str = "standard", **kwargs) -> Dict[str, Any]:
    """Quick investigation."""
    bridge = get_bridge()
    return bridge.investigate(topic, depth, **kwargs)


def solve(problem: str, method: str = "auto", **kwargs) -> Dict[str, Any]:
    """Quick problem solving."""
    bridge = get_bridge()
    return bridge.solve_problem(problem, method, **kwargs)


def verify(claim: str, level: VerificationLevel = VerificationLevel.CROSS_REFERENCE, **kwargs) -> VerificationResult:
    """Quick verification."""
    bridge = get_bridge()
    return bridge.verify_claim(claim, level, **kwargs)


def search(query: str, limit: int = 10) -> List[Dict]:
    """Quick search."""
    bridge = get_bridge()
    return bridge.search_web(query, limit)


def scrape(url: str, format: str = "markdown") -> ScrapeResult:
    """Quick scrape."""
    bridge = get_bridge()
    return bridge.scrape_url(url, format)


def youtube_transcript(video_url: str) -> TranscriptResult:
    """Quick YouTube transcript."""
    bridge = get_bridge()
    return bridge.get_youtube_transcript(video_url)


def think(problem: str, steps: int = 5) -> ThinkResult:
    """Quick thinking."""
    bridge = get_bridge()
    return bridge.think_through(problem, steps)


def pipeline(goal: str, max_steps: int = 10) -> PipelineResult:
    """Quick pipeline creation and execution."""
    bridge = get_bridge()
    return bridge.create_and_execute_pipeline(goal, max_steps)


def blend(a: str, b: str, blend_type: str = "hybrid") -> Dict[str, Any]:
    """Quick concept blending."""
    bridge = get_bridge()
    return bridge.blend_concepts(a, b, blend_type)


def status() -> Dict[str, Any]:
    """Get system status."""
    bridge = get_bridge()
    return bridge.get_system_status()