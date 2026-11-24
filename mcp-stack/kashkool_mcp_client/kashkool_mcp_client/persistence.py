"""
Persistence Layer — Save/load cognitive state, memory, reasoning chains.
Supports multiple backends: JSON, SQLite, Redis, PostgreSQL.
"""
import json
import sqlite3
import pickle
import os
import threading
from abc import ABC, abstractmethod
from dataclasses import dataclass, field, asdict
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Union
from contextlib import contextmanager

from .cognitive_core import (
    MemoryPalace, MemoryType, MemoryNode,
    Thought, ThoughtType, ThoughtChain, ThoughtTree,
    ReasoningEngine, ReasoningContext, ReasoningStrategy,
    CreativeSynthesis,
    VerificationCore, VerificationLevel, VerificationResult,
    AdaptiveRouter, ServerPerformance,
    ToolOrchestrator, PipelineStep, PipelineResult
)


# ==================== SERIALIZATION HELPERS ====================

def serialize_memory_node(node: MemoryNode) -> Dict[str, Any]:
    """Serialize a MemoryNode to dict."""
    return {
        "id": node.id,
        "type": node.type.value,
        "content": node.content,
        "embedding": node.embedding,
        "connections": node.connections,
        "access_count": node.access_count,
        "last_accessed": node.last_accessed.isoformat(),
        "created_at": node.created_at.isoformat(),
        "importance": node.importance,
        "tags": list(node.tags),
        "source": node.source,
        "verified": node.verified,
        "verification_sources": node.verification_sources
    }


def deserialize_memory_node(data: Dict[str, Any]) -> MemoryNode:
    """Deserialize a MemoryNode from dict."""
    return MemoryNode(
        id=data["id"],
        type=MemoryType(data["type"]),
        content=data["content"],
        embedding=data.get("embedding"),
        connections=data.get("connections", {}),
        access_count=data.get("access_count", 0),
        last_accessed=datetime.fromisoformat(data["last_accessed"]),
        created_at=datetime.fromisoformat(data["created_at"]),
        importance=data.get("importance", 0.5),
        tags=set(data.get("tags", [])),
        source=data.get("source", ""),
        verified=data.get("verified", False),
        verification_sources=data.get("verification_sources", [])
    )


def serialize_thought(thought: Thought) -> Dict[str, Any]:
    """Serialize a Thought to dict."""
    return {
        "id": thought.id,
        "type": thought.type.value,
        "content": thought.content,
        "confidence": thought.confidence,
        "evidence": thought.evidence,
        "contradicts": thought.contradicts,
        "metadata": thought.metadata,
        "timestamp": thought.timestamp.isoformat(),
        "parent_id": thought.parent_id,
        "children_ids": thought.children_ids
    }


def deserialize_thought(data: Dict[str, Any]) -> Thought:
    """Deserialize a Thought from dict."""
    return Thought(
        id=data["id"],
        type=ThoughtType(data["type"]),
        content=data["content"],
        confidence=data.get("confidence", 0.5),
        evidence=data.get("evidence", []),
        contradicts=data.get("contradicts", []),
        metadata=data.get("metadata", {}),
        timestamp=datetime.fromisoformat(data["timestamp"]),
        parent_id=data.get("parent_id"),
        children_ids=data.get("children_ids", [])
    )


def serialize_thought_chain(chain: ThoughtChain) -> Dict[str, Any]:
    """Serialize a ThoughtChain to dict."""
    return {
        "id": chain.id,
        "thoughts": [serialize_thought(t) for t in chain.thoughts],
        "goal": chain.goal,
        "conclusion": serialize_thought(chain.conclusion) if chain.conclusion else None,
        "confidence": chain.confidence,
        "verified": chain.verified,
        "verification_notes": chain.verification_notes
    }


def deserialize_thought_chain(data: Dict[str, Any]) -> ThoughtChain:
    """Deserialize a ThoughtChain from dict."""
    chain = ThoughtChain(
        id=data["id"],
        goal=data["goal"],
        confidence=data.get("confidence", 0.0),
        verified=data.get("verified", False),
        verification_notes=data.get("verification_notes", "")
    )
    chain.thoughts = [deserialize_thought(t) for t in data.get("thoughts", [])]
    if data.get("conclusion"):
        chain.conclusion = deserialize_thought(data["conclusion"])
    return chain


def serialize_verification_result(result: VerificationResult) -> Dict[str, Any]:
    """Serialize a VerificationResult to dict."""
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


def deserialize_verification_result(data: Dict[str, Any]) -> VerificationResult:
    """Deserialize a VerificationResult from dict."""
    return VerificationResult(
        claim=data["claim"],
        verified=data["verified"],
        confidence=data["confidence"],
        level=VerificationLevel(data["level"]),
        sources=data.get("sources", []),
        contradictions=data.get("contradictions", []),
        uncertainty_factors=data.get("uncertainty_factors", []),
        method=data.get("method", ""),
        timestamp=datetime.fromisoformat(data["timestamp"])
    )


def serialize_server_performance(perf: ServerPerformance) -> Dict[str, Any]:
    """Serialize ServerPerformance to dict."""
    return {
        "server_name": perf.server_name,
        "tool": perf.tool,
        "success_count": perf.success_count,
        "failure_count": perf.failure_count,
        "total_latency": perf.total_latency,
        "quality_scores": perf.quality_scores,
        "last_used": perf.last_used.isoformat()
    }


def deserialize_server_performance(data: Dict[str, Any]) -> ServerPerformance:
    """Deserialize ServerPerformance from dict."""
    perf = ServerPerformance(
        server_name=data["server_name"],
        tool=data["tool"],
        success_count=data.get("success_count", 0),
        failure_count=data.get("failure_count", 0),
        total_latency=data.get("total_latency", 0.0),
        quality_scores=data.get("quality_scores", []),
        last_used=datetime.fromisoformat(data["last_used"])
    )
    return perf


# ==================== STORAGE BACKENDS ====================

class StorageBackend(ABC):
    """Abstract storage backend."""

    @abstractmethod
    def save(self, key: str, value: Any) -> bool:
        pass

    @abstractmethod
    def load(self, key: str) -> Optional[Any]:
        pass

    @abstractmethod
    def delete(self, key: str) -> bool:
        pass

    @abstractmethod
    def list_keys(self, prefix: str = "") -> List[str]:
        pass

    @abstractmethod
    def close(self):
        pass


class JSONFileBackend(StorageBackend):
    """JSON file storage backend."""

    def __init__(self, base_path: Union[str, Path]):
        self.base_path = Path(base_path)
        self.base_path.mkdir(parents=True, exist_ok=True)
        self._lock = threading.RLock()

    def _get_path(self, key: str) -> Path:
        # Sanitize key for filesystem
        safe_key = key.replace("/", "_").replace("\\", "_").replace(":", "_")
        return self.base_path / f"{safe_key}.json"

    def save(self, key: str, value: Any) -> bool:
        with self._lock:
            try:
                path = self._get_path(key)
                with open(path, "w", encoding="utf-8") as f:
                    json.dump(value, f, ensure_ascii=False, indent=2, default=str)
                return True
            except Exception as e:
                print(f"JSON save error for {key}: {e}")
                return False

    def load(self, key: str) -> Optional[Any]:
        with self._lock:
            try:
                path = self._get_path(key)
                if not path.exists():
                    return None
                with open(path, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception as e:
                print(f"JSON load error for {key}: {e}")
                return None

    def delete(self, key: str) -> bool:
        with self._lock:
            try:
                path = self._get_path(key)
                if path.exists():
                    path.unlink()
                return True
            except Exception:
                return False

    def list_keys(self, prefix: str = "") -> List[str]:
        with self._lock:
            safe_prefix = prefix.replace("/", "_").replace("\\", "_").replace(":", "_")
            keys = []
            for path in self.base_path.glob(f"{safe_prefix}*.json"):
                key = path.stem
                keys.append(key)
            return keys

    def close(self):
        pass


class SQLiteBackend(StorageBackend):
    """SQLite storage backend with indexing."""

    def __init__(self, db_path: Union[str, Path]):
        self.db_path = Path(db_path)
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._conn = None
        self._lock = threading.RLock()
        self._init_db()

    def _get_conn(self):
        if self._conn is None:
            self._conn = sqlite3.connect(str(self.db_path), check_same_thread=False)
            self._conn.row_factory = sqlite3.Row
        return self._conn

    def _init_db(self):
        with self._lock:
            conn = self._get_conn()
            conn.executescript("""
                CREATE TABLE IF NOT EXISTS kv_store (
                    key TEXT PRIMARY KEY,
                    value TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                CREATE INDEX IF NOT EXISTS idx_kv_prefix ON kv_store(key);
                CREATE TABLE IF NOT EXISTS memory_nodes (
                    id TEXT PRIMARY KEY,
                    type TEXT NOT NULL,
                    content TEXT,
                    embedding TEXT,
                    connections TEXT,
                    access_count INTEGER DEFAULT 0,
                    last_accessed TIMESTAMP,
                    created_at TIMESTAMP,
                    importance REAL DEFAULT 0.5,
                    tags TEXT,
                    source TEXT,
                    verified INTEGER DEFAULT 0,
                    verification_sources TEXT
                );
                CREATE INDEX IF NOT EXISTS idx_memory_type ON memory_nodes(type);
                CREATE INDEX IF NOT EXISTS idx_memory_tags ON memory_nodes(tags);
                CREATE TABLE IF NOT EXISTS thought_chains (
                    id TEXT PRIMARY KEY,
                    goal TEXT,
                    thoughts TEXT,
                    conclusion TEXT,
                    confidence REAL,
                    verified INTEGER,
                    verification_notes TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
                CREATE TABLE IF NOT EXISTS verification_results (
                    id TEXT PRIMARY KEY,
                    claim TEXT,
                    verified INTEGER,
                    confidence REAL,
                    level INTEGER,
                    sources TEXT,
                    contradictions TEXT,
                    uncertainty_factors TEXT,
                    method TEXT,
                    timestamp TIMESTAMP
                );
                CREATE TABLE IF NOT EXISTS server_performance (
                    key TEXT PRIMARY KEY,
                    server_name TEXT,
                    tool TEXT,
                    success_count INTEGER,
                    failure_count INTEGER,
                    total_latency REAL,
                    quality_scores TEXT,
                    last_used TIMESTAMP
                );
            """)
            conn.commit()

    def save(self, key: str, value: Any) -> bool:
        with self._lock:
            try:
                conn = self._get_conn()
                json_value = json.dumps(value, default=str)
                conn.execute(
                    "INSERT OR REPLACE INTO kv_store (key, value, updated_at) VALUES (?, ?, ?)",
                    (key, json_value, datetime.now().isoformat())
                )
                conn.commit()
                return True
            except Exception as e:
                print(f"SQLite save error for {key}: {e}")
                return False

    def load(self, key: str) -> Optional[Any]:
        with self._lock:
            try:
                conn = self._get_conn()
                cursor = conn.execute("SELECT value FROM kv_store WHERE key = ?", (key,))
                row = cursor.fetchone()
                if row:
                    return json.loads(row["value"])
                return None
            except Exception as e:
                print(f"SQLite load error for {key}: {e}")
                return None

    def delete(self, key: str) -> bool:
        with self._lock:
            try:
                conn = self._get_conn()
                conn.execute("DELETE FROM kv_store WHERE key = ?", (key,))
                conn.commit()
                return True
            except Exception:
                return False

    def list_keys(self, prefix: str = "") -> List[str]:
        with self._lock:
            try:
                conn = self._get_conn()
                if prefix:
                    cursor = conn.execute("SELECT key FROM kv_store WHERE key LIKE ?", (f"{prefix}%",))
                else:
                    cursor = conn.execute("SELECT key FROM kv_store")
                return [row["key"] for row in cursor.fetchall()]
            except Exception:
                return []

    def close(self):
        with self._lock:
            if self._conn:
                self._conn.close()
                self._conn = None


class RedisBackend(StorageBackend):
    """Redis storage backend (requires redis-py)."""

    def __init__(self, host: str = "localhost", port: int = 6379, db: int = 0, password: Optional[str] = None):
        try:
            import redis
            self.client = redis.Redis(
                host=host, port=port, db=db, password=password,
                decode_responses=True
            )
            self.client.ping()  # Test connection
        except ImportError:
            raise RuntimeError("redis-py not installed. Run: pip install redis")
        except Exception as e:
            raise RuntimeError(f"Failed to connect to Redis: {e}")

    def save(self, key: str, value: Any) -> bool:
        try:
            json_value = json.dumps(value, default=str)
            self.client.set(key, json_value)
            return True
        except Exception as e:
            print(f"Redis save error for {key}: {e}")
            return False

    def load(self, key: str) -> Optional[Any]:
        try:
            value = self.client.get(key)
            if value:
                return json.loads(value)
            return None
        except Exception as e:
            print(f"Redis load error for {key}: {e}")
            return None

    def delete(self, key: str) -> bool:
        try:
            self.client.delete(key)
            return True
        except Exception:
            return False

    def list_keys(self, prefix: str = "") -> List[str]:
        try:
            pattern = f"{prefix}*" if prefix else "*"
            return list(self.client.scan_iter(match=pattern))
        except Exception:
            return []

    def close(self):
        try:
            self.client.close()
        except Exception:
            pass


# ==================== PERSISTENCE MANAGER ====================

@dataclass
class PersistenceConfig:
    """Configuration for persistence."""
    backend: str = "json"  # json, sqlite, redis
    path: str = "./cognitive_data"
    redis_host: str = "localhost"
    redis_port: int = 6379
    redis_db: int = 0
    redis_password: Optional[str] = None
    auto_save_interval: int = 30  # seconds
    max_memory_nodes: int = 10000
    max_thought_chains: int = 1000
    max_verification_cache: int = 5000


class PersistenceManager:
    """
    Manages persistence of all cognitive components.
    Handles automatic saving, loading, and synchronization.
    """

    def __init__(self, config: PersistenceConfig):
        self.config = config
        self.backend = self._create_backend(config)
        self._auto_save_timer: Optional[threading.Timer] = None
        self._dirty: Set[str] = set()
        self._lock = threading.RLock()

        # Component references (set via register)
        self.memory: Optional[MemoryPalace] = None
        self.reasoning: Optional[ReasoningEngine] = None
        self.creative: Optional[CreativeSynthesis] = None
        self.verification: Optional[VerificationCore] = None
        self.router: Optional[AdaptiveRouter] = None
        self.orchestrator: Optional[ToolOrchestrator] = None

    def _create_backend(self, config: PersistenceConfig) -> StorageBackend:
        if config.backend == "json":
            return JSONFileBackend(config.path)
        elif config.backend == "sqlite":
            return SQLiteBackend(Path(config.path) / "cognitive.db")
        elif config.backend == "redis":
            return RedisBackend(
                host=config.redis_host,
                port=config.redis_port,
                db=config.redis_db,
                password=config.redis_password
            )
        else:
            raise ValueError(f"Unknown backend: {config.backend}")

    def register_components(
        self,
        memory: Optional[MemoryPalace] = None,
        reasoning: Optional[ReasoningEngine] = None,
        creative: Optional[CreativeSynthesis] = None,
        verification: Optional[VerificationCore] = None,
        router: Optional[AdaptiveRouter] = None,
        orchestrator: Optional[ToolOrchestrator] = None
    ):
        """Register cognitive components for persistence."""
        if memory:
            self.memory = memory
        if reasoning:
            self.reasoning = reasoning
        if creative:
            self.creative = creative
        if verification:
            self.verification = verification
        if router:
            self.router = router
        if orchestrator:
            self.orchestrator = orchestrator

    def mark_dirty(self, component: str):
        """Mark a component as needing save."""
        with self._lock:
            self._dirty.add(component)

    def save_all(self, force: bool = False) -> Dict[str, bool]:
        """Save all registered components."""
        results = {}

        with self._lock:
            components_to_save = self._dirty.copy() if not force else {
                "memory", "reasoning", "creative", "verification", "router", "orchestrator"
            }

        for component in components_to_save:
            try:
                if component == "memory" and self.memory:
                    results[component] = self._save_memory()
                elif component == "reasoning" and self.reasoning:
                    results[component] = self._save_reasoning()
                elif component == "creative" and self.creative:
                    results[component] = self._save_creative()
                elif component == "verification" and self.verification:
                    results[component] = self._save_verification()
                elif component == "router" and self.router:
                    results[component] = self._save_router()
                elif component == "orchestrator" and self.orchestrator:
                    results[component] = self._save_orchestrator()
                else:
                    results[component] = True  # Not registered

                if results[component]:
                    with self._lock:
                        self._dirty.discard(component)
            except Exception as e:
                print(f"Error saving {component}: {e}")
                results[component] = False

        return results

    def _save_memory(self) -> bool:
        if not self.memory:
            return True

        # Save memory nodes in batches
        nodes_data = {}
        for node_id, node in self.memory._all_nodes.items():
            nodes_data[node_id] = serialize_memory_node(node)

        # Save metadata
        meta = {
            "capacity": self.memory.capacity,
            "consolidation_threshold": self.memory._consolidation_threshold,
            "forgetting_curve_factor": self.memory._forgetting_curve_factor,
            "node_count": len(nodes_data),
            "saved_at": datetime.now().isoformat()
        }

        return (
            self.backend.save("memory:meta", meta) and
            self.backend.save("memory:nodes", nodes_data) and
            self.backend.save("memory:tag_index", {k: list(v) for k, v in self.memory._index_by_tag.items()})
        )

    def _save_reasoning(self) -> bool:
        if not self.reasoning:
            return True

        chains_data = {
            cid: serialize_thought_chain(chain)
            for cid, chain in self.reasoning.thought_chains.items()
        }

        trees_data = {}
        for tid, tree in self.reasoning.thought_trees.items():
            trees_data[tid] = {
                "id": tree.id,
                "root": serialize_thought(tree.root),
                "nodes": {nid: serialize_thought(node) for nid, node in tree.nodes.items()},
                "best_path": tree.best_path,
                "explored_paths": tree.explored_paths,
                "pruned_paths": tree.pruned_paths
            }

        return (
            self.backend.save("reasoning:chains", chains_data) and
            self.backend.save("reasoning:trees", trees_data)
        )

    def _save_creative(self) -> bool:
        if not self.creative:
            return True

        concepts_data = {
            name: {
                "properties": concept["properties"],
                "domain": concept["domain"],
                "registered_at": concept["registered_at"].isoformat()
            }
            for name, concept in self.creative.concept_space.items()
        }

        blends_data = [
            {
                "concept_a": b["concept_a"],
                "concept_b": b["concept_b"],
                "type": b["type"],
                "timestamp": b["timestamp"].isoformat(),
                "result": b["result"]
            }
            for b in self.creative.blend_history
        ]

        return (
            self.backend.save("creative:concepts", concepts_data) and
            self.backend.save("creative:blends", blends_data)
        )

    def _save_verification(self) -> bool:
        if not self.verification:
            return True

        cache_data = {
            key: serialize_verification_result(result)
            for key, result in self.verification.verification_cache.items()
        }

        calibration_data = [
            {"confidence": c, "correct": corr}
            for c, corr in self.verification.calibration_data
        ]

        return (
            self.backend.save("verification:cache", cache_data) and
            self.backend.save("verification:calibration", calibration_data)
        )

    def _save_router(self) -> bool:
        if not self.router:
            return True

        perf_data = {
            key: serialize_server_performance(perf)
            for key, perf in self.router.performance.items()
        }

        tool_servers = {k: list(v) for k, v in self.router.tool_servers.items()}
        total_selections = dict(self.router.total_selections)

        return (
            self.backend.save("router:performance", perf_data) and
            self.backend.save("router:tool_servers", tool_servers) and
            self.backend.save("router:total_selections", total_selections)
        )

    def _save_orchestrator(self) -> bool:
        if not self.orchestrator:
            return True

        pipelines_data = {}
        for pid, steps in self.orchestrator.pipelines.items():
            pipelines_data[pid] = [
                {
                    "id": s.id,
                    "tool": s.tool,
                    "params": s.params,
                    "depends_on": s.depends_on,
                    "condition": s.condition,
                    "fallback": s.fallback,
                    "timeout": s.timeout,
                    "retries": s.retries
                }
                for s in steps
            ]

        history_data = [
            {
                "pipeline_id": r.pipeline_id,
                "step_results": r.step_results,
                "success": r.success,
                "error": r.error,
                "execution_time": r.execution_time,
                "completed_steps": r.completed_steps,
                "failed_steps": r.failed_steps
            }
            for r in self.orchestrator.execution_history[-100:]  # Keep last 100
        ]

        return (
            self.backend.save("orchestrator:pipelines", pipelines_data) and
            self.backend.save("orchestrator:history", history_data)
        )

    def load_all(self) -> Dict[str, bool]:
        """Load all registered components."""
        results = {}

        if self.memory:
            results["memory"] = self._load_memory()
        if self.reasoning:
            results["reasoning"] = self._load_reasoning()
        if self.creative:
            results["creative"] = self._load_creative()
        if self.verification:
            results["verification"] = self._load_verification()
        if self.router:
            results["router"] = self._load_router()
        if self.orchestrator:
            results["orchestrator"] = self._load_orchestrator()

        return results

    def _load_memory(self) -> bool:
        if not self.memory:
            return True

        meta = self.backend.load("memory:meta")
        nodes_data = self.backend.load("memory:nodes")
        tag_index = self.backend.load("memory:tag_index")

        if not nodes_data:
            return True

        # Restore nodes
        for node_id, node_data in nodes_data.items():
            node = deserialize_memory_node(node_data)
            store = self.memory._get_store(node.type)
            store[node_id] = node
            self.memory._all_nodes[node_id] = node

        # Restore tag index
        if tag_index:
            self.memory._index_by_tag = {k: set(v) for k, v in tag_index.items()}

        # Restore meta
        if meta:
            self.memory.capacity = meta.get("capacity", self.memory.capacity)
            self.memory._consolidation_threshold = meta.get("consolidation_threshold", 0.7)
            self.memory._forgetting_curve_factor = meta.get("forgetting_curve_factor", 0.99)

        return True

    def _load_reasoning(self) -> bool:
        if not self.reasoning:
            return True

        chains_data = self.backend.load("reasoning:chains")
        trees_data = self.backend.load("reasoning:trees")

        if chains_data:
            for cid, chain_data in chains_data.items():
                self.reasoning.thought_chains[cid] = deserialize_thought_chain(chain_data)

        if trees_data:
            for tid, tree_data in trees_data.items():
                tree = ThoughtTree()
                tree.id = tree_data["id"]
                tree.root = deserialize_thought(tree_data["root"])
                tree.nodes = {nid: deserialize_thought(n) for nid, n in tree_data["nodes"].items()}
                tree.best_path = tree_data.get("best_path", [])
                tree.explored_paths = tree_data.get("explored_paths", [])
                tree.pruned_paths = tree_data.get("pruned_paths", [])
                self.reasoning.thought_trees[tid] = tree

        return True

    def _load_creative(self) -> bool:
        if not self.creative:
            return True

        concepts_data = self.backend.load("creative:concepts")
        blends_data = self.backend.load("creative:blends")

        if concepts_data:
            for name, concept_data in concepts_data.items():
                self.creative.concept_space[name] = {
                    "properties": concept_data["properties"],
                    "domain": concept_data["domain"],
                    "registered_at": datetime.fromisoformat(concept_data["registered_at"])
                }

        if blends_data:
            self.creative.blend_history = [
                {
                    "concept_a": b["concept_a"],
                    "concept_b": b["concept_b"],
                    "type": b["type"],
                    "timestamp": datetime.fromisoformat(b["timestamp"]),
                    "result": b["result"]
                }
                for b in blends_data
            ]

        return True

    def _load_verification(self) -> bool:
        if not self.verification:
            return True

        cache_data = self.backend.load("verification:cache")
        calibration_data = self.backend.load("verification:calibration")

        if cache_data:
            for key, result_data in cache_data.items():
                self.verification.verification_cache[key] = deserialize_verification_result(result_data)

        if calibration_data:
            self.verification.calibration_data = [
                (d["confidence"], d["correct"]) for d in calibration_data
            ]

        return True

    def _load_router(self) -> bool:
        if not self.router:
            return True

        perf_data = self.backend.load("router:performance")
        tool_servers = self.backend.load("router:tool_servers")
        total_selections = self.backend.load("router:total_selections")

        if perf_data:
            for key, perf_data_item in perf_data.items():
                self.router.performance[key] = deserialize_server_performance(perf_data_item)

        if tool_servers:
            self.router.tool_servers = {k: set(v) for k, v in tool_servers.items()}

        if total_selections:
            self.router.total_selections = total_selections

        return True

    def _load_orchestrator(self) -> bool:
        if not self.orchestrator:
            return True

        pipelines_data = self.backend.load("orchestrator:pipelines")
        history_data = self.backend.load("orchestrator:history")

        if pipelines_data:
            for pid, steps_data in pipelines_data.items():
                steps = [
                    PipelineStep(
                        id=s["id"],
                        tool=s["tool"],
                        params=s["params"],
                        depends_on=s.get("depends_on", []),
                        condition=s.get("condition"),
                        fallback=s.get("fallback"),
                        timeout=s.get("timeout", 30.0),
                        retries=s.get("retries", 1)
                    )
                    for s in steps_data
                ]
                self.orchestrator.pipelines[pid] = steps

        if history_data:
            self.orchestrator.execution_history = [
                PipelineResult(
                    pipeline_id=r["pipeline_id"],
                    step_results=r["step_results"],
                    success=r["success"],
                    error=r.get("error"),
                    execution_time=r["execution_time"],
                    completed_steps=r["completed_steps"],
                    failed_steps=r["failed_steps"]
                )
                for r in history_data
            ]

        return True

    def start_auto_save(self):
        """Start automatic periodic saving."""
        if self._auto_save_timer:
            self._auto_save_timer.cancel()

        def auto_save():
            self.save_all()
            self._auto_save_timer = threading.Timer(self.config.auto_save_interval, auto_save)
            self._auto_save_timer.daemon = True
            self._auto_save_timer.start()

        auto_save()

    def stop_auto_save(self):
        """Stop automatic saving."""
        if self._auto_save_timer:
            self._auto_save_timer.cancel()
            self._auto_save_timer = None

    def close(self):
        """Close persistence manager."""
        self.stop_auto_save()
        self.save_all(force=True)
        self.backend.close()

    def get_stats(self) -> Dict[str, Any]:
        """Get persistence statistics."""
        return {
            "backend": self.config.backend,
            "path": self.config.path,
            "dirty_components": list(self._dirty),
            "keys_count": len(self.backend.list_keys()),
            "auto_save_interval": self.config.auto_save_interval
        }


# ==================== CONVENIENCE FUNCTIONS ====================

def create_persistence_manager(
    backend: str = "json",
    path: str = "./cognitive_data",
    **kwargs
) -> PersistenceManager:
    """Create a persistence manager with default config."""
    config = PersistenceConfig(backend=backend, path=path, **kwargs)
    return PersistenceManager(config)


def save_cognitive_state(
    bridge,  # CognitiveMCPBridge
    backend: str = "json",
    path: str = "./cognitive_data"
) -> Dict[str, bool]:
    """Quick save of entire cognitive state."""
    pm = create_persistence_manager(backend, path)
    pm.register_components(
        memory=bridge.memory,
        reasoning=bridge.reasoning,
        creative=bridge.creative,
        verification=bridge.verification,
        router=bridge.router,
        orchestrator=bridge.orchestrator
    )
    results = pm.save_all(force=True)
    pm.close()
    return results


def load_cognitive_state(
    bridge,  # CognitiveMCPBridge
    backend: str = "json",
    path: str = "./cognitive_data"
) -> Dict[str, bool]:
    """Quick load of entire cognitive state."""
    pm = create_persistence_manager(backend, path)
    pm.register_components(
        memory=bridge.memory,
        reasoning=bridge.reasoning,
        creative=bridge.creative,
        verification=bridge.verification,
        router=bridge.router,
        orchestrator=bridge.orchestrator
    )
    results = pm.load_all()
    pm.close()
    return results