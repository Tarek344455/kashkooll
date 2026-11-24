"""
CLI — Command-line interface for the Cognitive MCP Architecture.
"""
import asyncio
import json
import sys
from pathlib import Path
from typing import Optional

import click
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.syntax import Syntax

# Add parent to path
sys.path.insert(0, str(Path(__file__).parent))

from .cognitive_core import (
    MemoryPalace, MemoryType, MemoryNode,
    ReasoningEngine, ReasoningContext, ReasoningStrategy, Thought, ThoughtType, ThoughtChain,
    CreativeSynthesis,
    VerificationCore, VerificationLevel, VerificationResult,
    AdaptiveRouter, ServerPerformance,
    ToolOrchestrator, PipelineStep, PipelineResult
)
from .integration import CognitiveMCPBridge, get_bridge
from .config import CognitiveMCPConfig, create_config, ConfigManager, ConfigFormat
from .persistence import create_persistence_manager, save_cognitive_state, load_cognitive_state
from .advanced_verification import (
    AdvancedVerificationOrchestrator, VerificationStrategy, VerificationContext, advanced_verify
)
from .models import ScrapeResult, SearchResult, TranscriptResult, PDFResult, ThinkResult


console = Console()


# ==================== DEMO LLM ====================

def demo_llm(prompt: str) -> str:
    """Demo LLM for testing without API keys."""
    prompt_lower = prompt.lower()

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

    elif "evidence" in prompt_lower:
        return """EVIDENCE 1: Scientific consensus | Multiple peer-reviewed studies confirm | SUPPORTS | 0.9 | 0.9
EVIDENCE 2: IPCC report | Climate change is human-caused | SUPPORTS | 0.95 | 0.95
EVIDENCE 3: Skeptic blog | Claims natural cycles | CONTRADICTS | 0.3 | 0.4"""

    elif "logical" in prompt_lower:
        return """PREMISES: CO2 traps heat, Humans emit CO2
CONCLUSION: Humans cause warming
FALLACIES: None
ASSUMPTIONS: Climate sensitivity is positive
CONTRADICTIONS: None
VALIDITY: valid"""

    elif "uncertainty" in prompt_lower:
        return """ALEATORIC: 0.1
EPISTEMIC: 0.2
MODEL: 0.1
SOURCE: 0.1
TEMPORAL: 0.15
OVERALL: 0.13
FACTORS: measurement error, model uncertainty"""

    elif "attack" in prompt_lower:
        return """ATTACK 1: Correlation not causation
ATTACK 2: Solar activity alternative
ATTACK 3: Temperature record adjustments
SEVERITY: medium for all"""

    elif "defense" in prompt_lower:
        return """DEFENSE 1: invalid | Controlled for solar | low uncertainty
DEFENSE 2: invalid | Fingerprint matches GHG | low uncertainty
DEFENSE 3: invalid | Multiple independent datasets | low uncertainty"""

    elif "causal" in prompt_lower:
        return """CAUSAL_CLAIM: yes
CAUSE: CO2 emissions
EFFECT: Global warming
CONFOUNDERS: solar, volcanic
REVERSE_CAUSALITY_POSSIBLE: no
BRADFORD_HILL_SCORE: 8
NECESSARY_CONDITIONS: temporality, mechanism"""

    return f"[Demo LLM Response to: {prompt[:80]}...]"


# ==================== CLI COMMANDS ====================

@click.group()
@click.version_option(version="1.0.0")
@click.option("--config", "-c", type=click.Path(exists=True), help="Config file path")
@click.option("--verbose", "-v", is_flag=True, help="Verbose output")
@click.pass_context
def cli(ctx, config, verbose):
    """Kashkool Cognitive MCP CLI - Cognitive architecture for MCP servers."""
    ctx.ensure_object(dict)
    ctx.obj["config_path"] = config
    ctx.obj["verbose"] = verbose

    if config:
        console.print(f"[green]Loaded config: {config}[/green]")


@cli.command()
@click.pass_context
def demo(ctx):
    """Run the full cognitive architecture demo."""
    console.print(Panel.fit("🧠 [bold]Kashkool Cognitive MCP Demo[/bold]", border_style="blue"))

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        console=console
    ) as progress:
        task = progress.add_task("Initializing bridge...", total=None)

        bridge = CognitiveMCPBridge(llm_call=demo_llm)
        progress.update(task, description="Starting servers...")
        server_status = bridge.start_all_servers()

        progress.update(task, description="Running memory demo...")
        _demo_memory(bridge)

        progress.update(task, description="Running reasoning demo...")
        _demo_reasoning(bridge)

        progress.update(task, description="Running creative demo...")
        _demo_creative(bridge)

        progress.update(task, description="Running verification demo...")
        _demo_verification(bridge)

        progress.update(task, description="Running router demo...")
        _demo_router(bridge)

        progress.update(task, description="Running high-level ops demo...")
        _demo_high_level(bridge)

        bridge.stop_all_servers()

    console.print(Panel.fit("✅ [bold green]Demo completed successfully![/bold green]", border_style="green"))


def _demo_memory(bridge):
    console.print("\n[bold cyan]📦 Memory Palace Demo[/bold cyan]")

    mem_id1 = bridge.memory.store(
        content="Firecrawl excels at JavaScript-heavy sites with anti-bot protection",
        mem_type=MemoryType.SEMANTIC,
        tags={"scraping", "firecrawl", "javascript"},
        importance=0.8,
        source="experience"
    )
    console.print(f"  Stored semantic memory: [green]{mem_id1}[/green]")

    mem_id2 = bridge.memory.store(
        content="Investigated e-commerce price monitoring for client project",
        mem_type=MemoryType.EPISODIC,
        tags={"project", "ecommerce", "monitoring"},
        importance=0.9,
        source="work"
    )
    console.print(f"  Stored episodic memory: [green]{mem_id2}[/green]")

    results = bridge.memory.recall(query="scraping", top_k=3)
    console.print(f"  Recalled [yellow]{len(results)}[/yellow] memories for 'scraping'")
    for r in results:
        console.print(f"    - [{r.type.value}] {str(r.content)[:60]}... (importance: {r.importance:.2f})")

    stats = bridge.memory.get_stats()
    console.print(f"  Stats: {stats}")


def _demo_reasoning(bridge):
    console.print("\n[bold cyan]🧠 Reasoning Engine Demo[/bold cyan]")

    strategies = [
        ("Chain-of-Thought", ReasoningStrategy.CHAIN_OF_THOUGHT),
        ("Tree-of-Thoughts", ReasoningStrategy.TREE_OF_THOUGHTS),
        ("First Principles", ReasoningStrategy.FIRST_PRINCIPLES),
        ("Analogical", ReasoningStrategy.ANALOGICAL),
    ]

    for name, strategy in strategies:
        console.print(f"\n  [bold]{name}:[/bold]")
        context = ReasoningContext(
            problem="How to build a robust web scraper that handles dynamic content?",
            strategy=strategy,
            max_steps=5,
            max_branches=3,
            require_verification=True
        )
        chain = bridge.reasoning.reason(context, demo_llm)
        console.print(f"    Steps: {len(chain.thoughts)}")
        console.print(f"    Conclusion: {chain.conclusion.content[:80] if chain.conclusion else 'None'}...")
        console.print(f"    Confidence: {chain.confidence:.2f}")
        console.print(f"    Verified: {chain.verified}")


def _demo_creative(bridge):
    console.print("\n[bold cyan]🎨 Creative Synthesis Demo[/bold cyan]")

    blend_result = bridge.creative.blend("web_scraping", "reasoning", "hybrid", demo_llm)
    console.print(f"  Hybrid name: [green]{blend_result['result'].get('name', 'N/A')}[/green]")
    console.print(f"  Emergent: {blend_result['result'].get('emergent_properties', [])}")
    console.print(f"  Applications: {blend_result['result'].get('applications', [])}")

    ideas = bridge.creative.divergent_generation(
        "web_scraping", num_ideas=3,
        constraints=["novel", "practical", "uses reasoning"],
        llm_call=demo_llm
    )
    for i, idea in enumerate(ideas, 1):
        console.print(f"  {i}. [green]{idea.get('name', 'N/A')}[/green]: {idea.get('description', '')[:60]}...")


def _demo_verification(bridge):
    console.print("\n[bold cyan]✅ Verification Core Demo[/bold cyan]")

    claim = "Firecrawl can scrape JavaScript-rendered content"
    result = bridge.verification.verify(claim, VerificationLevel.CROSS_REFERENCE, "web scraping", demo_llm)
    console.print(f"  Claim: {claim}")
    console.print(f"  Verified: [green]{result.verified}[/green]")
    console.print(f"  Confidence: {result.confidence:.2f}")
    console.print(f"  Sources: {len(result.sources)}")

    claim2 = "A self-healing scraper using reasoning will never break"
    result2 = bridge.verification.verify(claim2, VerificationLevel.DEEP, "scraper architecture", demo_llm)
    console.print(f"\n  Claim: {claim2}")
    console.print(f"  Verified: [red]{result2.verified}[/red]")
    console.print(f"  Confidence: {result2.confidence:.2f}")
    console.print(f"  Uncertainty factors: {len(result2.uncertainty_factors)}")

    bridge.verification.calibrate(0.8, True)
    bridge.verification.calibrate(0.9, True)
    bridge.verification.calibrate(0.7, False)
    cal = bridge.verification.get_calibration_curve()
    console.print(f"\n  Calibration: ECE={cal['ece']:.3f}, MCE={cal['mce']:.3f}, samples={cal['samples']}")


def _demo_router(bridge):
    console.print("\n[bold cyan]🎯 Adaptive Router Demo[/bold cyan]")

    for _ in range(5):
        server = bridge.router.select_server("scrape")
        bridge.router.record_result(server, "scrape", True, 1.2, 0.85)

    for _ in range(3):
        server = bridge.router.select_server("scrape")
        bridge.router.record_result(server, "scrape", False, 5.0, 0.3)

    ranking = bridge.router.get_ranking("scrape")
    console.print("  Server ranking for 'scrape':")
    for server, score in ranking:
        console.print(f"    {server}: {score:.3f}")


def _demo_high_level(bridge):
    console.print("\n[bold cyan]🚀 High-Level Cognitive Operations[/bold cyan]")

    inv_result = bridge.investigate("AI-powered web scraping", depth="quick")
    console.print(f"  Investigate: {inv_result['topic']}")
    console.print(f"  Steps: {inv_result['reasoning_chain']['steps']}")
    console.print(f"  Creative insights: {len(inv_result['creative_insights'])}")

    solve_result = bridge.solve_problem(
        "How to extract structured data from any website reliably?",
        method="first_principles"
    )
    console.print(f"\n  Solve: {solve_result['strategy']}")
    console.print(f"  Confidence: {solve_result['confidence']:.2f}")
    console.print(f"  Verified: {solve_result['verified']}")

    verify_result = bridge.verify_claim(
        "Structured extraction is more reliable than regex parsing",
        VerificationLevel.DEEP
    )
    console.print(f"\n  Verify: {verify_result.verified}, Confidence: {verify_result.confidence:.2f}")

    sys_status = bridge.get_system_status()
    console.print(f"\n  System Status:")
    console.print(f"    Memory: {sys_status['memory']['total']} nodes")
    console.print(f"    Reasoning chains: {sys_status['reasoning_chains']}")
    console.print(f"    Verification cache: {sys_status['verification_cache']}")


@cli.command()
@click.argument("topic")
@click.option("--depth", type=click.Choice(["quick", "standard", "deep"]), default="standard")
@click.option("--strategy", type=click.Choice([s.value for s in ReasoningStrategy]), default="chain_of_thought")
@click.pass_context
def investigate(ctx, topic, depth, strategy):
    """Investigate a topic deeply."""
    bridge = CognitiveMCPBridge(llm_call=demo_llm)
    bridge.start_all_servers()

    try:
        result = bridge.investigate(topic, depth, ReasoningStrategy(strategy))
        console.print(json.dumps(result, indent=2, default=str))
    finally:
        bridge.stop_all_servers()


@cli.command()
@click.argument("problem")
@click.option("--method", type=click.Choice(["auto", "first_principles", "analogical", "react", "plan_and_solve", "self_consistency", "tree_of_thoughts"]), default="auto")
@click.option("--verify/--no-verify", default=True)
@click.pass_context
def solve(ctx, problem, method, verify):
    """Solve a problem using cognitive reasoning."""
    bridge = CognitiveMCPBridge(llm_call=demo_llm)
    bridge.start_all_servers()

    try:
        result = bridge.solve_problem(problem, method, verify)
        console.print(json.dumps(result, indent=2, default=str))
    finally:
        bridge.stop_all_servers()


@cli.command()
@click.argument("claim")
@click.option("--level", type=click.Choice([l.name.lower() for l in VerificationLevel]), default="cross_reference")
@click.option("--context", default=None)
@click.pass_context
def verify(ctx, claim, level, context):
    """Verify a claim."""
    bridge = CognitiveMCPBridge(llm_call=demo_llm)
    bridge.start_all_servers()

    try:
        result = bridge.verify_claim(claim, VerificationLevel[level.upper()], context)
        console.print(json.dumps(result.__dict__, indent=2, default=str))
    finally:
        bridge.stop_all_servers()


@cli.command()
@click.argument("concept_a")
@click.argument("concept_b")
@click.option("--type", "blend_type", type=click.Choice(["property_mapping", "structural_alignment", "metaphorical", "hybrid"]), default="hybrid")
@click.pass_context
def blend(ctx, concept_a, concept_b, blend_type):
    """Blend two concepts creatively."""
    bridge = CognitiveMCPBridge(llm_call=demo_llm)
    bridge.start_all_servers()

    try:
        result = bridge.blend_concepts(concept_a, concept_b, blend_type)
        console.print(json.dumps(result, indent=2, default=str))
    finally:
        bridge.stop_all_servers()


@cli.command()
@click.argument("seed_concept")
@click.option("--num", default=5, help="Number of ideas")
@click.option("--constraint", multiple=True, help="Constraints for generation")
@click.pass_context
def divergent(ctx, seed_concept, num, constraint):
    """Generate divergent ideas from a seed concept."""
    bridge = CognitiveMCPBridge(llm_call=demo_llm)
    bridge.start_all_servers()

    try:
        ideas = bridge.creative.divergent_generation(seed_concept, num, list(constraint), demo_llm)
        for i, idea in enumerate(ideas, 1):
            console.print(f"[bold]{i}. {idea.get('name', 'N/A')}[/bold]")
            console.print(f"   {idea.get('description', '')}")
            console.print(f"   Novelty: {idea.get('novelty', '')}\n")
    finally:
        bridge.stop_all_servers()


@cli.command()
@click.argument("goal")
@click.option("--max-steps", default=10)
@click.pass_context
def pipeline(ctx, goal, max_steps):
    """Create and execute a dynamic pipeline for a goal."""
    bridge = CognitiveMCPBridge(llm_call=demo_llm)
    bridge.start_all_servers()

    try:
        result = bridge.create_and_execute_pipeline(goal, max_steps)
        console.print(json.dumps({
            "pipeline_id": result.pipeline_id,
            "success": result.success,
            "error": result.error,
            "execution_time": result.execution_time,
            "completed_steps": result.completed_steps,
            "failed_steps": result.failed_steps
        }, indent=2, default=str))
    finally:
        bridge.stop_all_servers()


@cli.command()
@click.pass_context
def status(ctx):
    """Show system status."""
    bridge = CognitiveMCPBridge(llm_call=demo_llm)
    bridge.start_all_servers()

    try:
        sys_status = bridge.get_system_status()
        console.print(json.dumps(sys_status, indent=2, default=str))
    finally:
        bridge.stop_all_servers()


@cli.command()
@click.option("--backend", type=click.Choice(["json", "sqlite", "redis"]), default="sqlite")
@click.option("--path", default="./cognitive_data")
@click.pass_context
def save_state(ctx, backend, path):
    """Save cognitive state to disk."""
    bridge = CognitiveMCPBridge(llm_call=demo_llm)
    bridge.start_all_servers()

    try:
        with Progress(console=console) as progress:
            task = progress.add_task("Saving...", total=None)
            results = save_cognitive_state(bridge, backend, path)
        console.print(f"[green]Saved:[/green] {results}")
    finally:
        bridge.stop_all_servers()


@cli.command()
@click.option("--backend", type=click.Choice(["json", "sqlite", "redis"]), default="sqlite")
@click.option("--path", default="./cognitive_data")
@click.pass_context
def load_state(ctx, backend, path):
    """Load cognitive state from disk."""
    bridge = CognitiveMCPBridge(llm_call=demo_llm)
    bridge.start_all_servers()

    try:
        with Progress(console=console) as progress:
            task = progress.add_task("Loading...", total=None)
            results = load_cognitive_state(bridge, backend, path)
        console.print(f"[green]Loaded:[/green] {results}")
    finally:
        bridge.stop_all_servers()


@cli.command()
@click.option("--preset", type=click.Choice(["default", "development", "production", "testing", "minimal"]), default="default")
@click.option("--output", "-o", type=click.Path(), help="Output file")
@click.option("--format", type=click.Choice(["json", "yaml"]), default="json")
@click.pass_context
def create_config(ctx, preset, output, format):
    """Create a configuration file from preset."""
    config = create_config(preset)

    fmt = ConfigFormat.JSON if format == "json" else ConfigFormat.YAML
    output_path = Path(output) if output else Path(f"config_{preset}.{format}")

    config.save(output_path, fmt)
    console.print(f"[green]Created config:[/green] {output_path}")

    # Validate
    issues = config.validate()
    if issues:
        console.print("[yellow]Issues:[/yellow]")
        for issue in issues:
            console.print(f"  - {issue}")
    else:
        console.print("[green]Config valid![/green]")


@cli.command()
@click.argument("config_file", type=click.Path(exists=True))
@click.pass_context
def validate_config(ctx, config_file):
    """Validate a configuration file."""
    config = CognitiveMCPConfig.load(config_file)
    issues = config.validate()

    if issues:
        console.print("[red]Validation failed:[/red]")
        for issue in issues:
            console.print(f"  - {issue}")
    else:
        console.print("[green]Config valid![/green]")

    console.print(f"\nServers: {len(config.servers)}")
    console.print(f"Environment: {config.environment}")
    console.print(f"Debug: {config.debug}")


@cli.command()
@click.pass_context
def list_servers(ctx):
    """List all configured MCP servers."""
    config = CognitiveMCPConfig.default()

    table = Table(title="MCP Servers")
    table.add_column("Name", style="cyan")
    table.add_column("Command", style="green")
    table.add_column("Tools", style="yellow")
    table.add_column("Priority", style="magenta")
    table.add_column("Enabled", style="blue")

    for server in config.get_enabled_servers():
        table.add_row(
            server.name,
            " ".join(server.command),
            ", ".join(server.tools),
            str(server.priority),
            "✅" if server.enabled else "❌"
        )

    console.print(table)


@cli.command()
@click.pass_context
def advanced_verify_cmd(ctx):
    """Run advanced verification (async)."""
    async def run():
        claim = "Human CO2 emissions are the primary cause of global warming since 1950"

        with Progress(console=console) as progress:
            task = progress.add_task("Running advanced verification...", total=None)
            result = await advanced_verify(claim, demo_llm)

        console.print(json.dumps(result, indent=2, default=str))

    asyncio.run(run())


@cli.command()
@click.option("--host", default="0.0.0.0")
@click.option("--port", default=8000)
@click.option("--workers", default=1)
@click.option("--reload", is_flag=True)
@click.pass_context
def serve(ctx, host, port, workers, reload):
    """Start the API server."""
    import uvicorn

    console.print(f"[green]Starting API server on {host}:{port}[/green]")
    uvicorn.run(
        "kashkool_mcp_client.api_server:app",
        host=host,
        port=port,
        workers=workers,
        reload=reload,
        log_level="info"
    )


# ==================== MAIN ====================

if __name__ == "__main__":
    cli()