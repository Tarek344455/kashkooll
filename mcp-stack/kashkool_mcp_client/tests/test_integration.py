"""
Tests for the Integration layer and API server.
"""
import pytest
import asyncio
from unittest.mock import Mock, patch, AsyncMock
from datetime import datetime

from kashkool_mcp_client.integration import (
    CognitiveMCPBridge, MCPServerConfig, MCPProcessManager,
    get_bridge, investigate, solve, verify, search, scrape, youtube_transcript, think, pipeline, blend, status
)
from kashkool_mcp_client.config import (
    CognitiveMCPConfig, ServerConfig, LLMConfig, MemoryConfig,
    create_config, create_development_config, create_production_config,
    create_testing_config, create_minimal_config,
    ConfigManager, ConfigFormat
)
from kashkool_mcp_client.persistence import (
    PersistenceManager, PersistenceConfig, JSONFileBackend, SQLiteBackend,
    create_persistence_manager, save_cognitive_state, load_cognitive_state,
    serialize_memory_node, deserialize_memory_node,
    serialize_thought, deserialize_thought,
    serialize_thought_chain, deserialize_thought_chain,
    serialize_verification_result, deserialize_verification_result,
    serialize_server_performance, deserialize_server_performance
)
from kashkool_mcp_client.cognitive_core import (
    MemoryPalace, MemoryType, MemoryNode,
    Thought, ThoughtType, ThoughtChain,
    VerificationResult, VerificationLevel,
    ServerPerformance
)


# ==================== FIXTURES ====================

@pytest.fixture
def demo_llm():
    def llm(prompt: str) -> str:
        if "think step by step" in prompt.lower():
            return "STEP 1: First\nSTEP 2: Second\nSTEP 3: Conclusion"
        elif "generate" in prompt.lower() and "approach" in prompt.lower():
            return "APPROACH 1: First\nAPPROACH 2: Second"
        elif "sub-claim" in prompt.lower():
            return "SUB-CLAIM 1: First\nSUB-CLAIM 2: Second"
        elif "critique" in prompt.lower():
            return "CRITIQUE 1: Issue | SEVERITY: medium"
        elif "verdict" in prompt.lower():
            return "VERDICT: TRUE | CONFIDENCE: 0.8 | REASONING: Test"
        elif "structure:" in prompt.lower():
            return "STRUCTURE: Test"
        elif "analogy" in prompt.lower():
            return "ANALOGY 1: domain | mapping: test | insight: test"
        elif "mapping:" in prompt.lower():
            return "MAPPING: Test"
        elif "fundamental:" in prompt.lower():
            return "FUNDAMENTAL: Test"
        elif "solution:" in prompt.lower():
            return "SOLUTION: Test"
        elif "metaphorical insight:" in prompt.lower():
            return "METAPHORICAL INSIGHT: Test"
        elif "hybrid name:" in prompt.lower():
            return "HYBRID NAME: Test | PROPERTIES: {} | EMERGENT: [] | APPLICATIONS: []"
        elif "idea" in prompt.lower() and "diverse" in prompt.lower():
            return "IDEA 1: Test | DESCRIPTION: Test | NOVELTY: Test"
        elif "plan step" in prompt.lower():
            return "PLAN STEP 1: Step 1"
        elif "execution:" in prompt.lower():
            return "EXECUTION: Done"
        elif "decompose" in prompt.lower() and "assumption" in prompt.lower():
            return "ASSUMPTION 1: Test"
        elif "evidence" in prompt.lower():
            return "EVIDENCE 1: source | evidence | SUPPORTS | 0.9 | 0.9"
        elif "logical" in prompt.lower():
            return "PREMISES: test\nCONCLUSION: test\nFALLACIES: None\nVALIDITY: valid"
        elif "uncertainty" in prompt.lower():
            return "ALEATORIC: 0.1\nEPISTEMIC: 0.2\nOVERALL: 0.15\nFACTORS: test"
        elif "attack" in prompt.lower():
            return "ATTACK 1: Test attack"
        elif "defense" in prompt.lower():
            return "DEFENSE 1: invalid | counter | low"
        elif "causal" in prompt.lower():
            return "CAUSAL_CLAIM: yes\nCAUSE: X\nEFFECT: Y\nCONFOUNDERS: none\nREVERSE_CAUSALITY_POSSIBLE: no\nBRADFORD_HILL_SCORE: 8"
        return "Default"
    return llm


@pytest.fixture
def temp_dir(tmp_path):
    return tmp_path


# ==================== INTEGRATION TESTS ====================

class TestMCPProcessManager:
    def test_register_server(self):
        manager = MCPProcessManager()
        config = MCPServerConfig(
            name="test_server",
            command=["echo", "test"],
            tools=["tool1", "tool2"]
        )
        manager.register_server(config)
        assert "test_server" in manager.configs
        assert manager.configs["test_server"].tools == ["tool1", "tool2"]

    def test_get_stats_empty(self):
        manager = MCPProcessManager()
        stats = manager.get_stats()
        assert stats == {}


class TestCognitiveMCPBridge:
    def test_initialization(self, demo_llm):
        bridge = CognitiveMCPBridge(llm_call=demo_llm)
        assert bridge.llm_call == demo_llm
        assert bridge.memory is not None
        assert bridge.reasoning is not None
        assert bridge.creative is not None
        assert bridge.verification is not None
        assert bridge.router is not None
        assert bridge.orchestrator is not None
        assert len(bridge.process_manager.configs) > 0

    def test_register_core_concepts(self, demo_llm):
        bridge = CognitiveMCPBridge(llm_call=demo_llm)
        concepts = bridge.creative.concept_space
        assert "web_scraping" in concepts
        assert "search" in concepts
        assert "youtube_transcript" in concepts
        assert "reasoning" in concepts
        assert "memory" in concepts
        assert "verification" in concepts

    def test_investigate(self, demo_llm):
        bridge = CognitiveMCPBridge(llm_call=demo_llm)
        result = bridge.investigate("test topic", depth="quick")

        assert result["topic"] == "test topic"
        assert result["depth"] == "quick"
        assert "reasoning_chain" in result
        assert "creative_insights" in result
        assert "episode_id" in result

    def test_solve_problem(self, demo_llm):
        bridge = CognitiveMCPBridge(llm_call=demo_llm)
        result = bridge.solve_problem("test problem", method="first_principles")

        assert result["problem"] == "test problem"
        assert result["strategy"] == "first_principles"
        assert "conclusion" in result
        assert "confidence" in result

    def test_verify_claim(self, demo_llm):
        bridge = CognitiveMCPBridge(llm_call=demo_llm)
        result = bridge.verify_claim("test claim", VerificationLevel.BASIC)

        assert isinstance(result, VerificationResult)
        assert result.claim == "test claim"

    def test_blend_concepts(self, demo_llm):
        bridge = CognitiveMCPBridge(llm_call=demo_llm)
        result = bridge.blend_concepts("web_scraping", "reasoning", "hybrid")

        assert "result" in result
        assert result["concept_a"] == "web_scraping"
        assert result["concept_b"] == "reasoning"

    def test_search_web(self, demo_llm):
        bridge = CognitiveMCPBridge(llm_call=demo_llm)
        # This will fail without actual servers, but we can test the method exists
        assert hasattr(bridge, 'search_web')

    def test_get_system_status(self, demo_llm):
        bridge = CognitiveMCPBridge(llm_call=demo_llm)
        status = bridge.get_system_status()

        assert "servers" in status
        assert "router" in status
        assert "memory" in status
        assert "reasoning_chains" in status


# ==================== CONVENIENCE FUNCTION TESTS ====================

class TestConvenienceFunctions:
    def test_investigate(self, demo_llm):
        # These use global bridge, so we need to reset
        import kashkool_mcp_client.integration as integration
        integration._default_bridge = None

        result = investigate("test", depth="quick")
        assert "topic" in result

    def test_solve(self, demo_llm):
        import kashkool_mcp_client.integration as integration
        integration._default_bridge = None

        result = solve("test problem", method="auto")
        assert "problem" in result

    def test_verify(self, demo_llm):
        import kashkool_mcp_client.integration as integration
        integration._default_bridge = None

        result = verify("test claim", VerificationLevel.BASIC)
        assert isinstance(result, VerificationResult)

    def test_status(self, demo_llm):
        import kashkool_mcp_client.integration as integration
        integration._default_bridge = None

        result = status()
        assert "servers" in result


# ==================== CONFIG TESTS ====================

class TestConfig:
    def test_default_config(self):
        config = CognitiveMCPConfig.default()
        assert len(config.servers) > 0
        assert config.llm.provider == "demo"
        assert config.environment == "development"

    def test_create_development_config(self):
        config = create_development_config()
        assert config.environment == "development"
        assert config.debug is True
        assert config.logging.level == "DEBUG"

    def test_create_production_config(self):
        config = create_production_config()
        assert config.environment == "production"
        assert config.debug is False
        assert config.api.workers == 4

    def test_create_testing_config(self):
        config = create_testing_config()
        assert config.environment == "testing"
        assert config.reasoning.max_steps == 3

    def test_create_minimal_config(self):
        config = create_minimal_config()
        assert len(config.servers) == 2
        assert config.servers[0].name == "firecrawl"

    def test_config_save_load_json(self, temp_dir):
        config = CognitiveMCPConfig.default()
        config_path = temp_dir / "test_config.json"
        config.save(config_path, ConfigFormat.JSON)

        loaded = CognitiveMCPConfig.load(config_path, ConfigFormat.JSON)
        assert len(loaded.servers) == len(config.servers)
        assert loaded.llm.provider == config.llm.provider

    def test_config_save_load_yaml(self, temp_dir):
        config = CognitiveMCPConfig.default()
        config_path = temp_dir / "test_config.yaml"
        config.save(config_path, ConfigFormat.YAML)

        loaded = CognitiveMCPConfig.load(config_path, ConfigFormat.YAML)
        assert len(loaded.servers) == len(config.servers)

    def test_config_env_resolution(self, monkeypatch):
        monkeypatch.setenv("TEST_API_KEY", "secret123")
        config = CognitiveMCPConfig.default()
        config.servers[0].env["API_KEY"] = "${TEST_API_KEY}"

        resolved = config.resolve_env_vars()
        assert resolved.servers[0].env["API_KEY"] == "secret123"

    def test_config_validation(self):
        config = CognitiveMCPConfig.default()
        issues = config.validate()
        # Default config should be valid
        assert len(issues) == 0

    def test_config_manager(self):
        manager = ConfigManager()
        manager.load_from_env("NONEXISTENT_PREFIX_")
        # Should not crash

    def test_config_manager_watch(self):
        manager = ConfigManager()
        calls = []
        manager.watch(lambda c: calls.append(c.environment))
        manager.set("environment", "test")
        assert len(calls) == 1
        assert calls[0] == "test"

    def test_get_enabled_servers(self):
        config = CognitiveMCPConfig.default()
        enabled = config.get_enabled_servers()
        assert all(s.enabled for s in enabled)
        # Should be sorted by priority descending
        priorities = [s.priority for s in enabled]
        assert priorities == sorted(priorities, reverse=True)


# ==================== PERSISTENCE TESTS ====================

class TestPersistence:
    def test_json_backend(self, temp_dir):
        backend = JSONFileBackend(temp_dir / "json_data")
        backend.save("test_key", {"value": 123, "nested": {"a": 1}})
        loaded = backend.load("test_key")
        assert loaded["value"] == 123
        assert loaded["nested"]["a"] == 1

        keys = backend.list_keys()
        assert "test_key" in keys

        backend.delete("test_key")
        assert backend.load("test_key") is None

    def test_sqlite_backend(self, temp_dir):
        backend = SQLiteBackend(temp_dir / "test.db")
        backend.save("key1", {"data": "value1"})
        backend.save("key2", {"data": "value2"})

        assert backend.load("key1")["data"] == "value1"
        assert backend.load("key2")["data"] == "value2"

        keys = backend.list_keys()
        assert "key1" in keys
        assert "key2" in keys

        backend.delete("key1")
        assert backend.load("key1") is None

    def test_serialize_memory_node(self):
        node = MemoryNode(
            id="test123",
            type=MemoryType.SEMANTIC,
            content="Test content",
            embedding=[0.1, 0.2, 0.3],
            connections={"other": 0.8},
            access_count=5,
            last_accessed=datetime.now(),
            created_at=datetime.now(),
            importance=0.9,
            tags={"tag1", "tag2"},
            source="test",
            verified=True,
            verification_sources=["source1"]
        )

        serialized = serialize_memory_node(node)
        assert serialized["id"] == "test123"
        assert serialized["type"] == "semantic"
        assert serialized["content"] == "Test content"
        assert set(serialized["tags"]) == {"tag1", "tag2"}

        deserialized = deserialize_memory_node(serialized)
        assert deserialized.id == node.id
        assert deserialized.type == node.type
        assert deserialized.content == node.content
        assert deserialized.tags == node.tags

    def test_serialize_thought(self):
        thought = Thought(
            id="thought1",
            type=ThoughtType.INFERENCE,
            content="Test thought",
            confidence=0.8,
            evidence=["ev1", "ev2"],
            contradicts=["con1"],
            metadata={"key": "value"},
            timestamp=datetime.now(),
            parent_id="parent1",
            children_ids=["child1", "child2"]
        )

        serialized = serialize_thought(thought)
        assert serialized["id"] == "thought1"
        assert serialized["type"] == "inference"
        assert serialized["confidence"] == 0.8

        deserialized = deserialize_thought(serialized)
        assert deserialized.id == thought.id
        assert deserialized.type == thought.type
        assert deserialized.confidence == thought.confidence

    def test_serialize_thought_chain(self):
        chain = ThoughtChain(
            id="chain1",
            goal="Test goal",
            confidence=0.85,
            verified=True,
            verification_notes="All good"
        )
        thought = Thought(id="t1", type=ThoughtType.INFERENCE, content="Step 1", confidence=0.8)
        chain.add_thought(thought)
        chain.conclusion = thought

        serialized = serialize_thought_chain(chain)
        assert serialized["id"] == "chain1"
        assert serialized["goal"] == "Test goal"
        assert len(serialized["thoughts"]) == 1

        deserialized = deserialize_thought_chain(serialized)
        assert deserialized.id == chain.id
        assert deserialized.goal == chain.goal
        assert len(deserialized.thoughts) == 1

    def test_serialize_verification_result(self):
        result = VerificationResult(
            claim="Test claim",
            verified=True,
            confidence=0.9,
            level=VerificationLevel.CROSS_REFERENCE,
            sources=[{"type": "test", "result": True}],
            contradictions=[],
            uncertainty_factors=[],
            method="test"
        )

        serialized = serialize_verification_result(result)
        assert serialized["claim"] == "Test claim"
        assert serialized["verified"] is True
        assert serialized["level"] == VerificationLevel.CROSS_REFERENCE.value

        deserialized = deserialize_verification_result(serialized)
        assert deserialized.claim == result.claim
        assert deserialized.verified == result.verified
        assert deserialized.level == result.level

    def test_serialize_server_performance(self):
        perf = ServerPerformance(
            server_name="server1",
            tool="scrape",
            success_count=10,
            failure_count=2,
            total_latency=15.5,
            quality_scores=[0.8, 0.9, 0.85],
            last_used=datetime.now()
        )

        serialized = serialize_server_performance(perf)
        assert serialized["server_name"] == "server1"
        assert serialized["success_count"] == 10

        deserialized = deserialize_server_performance(serialized)
        assert deserialized.server_name == perf.server_name
        assert deserialized.success_count == perf.success_count
        assert deserialized.composite_score == perf.composite_score

    def test_persistence_manager(self, temp_dir, demo_llm):
        from kashkool_mcp_client.integration import CognitiveMCPBridge

        bridge = CognitiveMCPBridge(llm_call=demo_llm)

        config = PersistenceConfig(backend="json", path=str(temp_dir / "persist"))
        pm = PersistenceManager(config)
        pm.register_components(
            memory=bridge.memory,
            reasoning=bridge.reasoning,
            creative=bridge.creative,
            verification=bridge.verification,
            router=bridge.router,
            orchestrator=bridge.orchestrator
        )

        # Store some data
        bridge.memory.store("Test fact", MemoryType.SEMANTIC, {"test"}, 0.8)

        # Save
        results = pm.save_all(force=True)
        assert all(results.values())

        # Create new bridge and load
        bridge2 = CognitiveMCPBridge(llm_call=demo_llm)
        pm2 = PersistenceManager(config)
        pm2.register_components(
            memory=bridge2.memory,
            reasoning=bridge2.reasoning,
            creative=bridge2.creative,
            verification=bridge2.verification,
            router=bridge2.router,
            orchestrator=bridge2.orchestrator
        )

        load_results = pm2.load_all()
        assert all(load_results.values())

        # Check memory was restored
        assert len(bridge2.memory._all_nodes) > 0

    def test_convenience_save_load(self, temp_dir, demo_llm):
        from kashkool_mcp_client.integration import CognitiveMCPBridge

        bridge = CognitiveMCPBridge(llm_call=demo_llm)
        bridge.memory.store("Test", MemoryType.SEMANTIC, {"test"}, 0.8)

        results = save_cognitive_state(bridge, "json", str(temp_dir / "save"))
        assert all(results.values())

        bridge2 = CognitiveMCPBridge(llm_call=demo_llm)
        results = load_cognitive_state(bridge2, "json", str(temp_dir / "save"))
        assert all(results.values())


# ==================== ADVANCED VERIFICATION TESTS ====================

class TestAdvancedVerification:
    @pytest.mark.asyncio
    async def test_consensus_verifier(self, demo_llm):
        from kashkool_mcp_client.advanced_verification import (
            ConsensusVerifier, LLMEvidenceGatherer, VerificationContext, VerificationStrategy
        )

        gatherer = LLMEvidenceGatherer(demo_llm)
        verifier = ConsensusVerifier([gatherer])

        context = VerificationContext(
            claim="Test claim",
            strategy=VerificationStrategy.CONSENSUS,
            min_sources=1
        )

        report = await verifier.verify("Test claim", context)
        assert isinstance(report.verified, bool)
        assert 0 <= report.confidence <= 1
        assert len(report.evidence) > 0

    @pytest.mark.asyncio
    async def test_logical_consistency_verifier(self, demo_llm):
        from kashkool_mcp_client.advanced_verification import (
            LogicalConsistencyVerifier, VerificationContext, VerificationStrategy
        )

        verifier = LogicalConsistencyVerifier(demo_llm)
        context = VerificationContext(claim="Test claim", strategy=VerificationStrategy.LOGICAL_CONSISTENCY)

        report = await verifier.verify("Test claim", context)
        assert isinstance(report.verified, bool)
        assert "validity" in report.metadata or report.logical_issues is not None

    @pytest.mark.asyncio
    async def test_adversarial_verifier(self, demo_llm):
        from kashkool_mcp_client.advanced_verification import (
            AdversarialVerifier, VerificationContext, VerificationStrategy
        )

        verifier = AdversarialVerifier(demo_llm)
        context = VerificationContext(claim="Test claim", strategy=VerificationStrategy.ADVERSARIAL)

        report = await verifier.verify("Test claim", context)
        assert isinstance(report.verified, bool)
        assert "attacks" in report.metadata

    @pytest.mark.asyncio
    async def test_causal_verifier(self, demo_llm):
        from kashkool_mcp_client.advanced_verification import (
            CausalVerifier, VerificationContext, VerificationStrategy
        )

        verifier = CausalVerifier(demo_llm)
        context = VerificationContext(claim="X causes Y", strategy=VerificationStrategy.CAUSAL)

        report = await verifier.verify("X causes Y", context)
        assert isinstance(report.verified, bool)
        assert "causal_claim" in report.metadata

    @pytest.mark.asyncio
    async def test_orchestrator(self, demo_llm):
        from kashkool_mcp_client.advanced_verification import (
            AdvancedVerificationOrchestrator, VerificationStrategy
        )

        orchestrator = AdvancedVerificationOrchestrator(demo_llm)
        result = await orchestrator.verify(
            "Test claim",
            strategies=[
                VerificationStrategy.CONSENSUS,
                VerificationStrategy.LOGICAL_CONSISTENCY,
                VerificationStrategy.ADVERSARIAL
            ]
        )

        assert "claim" in result
        assert "individual_results" in result
        assert "aggregate" in result
        assert "verified" in result["aggregate"]
        assert "confidence" in result["aggregate"]


# ==================== RUN TESTS ====================

if __name__ == "__main__":
    pytest.main([__file__, "-v"])