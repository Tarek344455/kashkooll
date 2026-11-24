"""
Tests for the Cognitive Core components.
"""
import pytest
import asyncio
from datetime import datetime

from kashkool_mcp_client.cognitive_core import (
    MemoryPalace, MemoryType, MemoryNode,
    ReasoningEngine, ReasoningContext, ReasoningStrategy, Thought, ThoughtType, ThoughtChain, ThoughtTree,
    CreativeSynthesis,
    VerificationCore, VerificationLevel, VerificationResult,
    AdaptiveRouter, ServerPerformance,
    ToolOrchestrator, PipelineStep, PipelineResult
)


# ==================== FIXTURES ====================

@pytest.fixture
def demo_llm():
    def llm(prompt: str) -> str:
        prompt_lower = prompt.lower()
        if "think step by step" in prompt_lower:
            return "STEP 1: First step\nSTEP 2: Second step\nSTEP 3: Conclusion"
        elif "generate" in prompt_lower and "approach" in prompt_lower:
            return "APPROACH 1: First approach\nAPPROACH 2: Second approach"
        elif "sub-claim" in prompt_lower:
            return "SUB-CLAIM 1: First sub-claim\nSUB-CLAIM 2: Second sub-claim"
        elif "critique" in prompt_lower:
            return "CRITIQUE 1: Issue found | SEVERITY: medium"
        elif "verdict" in prompt_lower:
            return "VERDICT: TRUE | CONFIDENCE: 0.8 | REASONING: Test reasoning"
        elif "generate 3-5 analogies" in prompt_lower:
            return "ANALOGY 1: biology | mapping: nature solves problems | insight: biomimicry\nANALOGY 2: physics | mapping: energy minimization | insight: least action"
        elif "structure:" in prompt_lower:
            return "STRUCTURE: Test structure"
        elif "mapping:" in prompt_lower:
            return "MAPPING: Test mapping"
        elif "fundamental:" in prompt_lower:
            return "FUNDAMENTAL: Test fundamental"
        elif "solution:" in prompt_lower:
            return "SOLUTION: Test solution"
        elif "metaphorical insight:" in prompt_lower:
            return "METAPHORICAL INSIGHT: Test insight"
        elif "hybrid name:" in prompt_lower:
            return "HYBRID NAME: TestHybrid | PROPERTIES: {} | EMERGENT: [] | APPLICATIONS: []"
        elif "idea" in prompt_lower and "diverse" in prompt_lower:
            return "IDEA 1: TestIdea | DESCRIPTION: Test | NOVELTY: Test"
        elif "plan step" in prompt_lower:
            return "PLAN STEP 1: Step 1\nPLAN STEP 2: Step 2"
        elif "execution:" in prompt_lower:
            return "EXECUTION: Done"
        elif "decompose" in prompt_lower and "assumption" in prompt_lower:
            return "ASSUMPTION 1: Test assumption"
        elif "assumption" in prompt_lower and "hidden" in prompt_lower:
            return "ASSUMPTION 1: Things fall because of gravity\nASSUMPTION 2: Gravity is a force"
        elif "is this assumption necessarily true" in prompt_lower:
            return "FUNDAMENTAL: Mass curves spacetime"
        elif "create a pipeline" in prompt_lower:
            return "STEP 1: search_dummy | {\"query\": \"test\"} | []\nSTEP 2: scrape_dummy | {\"url\": \"{{step1.url}}\"} | [\"step1\"]"
        return "Default response"
    return llm


@pytest.fixture
def memory():
    return MemoryPalace(capacity=100)


@pytest.fixture
def reasoning_engine(memory):
    return ReasoningEngine(memory)


@pytest.fixture
def creative_synthesis(memory):
    return CreativeSynthesis(memory)


@pytest.fixture
def verification_core(memory):
    return VerificationCore(memory)


@pytest.fixture
def adaptive_router():
    router = AdaptiveRouter()
    router.register_server("server1", ["scrape", "search"])
    router.register_server("server2", ["scrape"])
    return router


@pytest.fixture
def tool_orchestrator():
    def dummy_tool(params, server=None):
        return {"result": "success", "quality": 0.8}
    return ToolOrchestrator(tool_executors={"dummy": dummy_tool})


# ==================== MEMORY TESTS ====================

class TestMemoryPalace:
    def test_store_semantic(self, memory):
        node_id = memory.store(
            content="Test fact",
            mem_type=MemoryType.SEMANTIC,
            tags={"test", "fact"},
            importance=0.8,
            source="test"
        )
        assert node_id is not None
        assert node_id in memory.semantic

    def test_store_episodic(self, memory):
        node_id = memory.store(
            content={"event": "test", "data": [1, 2, 3]},
            mem_type=MemoryType.EPISODIC,
            tags={"event"},
            importance=0.9
        )
        assert node_id in memory.episodic

    def test_store_procedural(self, memory):
        node_id = memory.store(
            content={"pattern": "test -> result", "success_rate": 0.95},
            mem_type=MemoryType.PROCEDURAL,
            tags={"procedure"},
            importance=0.85
        )
        assert node_id in memory.procedural

    def test_recall_by_query(self, memory):
        memory.store("Python is a programming language", MemoryType.SEMANTIC, {"python", "language"}, 0.8)
        memory.store("Java is also a language", MemoryType.SEMANTIC, {"java", "language"}, 0.7)

        results = memory.recall(query="programming language", top_k=5)
        assert len(results) > 0
        assert any("Python" in str(r.content) for r in results)

    def test_recall_by_tags(self, memory):
        memory.store("Tagged content", MemoryType.SEMANTIC, {"important", "tagged"}, 0.9)
        memory.store("Untagged content", MemoryType.SEMANTIC, {"other"}, 0.5)

        results = memory.recall(tags={"tagged"}, top_k=10)
        assert len(results) == 1
        assert "tagged" in results[0].tags

    def test_recall_by_type(self, memory):
        memory.store("Semantic fact", MemoryType.SEMANTIC, {"fact"}, 0.8)
        memory.store("Episodic event", MemoryType.EPISODIC, {"event"}, 0.8)

        semantic_results = memory.recall(mem_type=MemoryType.SEMANTIC, top_k=10)
        episodic_results = memory.recall(mem_type=MemoryType.EPISODIC, top_k=10)

        assert all(r.type == MemoryType.SEMANTIC for r in semantic_results)
        assert all(r.type == MemoryType.EPISODIC for r in episodic_results)

    def test_associate(self, memory):
        id1 = memory.store("First", MemoryType.SEMANTIC, {"a"}, 0.8)
        id2 = memory.store("Second", MemoryType.SEMANTIC, {"b"}, 0.7)

        memory.associate(id1, id2, 0.9)

        node1 = memory._all_nodes[id1]
        node2 = memory._all_nodes[id2]
        assert node1.connections[id2] == 0.9
        assert node2.connections[id1] == 0.9

    def test_consolidate(self, memory):
        id1 = memory.store("Important", MemoryType.SEMANTIC, {"important"}, 0.9, verified=True)
        id2 = memory.store("Unimportant", MemoryType.SEMANTIC, {"trivial"}, 0.1)

        memory.consolidate()

        # Verified memory should be strengthened
        assert memory._all_nodes[id1].importance >= 0.9
        # Unimportant memory should not be strengthened (stays at or below original)
        assert memory._all_nodes[id2].importance <= 0.1

    def test_capacity_enforcement(self, memory):
        # Fill beyond capacity
        for i in range(150):
            memory.store(f"Item {i}", MemoryType.SEMANTIC, {"item"}, 0.5)

        assert len(memory._all_nodes) <= memory.capacity

    def test_get_stats(self, memory):
        memory.store("Test", MemoryType.SEMANTIC, {"test"}, 0.8)
        memory.store("Test2", MemoryType.EPISODIC, {"test"}, 0.7)

        stats = memory.get_stats()
        assert stats["total"] == 2
        assert stats["semantic"] == 1
        assert stats["episodic"] == 1
        assert stats["procedural"] == 0


# ==================== REASONING TESTS ====================

class TestReasoningEngine:
    def test_chain_of_thought(self, reasoning_engine, demo_llm):
        context = ReasoningContext(
            problem="Test problem",
            strategy=ReasoningStrategy.CHAIN_OF_THOUGHT,
            max_steps=3,
            require_verification=True
        )
        chain = reasoning_engine.reason(context, demo_llm)

        assert isinstance(chain, ThoughtChain)
        assert len(chain.thoughts) > 0
        assert chain.conclusion is not None
        assert 0 <= chain.confidence <= 1

    def test_tree_of_thoughts(self, reasoning_engine, demo_llm):
        context = ReasoningContext(
            problem="Test problem",
            strategy=ReasoningStrategy.TREE_OF_THOUGHTS,
            max_steps=4,
            max_branches=2
        )
        chain = reasoning_engine.reason(context, demo_llm)

        assert isinstance(chain, ThoughtChain)
        assert chain.confidence >= 0

    def test_first_principles(self, reasoning_engine, demo_llm):
        context = ReasoningContext(
            problem="Why do things fall?",
            strategy=ReasoningStrategy.FIRST_PRINCIPLES,
            max_steps=5
        )
        chain = reasoning_engine.reason(context, demo_llm)

        assert isinstance(chain, ThoughtChain)
        # Should have assumption thoughts
        assumption_thoughts = [t for t in chain.thoughts if t.metadata.get("type") == "assumption"]
        assert len(assumption_thoughts) > 0

    def test_analogical_reasoning(self, reasoning_engine, demo_llm):
        context = ReasoningContext(
            problem="How to solve this like nature does?",
            strategy=ReasoningStrategy.ANALOGICAL,
            max_steps=4
        )
        chain = reasoning_engine.reason(context, demo_llm)

        assert isinstance(chain, ThoughtChain)
        analogy_thoughts = [t for t in chain.thoughts if t.type == ThoughtType.ANALOGY]
        assert len(analogy_thoughts) > 0

    def test_self_consistency(self, reasoning_engine, demo_llm):
        context = ReasoningContext(
            problem="Test problem",
            strategy=ReasoningStrategy.SELF_CONSISTENCY,
            max_steps=3,
            metadata={"num_samples": 3}
        )
        chain = reasoning_engine.reason(context, demo_llm)

        assert isinstance(chain, ThoughtChain)
        assert chain.verified is True
        assert "consensus" in chain.verification_notes.lower()

    def test_react(self, reasoning_engine, demo_llm):
        def dummy_tool(**kwargs):
            return "Tool result"

        context = ReasoningContext(
            problem="Test problem requiring action",
            strategy=ReasoningStrategy.REACT,
            max_steps=3,
            tools={"dummy": dummy_tool}
        )
        chain = reasoning_engine.reason(context, demo_llm)

        assert isinstance(chain, ThoughtChain)

    def test_plan_and_solve(self, reasoning_engine, demo_llm):
        context = ReasoningContext(
            problem="Plan and solve this",
            strategy=ReasoningStrategy.PLAN_AND_SOLVE,
            max_steps=4
        )
        chain = reasoning_engine.reason(context, demo_llm)

        assert isinstance(chain, ThoughtChain)
        plan_thoughts = [t for t in chain.thoughts if t.metadata.get("plan_step")]
        assert len(plan_thoughts) > 0


# ==================== CREATIVE SYNTHESIS TESTS ====================

class TestCreativeSynthesis:
    def test_register_concept(self, creative_synthesis):
        creative_synthesis.register_concept(
            "test_concept",
            {"property1": "value1", "property2": 42},
            "test_domain"
        )
        assert "test_concept" in creative_synthesis.concept_space

    def test_property_mapping_blend(self, creative_synthesis):
        creative_synthesis.register_concept("A", {"color": "red", "size": "large"}, "domain1")
        creative_synthesis.register_concept("B", {"color": "blue", "shape": "round"}, "domain2")

        result = creative_synthesis.blend("A", "B", "property_mapping")
        assert result["result"]["method"] == "property_mapping"
        assert "mapped_properties" in result["result"]

    def test_hybrid_blend(self, creative_synthesis, demo_llm):
        creative_synthesis.register_concept("A", {"p1": "v1"}, "d1")
        creative_synthesis.register_concept("B", {"p2": "v2"}, "d2")

        result = creative_synthesis.blend("A", "B", "hybrid", demo_llm)
        assert result["result"]["method"] == "hybrid"
        assert "name" in result["result"]

    def test_divergent_generation(self, creative_synthesis, demo_llm):
        creative_synthesis.register_concept("seed", {"prop": "val"}, "domain")

        ideas = creative_synthesis.divergent_generation("seed", num_ideas=3, llm_call=demo_llm)
        assert len(ideas) <= 3
        assert all("name" in idea for idea in ideas)


# ==================== VERIFICATION TESTS ====================

class TestVerificationCore:
    def test_basic_verify(self, verification_core, demo_llm):
        result = verification_core.verify(
            "Test claim",
            VerificationLevel.BASIC,
            llm_call=demo_llm
        )
        assert isinstance(result, VerificationResult)
        assert result.level == VerificationLevel.BASIC

    def test_cross_reference_verify(self, verification_core, demo_llm):
        result = verification_core.verify(
            "Test claim",
            VerificationLevel.CROSS_REFERENCE,
            llm_call=demo_llm
        )
        assert isinstance(result, VerificationResult)
        assert result.level == VerificationLevel.CROSS_REFERENCE
        assert len(result.sources) > 0

    def test_deep_verify(self, verification_core, demo_llm):
        result = verification_core.verify(
            "Complex claim with multiple parts",
            VerificationLevel.DEEP,
            llm_call=demo_llm
        )
        assert isinstance(result, VerificationResult)
        assert result.level == VerificationLevel.DEEP

    def test_calibration(self, verification_core):
        verification_core.calibrate(0.8, True)
        verification_core.calibrate(0.9, True)
        verification_core.calibrate(0.7, False)

        cal = verification_core.get_calibration_curve()
        assert cal["samples"] == 3
        assert 0 <= cal["ece"] <= 1

    def test_hallucination_detection(self, verification_core, demo_llm):
        result = verification_core.detect_hallucination(
            "Generated text with claim",
            "Source material without that claim",
            demo_llm
        )
        assert "hallucination_count" in result
        assert "clean" in result


# ==================== ADAPTIVE ROUTER TESTS ====================

class TestAdaptiveRouter:
    def test_register_server(self, adaptive_router):
        assert "scrape" in adaptive_router.tool_servers
        assert "search" in adaptive_router.tool_servers
        assert "server1" in adaptive_router.tool_servers["scrape"]
        assert "server2" in adaptive_router.tool_servers["scrape"]

    def test_select_server(self, adaptive_router):
        server = adaptive_router.select_server("scrape")
        assert server in ["server1", "server2"]

        # Only one server for search
        server = adaptive_router.select_server("search")
        assert server == "server1"

    def test_record_result(self, adaptive_router):
        adaptive_router.record_result("server1", "scrape", True, 1.0, 0.9)
        adaptive_router.record_result("server1", "scrape", True, 1.2, 0.8)
        adaptive_router.record_result("server2", "scrape", False, 5.0, 0.3)

        ranking = adaptive_router.get_ranking("scrape")
        assert len(ranking) == 2
        # server1 should rank higher
        assert ranking[0][0] == "server1"

    def test_get_stats(self, adaptive_router):
        stats = adaptive_router.get_stats()
        assert "tools" in stats
        assert "total_selections" in stats


# ==================== TOOL ORCHESTRATOR TESTS ====================

class TestToolOrchestrator:
    def test_define_pipeline(self, tool_orchestrator):
        steps = [
            PipelineStep(id="step1", tool="dummy", params={}, depends_on=[]),
            PipelineStep(id="step2", tool="dummy", params={}, depends_on=["step1"])
        ]
        tool_orchestrator.define_pipeline("test_pipeline", steps)
        assert "test_pipeline" in tool_orchestrator.pipelines

    def test_execute_pipeline(self, tool_orchestrator):
        steps = [
            PipelineStep(id="step1", tool="dummy", params={"input": "test"}, depends_on=[]),
            PipelineStep(id="step2", tool="dummy", params={"prev": "{{step1.result}}"}, depends_on=["step1"])
        ]
        tool_orchestrator.define_pipeline("test_pipeline", steps)

        result = tool_orchestrator.execute_pipeline("test_pipeline")
        assert result.success is True
        assert "step1" in result.completed_steps
        assert "step2" in result.completed_steps

    def test_execute_pipeline_with_failure(self, tool_orchestrator):
        def failing_tool(params, server=None):
            raise Exception("Tool failed")

        orchestrator = ToolOrchestrator(tool_executors={"fail": failing_tool})
        steps = [PipelineStep(id="step1", tool="fail", params={}, depends_on=[])]
        orchestrator.define_pipeline("fail_pipeline", steps)

        result = orchestrator.execute_pipeline("fail_pipeline")
        assert result.success is False
        assert "step1" in result.failed_steps

    def test_param_resolution(self, tool_orchestrator):
        steps = [
            PipelineStep(id="step1", tool="dummy", params={}, depends_on=[]),
            PipelineStep(id="step2", tool="dummy", params={"ref": "{{step1.result}}"}, depends_on=["step1"])
        ]
        tool_orchestrator.define_pipeline("resolve_pipeline", steps)

        # This tests the internal _resolve_params method
        outputs = {"step1": {"result": "test_value"}}
        resolved = tool_orchestrator._resolve_params({"ref": "{{step1.result}}"}, outputs)
        assert resolved["ref"] == "test_value"

    def test_create_dynamic_pipeline(self, tool_orchestrator, demo_llm):
        steps = tool_orchestrator.create_dynamic_pipeline(
            "Search and scrape a website",
            ["search_dummy", "scrape_dummy"],
            demo_llm,
            max_steps=3
        )
        assert len(steps) > 0
        assert all(isinstance(s, PipelineStep) for s in steps)


# ==================== INTEGRATION TESTS ====================

class TestIntegration:
    def test_full_cognitive_cycle(self, demo_llm):
        """Test a complete cognitive cycle: store -> reason -> verify -> create."""
        memory = MemoryPalace()
        reasoning = ReasoningEngine(memory)
        creative = CreativeSynthesis(memory)
        verification = VerificationCore(memory)

        # Store knowledge
        mem_id = memory.store(
            "Scrapers need to handle dynamic content",
            MemoryType.SEMANTIC,
            {"scraping", "dynamic"},
            0.9
        )

        # Reason about problem
        context = ReasoningContext(
            problem="How to handle dynamic content in scraping?",
            strategy=ReasoningStrategy.CHAIN_OF_THOUGHT,
            max_steps=3,
            require_verification=True
        )
        chain = reasoning.reason(context, demo_llm)

        # Verify conclusion
        if chain.conclusion:
            result = verification.verify(
                chain.conclusion.content,
                VerificationLevel.CROSS_REFERENCE,
                llm_call=demo_llm
            )
            assert isinstance(result, VerificationResult)

        # Creative synthesis
        creative.register_concept("scraper", {"handles": "dynamic"}, "engineering")
        creative.register_concept("browser", {"renders": "javascript"}, "engineering")
        blend = creative.blend("scraper", "browser", "hybrid", demo_llm)
        assert "result" in blend

    def test_memory_reasoning_integration(self, memory, reasoning_engine, demo_llm):
        """Test that reasoning can use memory."""
        # Store relevant memory
        memory.store(
            "Firecrawl handles JavaScript well",
            MemoryType.SEMANTIC,
            {"firecrawl", "javascript"},
            0.9
        )

        # Reason with memory
        context = ReasoningContext(
            problem="Which scraper for JavaScript sites?",
            strategy=ReasoningStrategy.CHAIN_OF_THOUGHT,
            max_steps=3,
            memory=memory
        )
        chain = reasoning_engine.reason(context, demo_llm)

        # Memory should be accessible during reasoning
        assert len(chain.thoughts) > 0


# ==================== RUN TESTS ====================

if __name__ == "__main__":
    pytest.main([__file__, "-v"])