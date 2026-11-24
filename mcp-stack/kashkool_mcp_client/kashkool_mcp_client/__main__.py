"""
Kashkool Cognitive MCP Client — Main Entry Point
Demonstrates the full cognitive architecture in action.
"""
import asyncio
import json
import os
import sys
from typing import Optional

# Add parent to path for imports
sys.path.insert(0, str(__file__).replace("__main__.py", ""))

from .cognitive_core import (
    MemoryPalace, MemoryType,
    ReasoningEngine, ReasoningContext, ReasoningStrategy,
    CreativeSynthesis,
    VerificationCore, VerificationLevel,
    AdaptiveRouter,
    ToolOrchestrator, PipelineStep
)
from .integration import (
    CognitiveMCPBridge, MCPServerConfig, get_bridge,
    investigate, solve, verify, search, scrape, youtube_transcript, think, pipeline, blend, status
)
from .models import ScrapeResult, SearchResult, TranscriptResult, PDFResult, ThinkResult


def demo_llm(prompt: str) -> str:
    """Demo LLM that simulates reasoning for testing without API keys."""
    prompt_lower = prompt.lower()
    
    # Simulate different types of responses
    if "think step by step" in prompt_lower or "chain of thought" in prompt_lower:
        return """STEP 1: First, I need to understand the problem structure.
STEP 2: Identify the key components and relationships.
STEP 3: Apply relevant principles or patterns.
STEP 4: Synthesize the solution.
STEP 5: Verify the result makes sense."""
    
    elif "generate" in prompt_lower and "approach" in prompt_lower:
        return """APPROACH 1: Direct analysis using first principles
APPROACH 2: Analogical reasoning from similar domains
APPROACH 3: Decomposition into sub-problems"""
    
    elif "sub-claim" in prompt_lower:
        return """SUB-CLAIM 1: The core assertion can be broken into atomic facts
SUB-CLAIM 2: Each fact can be independently verified
SUB-CLAIM 3: The combination of verified facts supports the conclusion"""
    
    elif "critique" in prompt_lower:
        return """CRITIQUE 1: Step 2 assumes X without evidence | SEVERITY: medium
CRITIQUE 2: Step 4 has a logical gap between premise and conclusion | SEVERITY: high"""
    
    elif "verdict" in prompt_lower:
        return "VERDICT: TRUE | CONFIDENCE: 0.85 | REASONING: Well-established fact supported by multiple sources"
    
    elif "structure:" in prompt_lower:
        return "STRUCTURE: This is a pattern matching problem with hierarchical decomposition"
    
    elif "analogy" in prompt_lower:
        return """ANALOGY 1: biology | mapping: neural networks ~ biological neurons | insight: learning via weight adjustment
ANALOGY 2: physics | mapping: gradient descent ~ ball rolling down hill | insight: local minima traps
ANALOGY 3: engineering | mapping: backpropagation ~ feedback control systems | insight: stability requires damping"""
    
    elif "mapping:" in prompt_lower:
        return "MAPPING: The backpropagation algorithm mirrors how biological systems adjust synaptic strengths based on error signals"
    
    elif "fundamental:" in prompt_lower:
        return "FUNDAMENTAL: At the core, this is about information transformation under constraints"
    
    elif "solution:" in prompt_lower:
        return "SOLUTION: By decomposing to information theory fundamentals, we can reconstruct the optimal approach"
    
    elif "metaphorical insight:" in prompt_lower:
        return "METAPHORICAL INSIGHT: Web scraping is like archaeology - you dig through layers (HTML), filter artifacts (data), and reconstruct the story (insights)"
    
    elif "hybrid name:" in prompt_lower:
        return "HYBRID NAME: CognitiveScraper | PROPERTIES: {\"reasoning\": true, \"adaptive\": true, \"self_verifying\": true} | EMERGENT: [\"learns site patterns\", \"auto-heals selectors\"] | APPLICATIONS: [\"research\", \"monitoring\", \"competitive_intel\"]"
    
    elif "idea" in prompt_lower and "diverse" in prompt_lower:
        return """IDEA 1: SelfHealingScraper | DESCRIPTION: Scraper that learns and adapts to site changes automatically | NOVELTY: Uses reasoning to infer new selectors
IDEA 2: VerifiedDataPipeline | DESCRIPTION: Pipeline that cross-references every claim across sources | NOVELTY: Built-in epistemic verification
IDEA 3: AnalogicalResearcher | DESCRIPTION: Finds solutions by mapping problems to solved domains | NOVELTY: Creative transfer not just retrieval"""
    
    elif "plan step" in prompt_lower:
        return "PLAN STEP 1: Define the problem precisely\nPLAN STEP 2: Gather relevant information\nPLAN STEP 3: Apply reasoning strategy\nPLAN STEP 4: Verify and refine"
    
    elif "execution:" in prompt_lower:
        return "EXECUTION: Completed step with result: gathered 10 sources, extracted key facts"
    
    elif "decompose" in prompt_lower and "assumption" in prompt_lower:
        return """ASSUMPTION 1: The standard approach is optimal
ASSUMPTION 2: All sources are equally reliable
ASSUMPTION 3: The problem structure matches known patterns"""
    
    else:
        return f"[Simulated LLM response for: {prompt[:80]}...]"


def run_cognitive_demo():
    """Run a comprehensive demo of the cognitive architecture."""
    print("=" * 70)
    print("🧠 KASHKOOL COGNITIVE MCP ARCHITECTURE — DEMO")
    print("=" * 70)
    
    # Initialize bridge with demo LLM
    bridge = CognitiveMCPBridge(llm_call=demo_llm)
    
    print("\n📦 Starting servers...")
    server_status = bridge.start_all_servers()
    for name, ok in server_status.items():
        print(f"  {'✅' if ok else '❌'} {name}")
    
    print("\n" + "=" * 70)
    print("1️⃣  MEMORY PALACE DEMO")
    print("=" * 70)
    
    # Store some memories
    mem_id1 = bridge.memory.store(
        content="Firecrawl excels at JavaScript-heavy sites with anti-bot protection",
        mem_type=MemoryType.SEMANTIC,
        tags={"scraping", "firecrawl", "javascript"},
        importance=0.8,
        source="experience"
    )
    print(f"  Stored semantic memory: {mem_id1}")
    
    mem_id2 = bridge.memory.store(
        content="Investigated e-commerce price monitoring for client project",
        mem_type=MemoryType.EPISODIC,
        tags={"project", "ecommerce", "monitoring"},
        importance=0.9,
        source="work"
    )
    print(f"  Stored episodic memory: {mem_id2}")
    
    mem_id3 = bridge.memory.store(
        content={"pattern": "scrape -> verify -> store", "success_rate": 0.92},
        mem_type=MemoryType.PROCEDURAL,
        tags={"procedure", "pipeline"},
        importance=0.85,
        source="learned"
    )
    print(f"  Stored procedural memory: {mem_id3}")
    
    # Recall
    results = bridge.memory.recall(query="scraping", top_k=3)
    print(f"  Recalled {len(results)} memories for 'scraping'")
    for r in results:
        print(f"    - [{r.type.value}] {str(r.content)[:60]}... (importance: {r.importance:.2f})")
    
    print("\n" + "=" * 70)
    print("2️⃣  REASONING ENGINE DEMO")
    print("=" * 70)
    
    # Chain of Thought
    print("\n  📝 Chain-of-Thought:")
    context = ReasoningContext(
        problem="How to build a robust web scraper that handles dynamic content?",
        strategy=ReasoningStrategy.CHAIN_OF_THOUGHT,
        max_steps=5,
        require_verification=True
    )
    chain = bridge.reasoning.reason(context, demo_llm)
    print(f"    Steps: {len(chain.thoughts)}")
    print(f"    Conclusion: {chain.conclusion.content[:80] if chain.conclusion else 'None'}...")
    print(f"    Confidence: {chain.confidence:.2f}")
    print(f"    Verified: {chain.verified}")
    
    # Tree of Thoughts
    print("\n  🌳 Tree-of-Thoughts:")
    context2 = ReasoningContext(
        problem="Best architecture for a self-healing scraper?",
        strategy=ReasoningStrategy.TREE_OF_THOUGHTS,
        max_steps=6,
        max_branches=3
    )
    chain2 = bridge.reasoning.reason(context2, demo_llm)
    print(f"    Best path length: {len(chain2.best_path)}")
    print(f"    Confidence: {chain2.confidence:.2f}")
    
    # First Principles
    print("\n  ⚛️  First Principles:")
    context3 = ReasoningContext(
        problem="Why do scrapers break when sites change?",
        strategy=ReasoningStrategy.FIRST_PRINCIPLES,
        max_steps=8
    )
    chain3 = bridge.reasoning.reason(context3, demo_llm)
    print(f"    Conclusion: {chain3.conclusion.content[:80] if chain3.conclusion else 'None'}...")
    print(f"    Confidence: {chain3.confidence:.2f}")
    
    # Analogical
    print("\n  🔄 Analogical Reasoning:")
    context4 = ReasoningContext(
        problem="How to make scrapers resilient?",
        strategy=ReasoningStrategy.ANALOGICAL,
        max_steps=6
    )
    chain4 = bridge.reasoning.reason(context4, demo_llm)
    print(f"    Analogies explored: {len([t for t in chain4.thoughts if t.type.value == 'analogy'])}")
    print(f"    Conclusion: {chain4.conclusion.content[:80] if chain4.conclusion else 'None'}...")
    
    print("\n" + "=" * 70)
    print("3️⃣  CREATIVE SYNTHESIS DEMO")
    print("=" * 70)
    
    # Concept blending
    print("\n  🎨 Concept Blending (Hybrid):")
    blend_result = bridge.creative.blend("web_scraping", "reasoning", "hybrid", demo_llm)
    print(f"    Hybrid name: {blend_result['result'].get('name', 'N/A')}")
    print(f"    Emergent properties: {blend_result['result'].get('emergent_properties', [])}")
    print(f"    Applications: {blend_result['result'].get('applications', [])}")
    
    # Divergent generation
    print("\n  💡 Divergent Generation:")
    ideas = bridge.creative.divergent_generation(
        "web_scraping",
        num_ideas=3,
        constraints=["novel", "practical", "uses reasoning"],
        llm_call=demo_llm
    )
    for i, idea in enumerate(ideas, 1):
        print(f"    {i}. {idea.get('name', 'N/A')}: {idea.get('description', '')[:60]}...")
    
    print("\n" + "=" * 70)
    print("4️⃣  VERIFICATION CORE DEMO")
    print("=" * 70)
    
    # Cross-reference verification
    print("\n  ✅ Cross-Reference Verification:")
    claim = "Firecrawl can scrape JavaScript-rendered content"
    result = bridge.verification.verify(
        claim,
        level=VerificationLevel.CROSS_REFERENCE,
        context="web scraping capabilities",
        llm_call=demo_llm
    )
    print(f"    Claim: {claim}")
    print(f"    Verified: {result.verified}")
    print(f"    Confidence: {result.confidence:.2f}")
    print(f"    Sources: {len(result.sources)}")
    
    # Deep verification
    print("\n  🔬 Deep Verification:")
    claim2 = "A self-healing scraper using reasoning will never break"
    result2 = bridge.verification.verify(
        claim2,
        level=VerificationLevel.DEEP,
        context="scraper architecture",
        llm_call=demo_llm
    )
    print(f"    Claim: {claim2}")
    print(f"    Verified: {result2.verified}")
    print(f"    Confidence: {result2.confidence:.2f}")
    print(f"    Uncertainty factors: {len(result2.uncertainty_factors)}")
    
    # Calibration
    bridge.verification.calibrate(0.8, True)
    bridge.verification.calibrate(0.9, True)
    bridge.verification.calibrate(0.7, False)
    cal = bridge.verification.get_calibration_curve()
    print(f"\n  📊 Calibration: ECE={cal['ece']:.3f}, MCE={cal['mce']:.3f}, samples={cal['samples']}")
    
    print("\n" + "=" * 70)
    print("5️⃣  ADAPTIVE ROUTER DEMO")
    print("=" * 70)
    
    # Simulate some usage
    for _ in range(5):
        server = bridge.router.select_server("scrape")
        bridge.router.record_result(server, "scrape", True, 1.2, 0.85)
    
    for _ in range(3):
        server = bridge.router.select_server("scrape")
        bridge.router.record_result(server, "scrape", False, 5.0, 0.3)
    
    ranking = bridge.router.get_ranking("scrape")
    print("  Server ranking for 'scrape':")
    for server, score in ranking:
        print(f"    {server}: {score:.3f}")
    
    print("\n" + "=" * 70)
    print("6️⃣  TOOL ORCHESTRATOR DEMO")
    print("=" * 70)
    
    # Define a simple pipeline
    steps = [
        PipelineStep(
            id="search",
            tool="search_firecrawl",
            params={"query": "web scraping best practices 2024", "limit": 5},
            depends_on=[]
        ),
        PipelineStep(
            id="scrape_first",
            tool="scrape_firecrawl",
            params={"url": "{{search.results[0].url}}"},
            depends_on=["search"]
        ),
        PipelineStep(
            id="verify",
            tool="call_tool",
            params={"server": "sequential", "tool": "think", "problem": "Verify the scraped content is accurate"},
            depends_on=["scrape_first"]
        )
    ]
    
    pipeline_id = "demo_pipeline"
    bridge.orchestrator.define_pipeline(pipeline_id, steps)
    print(f"  Defined pipeline: {pipeline_id} with {len(steps)} steps")
    
    # Note: Not executing since servers aren't really running
    print("  (Pipeline execution skipped - servers not actually running in demo)")
    
    print("\n" + "=" * 70)
    print("7️⃣  HIGH-LEVEL COGNITIVE OPERATIONS")
    print("=" * 70)
    
    # Investigate
    print("\n  🔍 Investigate (quick):")
    inv_result = bridge.investigate("AI-powered web scraping", depth="quick")
    print(f"    Topic: {inv_result['topic']}")
    print(f"    Search results: {len(inv_result['search_results'])}")
    print(f"    Reasoning steps: {inv_result['reasoning_chain']['steps']}")
    print(f"    Creative insights: {len(inv_result['creative_insights'])}")
    
    # Solve problem
    print("\n  🧩 Solve Problem (first principles):")
    solve_result = bridge.solve_problem(
        "How to extract structured data from any website reliably?",
        method="first_principles"
    )
    print(f"    Strategy: {solve_result['strategy']}")
    print(f"    Confidence: {solve_result['confidence']:.2f}")
    print(f"    Verified: {solve_result['verified']}")
    
    # Verify claim
    print("\n  ✅ Verify Claim:")
    verify_result = bridge.verify_claim(
        "Structured extraction is more reliable than regex parsing",
        level=VerificationLevel.DEEP
    )
    print(f"    Verified: {verify_result.verified}")
    print(f"    Confidence: {verify_result.confidence:.2f}")
    
    print("\n" + "=" * 70)
    print("8️⃣  SYSTEM STATUS")
    print("=" * 70)
    
    sys_status = bridge.get_system_status()
    print(f"  Servers: {len(sys_status['servers'])}")
    print(f"  Memory: {sys_status['memory']['total']} nodes ({sys_status['memory']['semantic']} semantic, {sys_status['memory']['episodic']} episodic, {sys_status['memory']['procedural']} procedural)")
    print(f"  Reasoning chains: {sys_status['reasoning_chains']}")
    print(f"  Verification cache: {sys_status['verification_cache']}")
    print(f"  Calibration samples: {sys_status['calibration']['samples']}")
    
    print("\n" + "=" * 70)
    print("✅ DEMO COMPLETE")
    print("=" * 70)
    
    # Cleanup
    bridge.stop_all_servers()
    
    return bridge


def run_convenience_demo():
    """Demo the convenience functions."""
    print("\n" + "=" * 70)
    print("🎯 CONVENIENCE FUNCTIONS DEMO")
    print("=" * 70)
    
    # These use the global bridge
    print("\n  investigate():")
    result = investigate("quantum computing", depth="quick")
    print(f"    Steps: {result['reasoning_chain']['steps']}")
    
    print("\n  solve():")
    result = solve("How to optimize database queries?", method="analogical")
    print(f"    Strategy: {result['strategy']}")
    
    print("\n  verify():")
    result = verify("Python is slower than C", level=VerificationLevel.BASIC)
    print(f"    Verified: {result.verified}, Confidence: {result.confidence:.2f}")
    
    print("\n  search():")
    results = search("machine learning", limit=3)
    print(f"    Results: {len(results)}")
    
    print("\n  think():")
    result = think("Design a cache invalidation strategy", steps=3)
    print(f"    Conclusion: {result.conclusion[:60] if result.conclusion else 'N/A'}...")
    
    print("\n  blend():")
    result = blend("web_scraping", "reasoning", "hybrid")
    print(f"    Hybrid: {result['result'].get('name', 'N/A')}")
    
    print("\n  status():")
    result = status()
    print(f"    Memory nodes: {result['memory']['total']}")


if __name__ == "__main__":
    # Run main demo
    bridge = run_cognitive_demo()
    
    # Run convenience demo
    run_convenience_demo()
    
    print("\n" + "=" * 70)
    print("🎉 ALL DEMOS COMPLETED SUCCESSFULLY")
    print("=" * 70)
    print("\nNext steps:")
    print("  1. Add real LLM: bridge = CognitiveMCPBridge(llm_call=your_llm_function)")
    print("  2. Add API keys to environment for full server functionality")
    print("  3. Use bridge.investigate(), bridge.solve_problem(), etc. for real tasks")
    print("  4. Extend with custom tools, memory types, reasoning strategies")