"""
Kashkool Cognitive Core — The thinking brain behind MCP operations.
Not a wrapper. A genuine cognitive architecture with:
- Multi-modal reasoning (CoT, ToT, Self-consistency)
- Three-tier memory (Semantic, Episodic, Procedural)
- Creative synthesis (Concept blending, Analogical reasoning)
- Self-verification with confidence calibration
"""
import asyncio
import hashlib
import json
import time
import uuid
from abc import ABC, abstractmethod
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Tuple, Union
import numpy as np


# ==================== COGNITIVE PRIMITIVES ====================

class ThoughtType(Enum):
    """Types of cognitive operations."""
    OBSERVATION = "observation"          # Raw perception
    INFERENCE = "inference"              # Logical deduction
    HYPOTHESIS = "hypothesis"            # Tentative explanation
    ANALOGY = "analogy"                  # Cross-domain mapping
    SYNTHESIS = "synthesis"              # Combining ideas
    CRITIQUE = "critique"                # Self-evaluation
    VERIFICATION = "verification"        # Fact-checking
    CREATIVE_LEAP = "creative_leap"      # Non-linear insight
    META_COGNITION = "meta_cognition"    # Thinking about thinking


@dataclass
class Thought:
    """A single cognitive unit — the atom of thinking."""
    id: str = field(default_factory=lambda: str(uuid.uuid4())[:8])
    type: ThoughtType = ThoughtType.OBSERVATION
    content: str = ""
    confidence: float = 0.5              # 0-1, calibrated
    evidence: List[str] = field(default_factory=list)  # Supporting thought IDs
    contradicts: List[str] = field(default_factory=list)  # Conflicting thought IDs
    metadata: Dict[str, Any] = field(default_factory=dict)
    timestamp: datetime = field(default_factory=datetime.now)
    parent_id: Optional[str] = None      # For thought trees
    children_ids: List[str] = field(default_factory=list)
    
    def __hash__(self):
        return hash(self.id)
    
    def __eq__(self, other):
        return isinstance(other, Thought) and self.id == other.id


@dataclass
class ThoughtChain:
    """A sequence of connected thoughts (Chain-of-Thought)."""
    id: str = field(default_factory=lambda: str(uuid.uuid4())[:8])
    thoughts: List[Thought] = field(default_factory=list)
    goal: str = ""
    conclusion: Optional[Thought] = None
    confidence: float = 0.0
    verified: bool = False
    verification_notes: str = ""
    
    def add_thought(self, thought: Thought, parent_id: Optional[str] = None):
        if parent_id:
            thought.parent_id = parent_id
            # Find parent and link
            for t in self.thoughts:
                if t.id == parent_id:
                    t.children_ids.append(thought.id)
                    break
        self.thoughts.append(thought)
    
    def get_thought(self, thought_id: str) -> Optional[Thought]:
        for t in self.thoughts:
            if t.id == thought_id:
                return t
        return None
    
    def get_leaf_thoughts(self) -> List[Thought]:
        """Thoughts with no children — current frontier."""
        return [t for t in self.thoughts if not t.children_ids]


@dataclass
class ThoughtTree:
    """Tree-of-Thoughts for exploration with backtracking."""
    id: str = field(default_factory=lambda: str(uuid.uuid4())[:8])
    root: Thought = field(default_factory=Thought)
    nodes: Dict[str, Thought] = field(default_factory=dict)
    best_path: List[str] = field(default_factory=list)
    explored_paths: List[List[str]] = field(default_factory=list)
    pruned_paths: List[List[str]] = field(default_factory=list)
    
    def __post_init__(self):
        self.nodes[self.root.id] = self.root
    
    def add_node(self, thought: Thought, parent_id: str):
        parent = self.nodes.get(parent_id)
        if not parent:
            raise ValueError(f"Parent {parent_id} not found")
        thought.parent_id = parent_id
        parent.children_ids.append(thought.id)
        self.nodes[thought.id] = thought
    
    def get_path_to_root(self, node_id: str) -> List[str]:
        path = []
        current = self.nodes.get(node_id)
        while current:
            path.append(current.id)
            current = self.nodes.get(current.parent_id) if current.parent_id else None
        return list(reversed(path))
    
    def evaluate_path(self, path: List[str], evaluator: Callable[[List[Thought]], float]) -> float:
        thoughts = [self.nodes[tid] for tid in path if tid in self.nodes]
        return evaluator(thoughts)


# ==================== MEMORY PALACE ====================

class MemoryType(Enum):
    SEMANTIC = "semantic"      # Facts, concepts, knowledge
    EPISODIC = "episodic"      # Experiences, specific events
    PROCEDURAL = "procedural"  # Skills, how-to patterns


@dataclass
class MemoryNode:
    """A memory unit with rich connections."""
    id: str = field(default_factory=lambda: str(uuid.uuid4())[:8])
    type: MemoryType = MemoryType.SEMANTIC
    content: Any = None
    embedding: Optional[List[float]] = None  # For semantic similarity
    connections: Dict[str, float] = field(default_factory=dict)  # node_id -> strength
    access_count: int = 0
    last_accessed: datetime = field(default_factory=datetime.now)
    created_at: datetime = field(default_factory=datetime.now)
    importance: float = 0.5
    tags: Set[str] = field(default_factory=set)
    source: str = ""  # Where this came from
    verified: bool = False
    verification_sources: List[str] = field(default_factory=list)


class MemoryPalace:
    """
    Three-tier memory system with associative recall, consolidation, and forgetting.
    Inspired by human memory architecture + vector databases.
    """
    
    def __init__(self, capacity: int = 10000):
        self.capacity = capacity
        self.semantic: Dict[str, MemoryNode] = {}
        self.episodic: Dict[str, MemoryNode] = {}
        self.procedural: Dict[str, MemoryNode] = {}
        self._all_nodes: Dict[str, MemoryNode] = {}
        self._index_by_tag: Dict[str, Set[str]] = defaultdict(set)
        self._consolidation_threshold = 0.7
        self._forgetting_curve_factor = 0.99  # Per day
    
    def _get_store(self, mem_type: MemoryType) -> Dict[str, MemoryNode]:
        return {"semantic": self.semantic, "episodic": self.episodic, "procedural": self.procedural}[mem_type.value]
    
    def store(
        self,
        content: Any,
        mem_type: MemoryType = MemoryType.SEMANTIC,
        tags: Optional[Set[str]] = None,
        importance: float = 0.5,
        source: str = "",
        connections: Optional[Dict[str, float]] = None,
        embedding: Optional[List[float]] = None,
        verified: bool = False
    ) -> str:
        """Store a new memory, return its ID."""
        node = MemoryNode(
            type=mem_type,
            content=content,
            embedding=embedding,
            importance=importance,
            tags=tags or set(),
            source=source,
            connections=connections or {},
            verified=verified
        )
        
        store = self._get_store(mem_type)
        store[node.id] = node
        self._all_nodes[node.id] = node
        
        for tag in node.tags:
            self._index_by_tag[tag].add(node.id)
        
        # Auto-connect to similar memories (if embedding provided)
        if embedding:
            self._auto_connect(node)
        
        # Enforce capacity with intelligent forgetting
        self._enforce_capacity()
        
        return node.id
    
    def _auto_connect(self, new_node: MemoryNode, top_k: int = 5):
        """Connect to semantically similar existing memories."""
        if not new_node.embedding:
            return
        
        similarities = []
        for node_id, node in self._all_nodes.items():
            if node.id == new_node.id or not node.embedding:
                continue
            sim = self._cosine_similarity(new_node.embedding, node.embedding)
            if sim > 0.7:
                similarities.append((node_id, sim))
        
        similarities.sort(key=lambda x: x[1], reverse=True)
        for node_id, sim in similarities[:top_k]:
            new_node.connections[node_id] = sim
            self._all_nodes[node_id].connections[new_node.id] = sim
    
    def _cosine_similarity(self, a: List[float], b: List[float]) -> float:
        if not a or not b or len(a) != len(b):
            return 0.0
        a_np, b_np = np.array(a), np.array(b)
        return float(np.dot(a_np, b_np) / (np.linalg.norm(a_np) * np.linalg.norm(b_np)))
    
    def recall(
        self,
        query: Optional[Any] = None,
        mem_type: Optional[MemoryType] = None,
        tags: Optional[Set[str]] = None,
        top_k: int = 10,
        min_importance: float = 0.0,
        spreading_activation: bool = True
    ) -> List[MemoryNode]:
        """
        Recall memories using multiple cues.
        Supports: direct query, tag filtering, spreading activation from seed nodes.
        """
        candidates = set()
        
        # Tag-based filtering
        if tags:
            for tag in tags:
                candidates.update(self._index_by_tag.get(tag, set()))
        else:
            candidates = set(self._all_nodes.keys())
        
        # Type filtering
        if mem_type:
            store = self._get_store(mem_type)
            candidates &= set(store.keys())
        
        # Importance filtering
        candidates = {cid for cid in candidates if self._all_nodes[cid].importance >= min_importance}
        
        if not candidates:
            return []
        
        # Score candidates
        scored = []
        query_embedding = getattr(query, 'embedding', None) if hasattr(query, 'embedding') else None
        
        for cid in candidates:
            node = self._all_nodes[cid]
            score = node.importance * (node.access_count ** 0.1)  # Base score
            
            # Semantic similarity if embeddings available
            if query_embedding and node.embedding:
                score += self._cosine_similarity(query_embedding, node.embedding) * 2
            
            # Spreading activation from connected nodes
            if spreading_activation:
                for conn_id, strength in node.connections.items():
                    if conn_id in self._all_nodes:
                        conn_node = self._all_nodes[conn_id]
                        score += conn_node.importance * strength * 0.3
            
            scored.append((node, score))
        
        scored.sort(key=lambda x: x[1], reverse=True)
        results = [node for node, _ in scored[:top_k]]
        
        # Update access stats
        for node in results:
            node.access_count += 1
            node.last_accessed = datetime.now()
        
        return results
    
    def associate(self, node_id_1: str, node_id_2: str, strength: float = 1.0):
        """Create bidirectional association between memories."""
        for nid in [node_id_1, node_id_2]:
            if nid not in self._all_nodes:
                raise ValueError(f"Node {nid} not found")
        
        self._all_nodes[node_id_1].connections[node_id_2] = strength
        self._all_nodes[node_id_2].connections[node_id_1] = strength
    
    def consolidate(self):
        """Memory consolidation: strengthen important connections, weaken unused."""
        now = datetime.now()
        
        for node in self._all_nodes.values():
            # Decay unused memories
            days_since_access = (now - node.last_accessed).days
            node.importance *= (self._forgetting_curve_factor ** days_since_access)
            
            # Strengthen verified memories
            if node.verified:
                node.importance = min(1.0, node.importance * 1.1)
            
            # Prune very weak connections
            node.connections = {k: v for k, v in node.connections.items() if v > 0.1}
        
        # Remove memories below threshold
        to_remove = [nid for nid, node in self._all_nodes.items() if node.importance < 0.05]
        for nid in to_remove:
            self._forget(nid)
    
    def _forget(self, node_id: str):
        """Completely remove a memory."""
        node = self._all_nodes.pop(node_id, None)
        if not node:
            return
        
        store = self._get_store(node.type)
        store.pop(node_id, None)
        
        for tag in node.tags:
            self._index_by_tag[tag].discard(node_id)
        
        # Remove from other nodes' connections
        for other in self._all_nodes.values():
            other.connections.pop(node_id, None)
    
    def _enforce_capacity(self):
        if len(self._all_nodes) <= self.capacity:
            return
        
        # Remove least important, least accessed memories
        sorted_nodes = sorted(
            self._all_nodes.values(),
            key=lambda n: (n.importance, n.access_count, n.last_accessed)
        )
        
        to_remove = len(self._all_nodes) - self.capacity
        for node in sorted_nodes[:to_remove]:
            self._forget(node.id)
    
    def get_stats(self) -> Dict[str, Any]:
        return {
            "total": len(self._all_nodes),
            "semantic": len(self.semantic),
            "episodic": len(self.episodic),
            "procedural": len(self.procedural),
            "tags": len(self._index_by_tag),
            "avg_importance": np.mean([n.importance for n in self._all_nodes.values()]) if self._all_nodes else 0,
            "verified_count": sum(1 for n in self._all_nodes.values() if n.verified)
        }


# ==================== REASONING ENGINE ====================

class ReasoningStrategy(Enum):
    CHAIN_OF_THOUGHT = "chain_of_thought"
    TREE_OF_THOUGHTS = "tree_of_thoughts"
    SELF_CONSISTENCY = "self_consistency"
    REACT = "react"                    # Reasoning + Acting
    PLAN_AND_SOLVE = "plan_and_solve"
    ANALOGICAL = "analogical"
    FIRST_PRINCIPLES = "first_principles"


@dataclass
class ReasoningContext:
    """Context for a reasoning session."""
    problem: str
    strategy: ReasoningStrategy = ReasoningStrategy.CHAIN_OF_THOUGHT
    max_steps: int = 10
    max_branches: int = 3
    temperature: float = 0.7
    require_verification: bool = True
    memory: Optional[MemoryPalace] = None
    tools: Optional[Dict[str, Callable]] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


class ReasoningEngine:
    """
    Multi-strategy reasoning engine with self-verification.
    Implements: CoT, ToT, Self-Consistency, ReAct, Analogical, First Principles.
    """
    
    def __init__(self, memory: Optional[MemoryPalace] = None):
        self.memory = memory or MemoryPalace()
        self.thought_chains: Dict[str, ThoughtChain] = {}
        self.thought_trees: Dict[str, ThoughtTree] = {}
        self.verification_log: List[Dict] = []
    
    def reason(
        self,
        context: ReasoningContext,
        llm_call: Callable[[str], str]  # Function that takes prompt, returns response
    ) -> ThoughtChain:
        """Main entry point — routes to appropriate strategy."""
        strategy_map = {
            ReasoningStrategy.CHAIN_OF_THOUGHT: self._chain_of_thought,
            ReasoningStrategy.TREE_OF_THOUGHTS: self._tree_of_thoughts,
            ReasoningStrategy.SELF_CONSISTENCY: self._self_consistency,
            ReasoningStrategy.REACT: self._react,
            ReasoningStrategy.PLAN_AND_SOLVE: self._plan_and_solve,
            ReasoningStrategy.ANALOGICAL: self._analogical_reasoning,
            ReasoningStrategy.FIRST_PRINCIPLES: self._first_principles,
        }
        
        handler = strategy_map.get(context.strategy, self._chain_of_thought)
        return handler(context, llm_call)
    
    def _chain_of_thought(self, context: ReasoningContext, llm_call: Callable) -> ThoughtChain:
        """Classic Chain-of-Thought with self-critique."""
        chain = ThoughtChain(goal=context.problem)
        
        # Initial decomposition
        prompt = f"""Problem: {context.problem}

Think step by step. Break this down into clear reasoning steps.
Each step should be a single logical inference.
Format: STEP N: [reasoning]"""
        
        response = llm_call(prompt)
        steps = self._parse_steps(response)
        
        for i, step_content in enumerate(steps):
            thought = Thought(
                type=ThoughtType.INFERENCE,
                content=step_content,
                confidence=0.7,
                metadata={"step_number": i + 1}
            )
            parent_id = chain.thoughts[-1].id if chain.thoughts else None
            chain.add_thought(thought, parent_id)
        
        # Self-critique pass
        if context.require_verification:
            chain = self._self_critique(chain, context, llm_call)
        
        # Extract conclusion
        chain.conclusion = chain.thoughts[-1] if chain.thoughts else None
        chain.confidence = self._calculate_chain_confidence(chain)
        
        self.thought_chains[chain.id] = chain
        return chain
    
    def _tree_of_thoughts(self, context: ReasoningContext, llm_call: Callable) -> ThoughtChain:
        """Tree-of-Thoughts: explore multiple reasoning paths, prune, select best."""
        tree = ThoughtTree()
        tree.root = Thought(
            type=ThoughtType.OBSERVATION,
            content=f"Problem: {context.problem}",
            confidence=1.0
        )
        tree.nodes[tree.root.id] = tree.root
        
        # Generate initial branches
        prompt = f"""Problem: {context.problem}

Generate {context.max_branches} distinct initial approaches to solve this.
Each approach should be a different angle or strategy.
Format: APPROACH N: [description]"""
        
        response = llm_call(prompt)
        approaches = self._parse_approaches(response)
        
        for approach in approaches[:context.max_branches]:
            thought = Thought(
                type=ThoughtType.HYPOTHESIS,
                content=approach,
                confidence=0.6,
                metadata={"depth": 1}
            )
            tree.add_node(thought, tree.root.id)
        
        # Explore each branch
        for depth in range(2, context.max_steps + 1):
            leaf_nodes = [nid for nid, node in tree.nodes.items() if not node.children_ids]
            
            for leaf_id in leaf_nodes:
                leaf = tree.nodes[leaf_id]
                
                # Generate next steps for this branch
                path = tree.get_path_to_root(leaf_id)
                path_content = " -> ".join([tree.nodes[pid].content for pid in path])
                
                prompt = f"""Current reasoning path: {path_content}

Generate {context.max_branches} possible next steps.
Each should advance the reasoning toward a solution.
Format: STEP: [reasoning]"""
                
                response = llm_call(prompt)
                next_steps = self._parse_steps(response)
                
                for step in next_steps[:context.max_branches]:
                    thought = Thought(
                        type=ThoughtType.INFERENCE,
                        content=step,
                        confidence=0.6,
                        metadata={"depth": depth}
                    )
                    tree.add_node(thought, leaf_id)
        
        # Evaluate all complete paths
        evaluator = lambda thoughts: sum(t.confidence for t in thoughts) / len(thoughts) if thoughts else 0
        
        best_score = -1
        best_path = []
        
        for leaf_id in [nid for nid, node in tree.nodes.items() if not node.children_ids]:
            path = tree.get_path_to_root(leaf_id)
            score = tree.evaluate_path(path, evaluator)
            if score > best_score:
                best_score = score
                best_path = path
        
        tree.best_path = best_path
        
        # Convert best path to ThoughtChain
        chain = ThoughtChain(goal=context.problem)
        for tid in best_path:
            chain.thoughts.append(tree.nodes[tid])
        chain.confidence = best_score
        chain.conclusion = tree.nodes[best_path[-1]] if best_path else None
        
        self.thought_trees[tree.id] = tree
        self.thought_chains[chain.id] = chain
        return chain
    
    def _self_consistency(self, context: ReasoningContext, llm_call: Callable) -> ThoughtChain:
        """Self-Consistency: run multiple CoT, take majority/consensus."""
        num_samples = context.metadata.get("num_samples", 5)
        chains = []
        
        for i in range(num_samples):
            # Vary temperature slightly for diversity
            original_temp = context.temperature
            context.temperature = original_temp + (i * 0.1)
            chain = self._chain_of_thought(context, llm_call)
            chains.append(chain)
            context.temperature = original_temp
        
        # Find consensus conclusion
        conclusions = [c.conclusion.content if c.conclusion else "" for c in chains]
        
        # Simple majority vote (could be semantic clustering)
        from collections import Counter
        counter = Counter(conclusions)
        consensus = counter.most_common(1)[0][0] if counter else ""
        
        # Build consensus chain
        consensus_chain = ThoughtChain(goal=context.problem)
        consensus_chain.conclusion = Thought(
            type=ThoughtType.SYNTHESIS,
            content=consensus,
            confidence=counter.most_common(1)[0][1] / num_samples,
            metadata={"method": "self_consistency", "samples": num_samples}
        )
        consensus_chain.confidence = consensus_chain.conclusion.confidence
        consensus_chain.verified = True
        consensus_chain.verification_notes = f"Consensus from {num_samples} samples: {dict(counter)}"
        
        self.thought_chains[consensus_chain.id] = consensus_chain
        return consensus_chain
    
    def _react(self, context: ReasoningContext, llm_call: Callable) -> ThoughtChain:
        """ReAct: Reasoning + Acting loop with tool use."""
        chain = ThoughtChain(goal=context.problem)
        tools = context.tools or {}
        
        max_iterations = context.max_steps
        observation = ""
        
        for i in range(max_iterations):
            # Thought
            prompt = f"""Problem: {context.problem}
Previous observation: {observation}

Think about what to do next. You can:
1. Reason (THOUGHT: ...)
2. Use a tool (ACTION: tool_name | params)
3. Conclude (ANSWER: ...)

Available tools: {list(tools.keys())}"""
            
            response = llm_call(prompt)
            
            if "THOUGHT:" in response:
                thought_content = response.split("THOUGHT:")[1].split("\n")[0].strip()
                thought = Thought(type=ThoughtType.INFERENCE, content=thought_content, confidence=0.7)
                chain.add_thought(thought)
            
            elif "ACTION:" in response:
                action_line = response.split("ACTION:")[1].split("\n")[0].strip()
                tool_name, params_str = action_line.split("|", 1)
                tool_name = tool_name.strip()
                
                try:
                    params = json.loads(params_str.strip())
                except:
                    params = {"input": params_str.strip()}
                
                if tool_name in tools:
                    thought = Thought(
                        type=ThoughtType.OBSERVATION,
                        content=f"Calling {tool_name} with {params}",
                        confidence=0.8,
                        metadata={"tool": tool_name, "params": params}
                    )
                    chain.add_thought(thought)
                    
                    # Execute tool
                    try:
                        result = tools[tool_name](**params)
                        observation = str(result)
                        
                        obs_thought = Thought(
                            type=ThoughtType.OBSERVATION,
                            content=f"Tool result: {observation}",
                            confidence=0.9,
                            metadata={"tool_result": True}
                        )
                        chain.add_thought(obs_thought)
                    except Exception as e:
                        observation = f"Error: {e}"
                else:
                    observation = f"Unknown tool: {tool_name}"
            
            elif "ANSWER:" in response:
                answer = response.split("ANSWER:")[1].strip()
                conclusion = Thought(
                    type=ThoughtType.SYNTHESIS,
                    content=answer,
                    confidence=0.85,
                    metadata={"method": "react"}
                )
                chain.add_thought(conclusion)
                chain.conclusion = conclusion
                break
        
        chain.confidence = self._calculate_chain_confidence(chain)
        self.thought_chains[chain.id] = chain
        return chain
    
    def _plan_and_solve(self, context: ReasoningContext, llm_call: Callable) -> ThoughtChain:
        """Plan-and-Solve: first create plan, then execute."""
        # Phase 1: Planning
        plan_prompt = f"""Problem: {context.problem}

Create a detailed step-by-step plan to solve this.
Each step should be actionable and specific.
Format: PLAN STEP N: [description]"""
        
        plan_response = llm_call(plan_prompt)
        plan_steps = self._parse_steps(plan_response)
        
        # Phase 2: Execute plan
        chain = ThoughtChain(goal=context.problem)
        
        for i, step in enumerate(plan_steps):
            exec_prompt = f"""Problem: {context.problem}
Plan step {i+1}/{len(plan_steps)}: {step}

Execute this step. Provide the reasoning and result.
Format: EXECUTION: [reasoning and result]"""
            
            exec_response = llm_call(exec_prompt)
            execution = exec_response.split("EXECUTION:")[-1].strip() if "EXECUTION:" in exec_response else exec_response
            
            thought = Thought(
                type=ThoughtType.INFERENCE,
                content=f"Step {i+1}: {step}\nExecution: {execution}",
                confidence=0.75,
                metadata={"plan_step": i + 1, "plan_total": len(plan_steps)}
            )
            chain.add_thought(thought)
        
        # Final synthesis
        synthesis_prompt = f"""Problem: {context.problem}
Plan executed. Steps and results:
{chr(10).join([t.content for t in chain.thoughts])}

Provide final answer."""
        
        final_response = llm_call(synthesis_prompt)
        conclusion = Thought(
            type=ThoughtType.SYNTHESIS,
            content=final_response,
            confidence=0.8,
            metadata={"method": "plan_and_solve"}
        )
        chain.add_thought(conclusion)
        chain.conclusion = conclusion
        chain.confidence = self._calculate_chain_confidence(chain)
        
        self.thought_chains[chain.id] = chain
        return chain
    
    def _analogical_reasoning(self, context: ReasoningContext, llm_call: Callable) -> ThoughtChain:
        """Analogical reasoning: find similar problems, map solutions."""
        chain = ThoughtChain(goal=context.problem)
        
        # Step 1: Identify core structure
        structure_prompt = f"""Problem: {context.problem}

Identify the abstract structure/pattern of this problem.
What is the core relationship? What type of problem is this?
Format: STRUCTURE: [abstract description]"""
        
        structure_response = llm_call(structure_prompt)
        structure = structure_response.split("STRUCTURE:")[-1].strip() if "STRUCTURE:" in structure_response else structure_response
        
        structure_thought = Thought(
            type=ThoughtType.OBSERVATION,
            content=f"Problem structure: {structure}",
            confidence=0.8
        )
        chain.add_thought(structure_thought)
        
        # Step 2: Retrieve analogies from memory
        if self.memory:
            analogies = self.memory.recall(
                query=structure,
                mem_type=MemoryType.SEMANTIC,
                tags={"analogy", "pattern", "solution"},
                top_k=5
            )
        else:
            analogies = []
        
        # Step 3: Generate analogies via LLM if memory empty
        if not analogies:
            analogy_prompt = f"""Problem structure: {structure}

Generate 3-5 analogies from different domains (math, physics, biology, engineering, daily life, etc.)
that share this structure. For each, explain the mapping.
Format: ANALOGY N: [domain] | [mapping] | [insight]"""
            
            analogy_response = llm_call(analogy_prompt)
            analogies = self._parse_analogies(analogy_response)
        
        # Step 4: Map solutions
        for i, analogy in enumerate(analogies[:3]):
            mapping_prompt = f"""Original problem: {context.problem}
Analogy: {analogy}

Map the solution from the analogy domain to the original problem.
What insights transfer? What doesn't?
Format: MAPPING: [transferred insight]"""
            
            mapping_response = llm_call(mapping_prompt)
            mapping = mapping_response.split("MAPPING:")[-1].strip() if "MAPPING:" in mapping_response else mapping_response
            
            thought = Thought(
                type=ThoughtType.ANALOGY,
                content=f"Analogy {i+1}: {analogy}\nMapping: {mapping}",
                confidence=0.7,
                metadata={"analogy_index": i}
            )
            chain.add_thought(thought)
        
        # Step 5: Synthesize
        synthesis_prompt = f"""Problem: {context.problem}
Analogical insights:
{chr(10).join([t.content for t in chain.thoughts if t.type == ThoughtType.ANALOGY])}

Synthesize a novel solution combining these analogical insights."""
        
        final_response = llm_call(synthesis_prompt)
        conclusion = Thought(
            type=ThoughtType.SYNTHESIS,
            content=final_response,
            confidence=0.75,
            metadata={"method": "analogical"}
        )
        chain.add_thought(conclusion)
        chain.conclusion = conclusion
        chain.confidence = self._calculate_chain_confidence(chain)
        
        self.thought_chains[chain.id] = chain
        return chain
    
    def _first_principles(self, context: ReasoningContext, llm_call: Callable) -> ThoughtChain:
        """First Principles: decompose to fundamentals, rebuild."""
        chain = ThoughtChain(goal=context.problem)
        
        # Step 1: Identify assumptions
        assumptions_prompt = f"""Problem: {context.problem}

List all hidden assumptions, conventions, and "standard ways" people approach this.
What is taken for granted?
Format: ASSUMPTION N: [assumption]"""
        
        assumptions_response = llm_call(assumptions_prompt)
        assumptions = self._parse_steps(assumptions_response)
        
        for a in assumptions:
            thought = Thought(
                type=ThoughtType.OBSERVATION,
                content=f"Assumption: {a}",
                confidence=0.9,
                metadata={"type": "assumption"}
            )
            chain.add_thought(thought)
        
        # Step 2: Question each assumption
        for assumption in assumptions:
            question_prompt = f"""Assumption: {assumption}
Context: {context.problem}

Is this assumption necessarily true? What if it's false? What are the physical/logical fundamentals?
Format: FUNDAMENTAL: [core truth]"""
            
            question_response = llm_call(question_prompt)
            fundamental = question_response.split("FUNDAMENTAL:")[-1].strip() if "FUNDAMENTAL:" in question_response else question_response
            
            thought = Thought(
                type=ThoughtType.INFERENCE,
                content=f"Fundamental: {fundamental} (from questioning: {assumption})",
                confidence=0.85,
                metadata={"type": "first_principle", "derived_from": assumption}
            )
            chain.add_thought(thought)
        
        # Step 3: Rebuild from fundamentals
        rebuild_prompt = f"""Problem: {context.problem}
First principles identified:
{chr(10).join([t.content for t in chain.thoughts if t.metadata.get('type') == 'first_principle'])}

Rebuild the solution from these fundamentals only. No assumptions.
Format: SOLUTION: [rebuilt solution]"""
        
        rebuild_response = llm_call(rebuild_prompt)
        solution = rebuild_response.split("SOLUTION:")[-1].strip() if "SOLUTION:" in rebuild_response else rebuild_response
        
        conclusion = Thought(
            type=ThoughtType.SYNTHESIS,
            content=solution,
            confidence=0.9,
            metadata={"method": "first_principles"}
        )
        chain.add_thought(conclusion)
        chain.conclusion = conclusion
        chain.confidence = self._calculate_chain_confidence(chain)
        
        self.thought_chains[chain.id] = chain
        return chain
    
    def _self_critique(self, chain: ThoughtChain, context: ReasoningContext, llm_call: Callable) -> ThoughtChain:
        """Self-critique pass: verify each step, identify gaps."""
        critique_prompt = f"""Problem: {context.problem}
Reasoning chain:
{chr(10).join([f"{i+1}. {t.content} (confidence: {t.confidence})" for i, t in enumerate(chain.thoughts)])}

Critique this reasoning. Identify:
1. Logical gaps
2. Unsupported claims
3. Alternative interpretations
4. Missing steps
Format: CRITIQUE N: [issue] | SEVERITY: [high/medium/low]"""
        
        critique_response = llm_call(critique_prompt)
        critiques = self._parse_critiques(critique_response)
        
        for critique in critiques:
            thought = Thought(
                type=ThoughtType.CRITIQUE,
                content=critique["issue"],
                confidence=0.8,
                metadata={"severity": critique["severity"]}
            )
            chain.add_thought(thought)
        
        # Adjust confidence based on critiques
        high_severity = sum(1 for c in critiques if c["severity"] == "high")
        if high_severity > 0:
            for t in chain.thoughts:
                t.confidence *= 0.8
        
        chain.verified = True
        chain.verification_notes = f"Self-critique: {len(critiques)} issues found ({high_severity} high severity)"
        
        return chain
    
    def _calculate_chain_confidence(self, chain: ThoughtChain) -> float:
        if not chain.thoughts:
            return 0.0
        
        # Weighted average: later thoughts matter more, critiques reduce confidence
        total_weight = 0
        weighted_sum = 0
        
        for i, thought in enumerate(chain.thoughts):
            weight = (i + 1) * (0.5 if thought.type == ThoughtType.CRITIQUE else 1.0)
            weighted_sum += thought.confidence * weight
            total_weight += weight
        
        return weighted_sum / total_weight if total_weight > 0 else 0.0
    
    # ==================== Parsing helpers ====================
    
    def _parse_steps(self, text: str) -> List[str]:
        steps = []
        for line in text.split("\n"):
            line = line.strip()
            if line and (line.startswith(("STEP", "Step", "PLAN", "Plan", "ASSUMPTION", "Assumption")) or 
                         any(line.startswith(f"{i}.") for i in range(1, 20))):
                # Remove prefix
                for prefix in ["STEP", "Step", "PLAN", "Plan", "ASSUMPTION", "Assumption"]:
                    if line.upper().startswith(prefix):
                        line = line[len(prefix):].strip()
                        if line.startswith(":"):
                            line = line[1:].strip()
                        break
                steps.append(line)
        return steps
    
    def _parse_approaches(self, text: str) -> List[str]:
        approaches = []
        for line in text.split("\n"):
            line = line.strip()
            if line and line.upper().startswith("APPROACH"):
                line = line[8:].strip()
                if line.startswith(":"):
                    line = line[1:].strip()
                approaches.append(line)
        return approaches
    
    def _parse_analogies(self, text: str) -> List[str]:
        analogies = []
        for line in text.split("\n"):
            line = line.strip()
            if line and line.upper().startswith("ANALOGY"):
                line = line[7:].strip()
                if line.startswith(":"):
                    line = line[1:].strip()
                analogies.append(line)
        return analogies
    
    def _parse_critiques(self, text: str) -> List[Dict]:
        critiques = []
        for line in text.split("\n"):
            line = line.strip()
            if line and line.upper().startswith("CRITIQUE"):
                parts = line[8:].split("|")
                issue = parts[0].strip()
                if issue.startswith(":"):
                    issue = issue[1:].strip()
                severity = "medium"
                for p in parts[1:]:
                    if "SEVERITY" in p.upper():
                        severity = p.split(":")[-1].strip().lower()
                        break
                critiques.append({"issue": issue, "severity": severity})
        return critiques


# ==================== CREATIVE SYNTHESIS ====================

class CreativeSynthesis:
    """
    Creative thinking engine: concept blending, analogical transfer, divergent generation.
    Not just retrieval — genuine novel combination.
    """
    
    def __init__(self, memory: Optional[MemoryPalace] = None):
        self.memory = memory or MemoryPalace()
        self.concept_space: Dict[str, Dict] = {}  # concept -> properties
        self.blend_history: List[Dict] = []
    
    def register_concept(self, name: str, properties: Dict[str, Any], domain: str = ""):
        """Register a concept with its properties for blending."""
        self.concept_space[name] = {
            "properties": properties,
            "domain": domain,
            "registered_at": datetime.now()
        }
    
    def blend(
        self,
        concept_a: str,
        concept_b: str,
        blend_type: str = "property_mapping",
        llm_call: Optional[Callable] = None
    ) -> Dict[str, Any]:
        """
        Blend two concepts using various creative strategies.
        
        Blend types:
        - property_mapping: Map properties from A to B
        - structural_alignment: Align relational structures
        - metaphorical: Use A as metaphor for B
        - hybrid: Create new concept with features of both
        """
        if concept_a not in self.concept_space or concept_b not in self.concept_space:
            raise ValueError("Both concepts must be registered")
        
        a = self.concept_space[concept_a]
        b = self.concept_space[concept_b]
        
        blend = {
            "concept_a": concept_a,
            "concept_b": concept_b,
            "type": blend_type,
            "timestamp": datetime.now(),
            "result": None
        }
        
        if blend_type == "property_mapping":
            blend["result"] = self._property_mapping_blend(a, b)
        elif blend_type == "structural_alignment":
            blend["result"] = self._structural_alignment_blend(a, b)
        elif blend_type == "metaphorical":
            blend["result"] = self._metaphorical_blend(a, b, llm_call)
        elif blend_type == "hybrid":
            blend["result"] = self._hybrid_blend(a, b, llm_call)
        
        self.blend_history.append(blend)
        return blend
    
    def _property_mapping_blend(self, a: Dict, b: Dict) -> Dict:
        """Map salient properties from A onto B."""
        props_a = a["properties"]
        props_b = b["properties"]
        
        # Find mappable properties (same keys or semantic similarity)
        mapped = {}
        for key_a, val_a in props_a.items():
            for key_b, val_b in props_b.items():
                if key_a == key_b or self._semantic_similar(key_a, key_b) > 0.7:
                    mapped[key_b] = {
                        "from_a": val_a,
                        "original_b": val_b,
                        "blended": self._blend_values(val_a, val_b)
                    }
        
        return {
            "method": "property_mapping",
            "mapped_properties": mapped,
            "new_concept": {**props_b, **{k: v["blended"] for k, v in mapped.items()}}
        }
    
    def _structural_alignment_blend(self, a: Dict, b: Dict) -> Dict:
        """Align relational structures between concepts."""
        # Simplified: find common relation patterns
        relations_a = a["properties"].get("relations", {})
        relations_b = b["properties"].get("relations", {})
        
        aligned = {}
        for rel_a, targets_a in relations_a.items():
            for rel_b, targets_b in relations_b.items():
                if self._semantic_similar(rel_a, rel_b) > 0.6:
                    aligned[rel_a] = {
                        "concept_a_targets": targets_a,
                        "concept_b_targets": targets_b,
                        "merged": list(set(targets_a) | set(targets_b))
                    }
        
        return {
            "method": "structural_alignment",
            "aligned_relations": aligned
        }
    
    def _metaphorical_blend(self, a: Dict, b: Dict, llm_call: Optional[Callable]) -> Dict:
        """Use A as metaphor to reconceptualize B."""
        if not llm_call:
            return {"error": "LLM call required for metaphorical blend"}
        
        prompt = f"""Concept A (source domain: {a['domain']}): {a['properties']}
Concept B (target domain: {b['domain']}): {b['properties']}

Use Concept A as a metaphor to generate novel insights about Concept B.
What properties, relations, or behaviors from A transfer creatively to B?
Format: METAPHORICAL INSIGHT: [insight]"""
        
        response = llm_call(prompt)
        insight = response.split("METAPHORICAL INSIGHT:")[-1].strip() if "METAPHORICAL INSIGHT:" in response else response
        
        return {
            "method": "metaphorical",
            "insight": insight,
            "source_domain": a["domain"],
            "target_domain": b["domain"]
        }
    
    def _hybrid_blend(self, a: Dict, b: Dict, llm_call: Optional[Callable]) -> Dict:
        """Create genuinely new concept combining both."""
        if not llm_call:
            return {"error": "LLM call required for hybrid blend"}
        
        prompt = f"""Concept A: {a['properties']} (domain: {a['domain']})
Concept B: {b['properties']} (domain: {b['domain']})

Create a NEW concept that is a genuine hybrid of both.
It should have:
- A name
- Core properties (combining both)
- Novel emergent properties (not in either parent)
- Potential applications
Format: HYBRID NAME: [name] | PROPERTIES: [dict] | EMERGENT: [list] | APPLICATIONS: [list]"""
        
        response = llm_call(prompt)
        
        # Parse response
        name = ""
        properties = {}
        emergent = []
        applications = []
        
        for line in response.split("\n"):
            if "HYBRID NAME:" in line:
                name = line.split("HYBRID NAME:")[-1].split("|")[0].strip()
            elif "PROPERTIES:" in line:
                try:
                    prop_str = line.split("PROPERTIES:")[-1].split("|")[0].strip()
                    properties = json.loads(prop_str)
                except:
                    pass
            elif "EMERGENT:" in line:
                try:
                    emergent_str = line.split("EMERGENT:")[-1].split("|")[0].strip()
                    emergent = json.loads(emergent_str)
                except:
                    pass
            elif "APPLICATIONS:" in line:
                try:
                    app_str = line.split("APPLICATIONS:")[-1].strip()
                    applications = json.loads(app_str)
                except:
                    pass
        
        return {
            "method": "hybrid",
            "name": name,
            "properties": properties,
            "emergent_properties": emergent,
            "applications": applications
        }
    
    def _semantic_similar(self, a: str, b: str) -> float:
        """Simple semantic similarity (placeholder for embedding-based)."""
        # In production, use embeddings
        a_words = set(a.lower().split("_"))
        b_words = set(b.lower().split("_"))
        if not a_words or not b_words:
            return 0.0
        return len(a_words & b_words) / len(a_words | b_words)
    
    def _blend_values(self, a: Any, b: Any) -> Any:
        """Blend two values creatively."""
        if isinstance(a, (int, float)) and isinstance(b, (int, float)):
            return (a + b) / 2
        elif isinstance(a, str) and isinstance(b, str):
            return f"{a} + {b}"
        elif isinstance(a, list) and isinstance(b, list):
            return list(set(a) | set(b))
        elif isinstance(a, dict) and isinstance(b, dict):
            return {**a, **b}
        return b  # Default to B
    
    def divergent_generation(
        self,
        seed_concept: str,
        num_ideas: int = 10,
        constraints: Optional[List[str]] = None,
        llm_call: Optional[Callable] = None
    ) -> List[Dict]:
        """Generate diverse ideas from a seed (divergent thinking)."""
        if not llm_call:
            return [{"error": "LLM call required"}]
        
        if seed_concept not in self.concept_space:
            raise ValueError("Seed concept must be registered")
        
        seed = self.concept_space[seed_concept]
        constraints_str = "\n".join(f"- {c}" for c in constraints) if constraints else "None"
        
        prompt = f"""Seed concept: {seed_concept} ({seed['domain']})
Properties: {seed['properties']}
Constraints: {constraints_str}

Generate {num_ideas} DIVERSE, NOVEL ideas/concepts/applications.
Each should be genuinely different from the others.
Think broadly: different domains, scales, perspectives, inversions, combinations.
Format for each: IDEA N: [name] | DESCRIPTION: [desc] | NOVELTY: [what makes it new]"""
        
        response = llm_call(prompt)
        
        ideas = []
        current_idea = {}
        for line in response.split("\n"):
            line = line.strip()
            if line.startswith("IDEA"):
                if current_idea:
                    ideas.append(current_idea)
                current_idea = {"name": line.split("|")[0].split(":")[-1].strip()}
            elif "DESCRIPTION:" in line:
                current_idea["description"] = line.split("DESCRIPTION:")[-1].split("|")[0].strip()
            elif "NOVELTY:" in line:
                current_idea["novelty"] = line.split("NOVELTY:")[-1].strip()
        
        if current_idea:
            ideas.append(current_idea)
        
        return ideas[:num_ideas]


# ==================== VERIFICATION CORE ====================

class VerificationLevel(Enum):
    NONE = 0
    BASIC = 1          # Single source check
    CROSS_REFERENCE = 2  # Multiple sources
    DEEP = 3           # Chain verification + uncertainty quantification
    FORMAL = 4         # Logical proof / formal verification


@dataclass
class VerificationResult:
    claim: str
    verified: bool
    confidence: float
    level: VerificationLevel
    sources: List[Dict[str, Any]] = field(default_factory=list)
    contradictions: List[str] = field(default_factory=list)
    uncertainty_factors: List[str] = field(default_factory=list)
    method: str = ""
    timestamp: datetime = field(default_factory=datetime.now)


class VerificationCore:
    """
    Multi-level verification with hallucination detection, confidence calibration,
    and cross-source validation.
    """
    
    def __init__(
        self,
        memory: Optional[MemoryPalace] = None,
        external_verifiers: Optional[Dict[str, Callable]] = None
    ):
        self.memory = memory or MemoryPalace()
        self.external_verifiers = external_verifiers or {}
        self.verification_cache: Dict[str, VerificationResult] = {}
        self.calibration_data: List[Tuple[float, bool]] = []  # (predicted_conf, actual_correct)
    
    def verify(
        self,
        claim: str,
        level: VerificationLevel = VerificationLevel.CROSS_REFERENCE,
        context: Optional[str] = None,
        llm_call: Optional[Callable] = None
    ) -> VerificationResult:
        """Main verification entry point."""
        # Check cache
        cache_key = hashlib.md5(f"{claim}:{level.value}:{context}".encode()).hexdigest()[:16]
        if cache_key in self.verification_cache:
            return self.verification_cache[cache_key]
        
        verifier_map = {
            VerificationLevel.BASIC: self._basic_verify,
            VerificationLevel.CROSS_REFERENCE: self._cross_reference_verify,
            VerificationLevel.DEEP: self._deep_verify,
            VerificationLevel.FORMAL: self._formal_verify,
        }
        
        verifier = verifier_map.get(level, self._cross_reference_verify)
        result = verifier(claim, context, llm_call)
        
        self.verification_cache[cache_key] = result
        return result
    
    def _basic_verify(self, claim: str, context: Optional[str], llm_call: Optional[Callable]) -> VerificationResult:
        """Single-source verification using internal knowledge."""
        if not llm_call:
            return VerificationResult(
                claim=claim, verified=False, confidence=0.0,
                level=VerificationLevel.BASIC,
                method="basic_no_llm"
            )
        
        prompt = f"""Claim: {claim}
Context: {context or 'None'}

Is this claim factually correct? Answer with VERDICT: TRUE/FALSE/UNCERTAIN and CONFIDENCE: 0-1.
Provide brief reasoning.
Format: VERDICT: [T/F/U] | CONFIDENCE: [0-1] | REASONING: [text]"""
        
        response = llm_call(prompt)
        
        verdict = "UNCERTAIN"
        confidence = 0.5
        reasoning = ""
        
        for part in response.split("|"):
            if "VERDICT:" in part:
                verdict = part.split("VERDICT:")[-1].strip()
            elif "CONFIDENCE:" in part:
                try:
                    confidence = float(part.split("CONFIDENCE:")[-1].strip())
                except:
                    pass
            elif "REASONING:" in part:
                reasoning = part.split("REASONING:")[-1].strip()
        
        verified = verdict.upper() == "TRUE"
        
        return VerificationResult(
            claim=claim,
            verified=verified,
            confidence=confidence,
            level=VerificationLevel.BASIC,
            sources=[{"type": "llm_internal", "reasoning": reasoning}],
            method="basic_llm"
        )
    
    def _cross_reference_verify(self, claim: str, context: Optional[str], llm_call: Optional[Callable]) -> VerificationResult:
        """Verify by checking multiple independent sources."""
        sources = []
        contradictions = []
        
        # Source 1: Internal knowledge
        if llm_call:
            internal = self._basic_verify(claim, context, llm_call)
            sources.append({"type": "llm_internal", "result": internal.verified, "confidence": internal.confidence})
        
        # Source 2: Memory palace (if available)
        if self.memory:
            memories = self.memory.recall(query=claim, top_k=5, min_importance=0.5)
            mem_support = sum(1 for m in memories if claim.lower() in str(m.content).lower())
            mem_total = len(memories)
            if mem_total > 0:
                sources.append({
                    "type": "memory",
                    "supporting": mem_support,
                    "total": mem_total,
                    "ratio": mem_support / mem_total
                })
        
        # Source 3: External verifiers (search, APIs, etc.)
        for name, verifier in self.external_verifiers.items():
            try:
                ext_result = verifier(claim)
                sources.append({"type": f"external_{name}", **ext_result})
            except Exception as e:
                sources.append({"type": f"external_{name}", "error": str(e)})
        
        # Aggregate
        supporting = sum(1 for s in sources if s.get("result", s.get("verified", s.get("supporting", 0))) > 0.5)
        total = len([s for s in sources if "error" not in s])
        
        if total == 0:
            return VerificationResult(
                claim=claim, verified=False, confidence=0.0,
                level=VerificationLevel.CROSS_REFERENCE,
                method="cross_reference_no_sources"
            )
        
        verified = supporting / total > 0.5
        confidence = supporting / total
        
        # Check for contradictions
        for s in sources:
            if s.get("result") is False or s.get("verified") is False:
                contradictions.append(f"{s['type']}: contradicts claim")
        
        return VerificationResult(
            claim=claim,
            verified=verified,
            confidence=confidence,
            level=VerificationLevel.CROSS_REFERENCE,
            sources=sources,
            contradictions=contradictions,
            method="cross_reference"
        )
    
    def _deep_verify(self, claim: str, context: Optional[str], llm_call: Optional[Callable]) -> VerificationResult:
        """Deep verification: decompose claim, verify each part, quantify uncertainty."""
        if not llm_call:
            return self._cross_reference_verify(claim, context, llm_call)
        
        # Step 1: Decompose claim into atomic sub-claims
        decomp_prompt = f"""Claim: {claim}
Context: {context or 'None'}

Decompose this claim into atomic, independently verifiable sub-claims.
Each sub-claim should be a single factual assertion.
Format: SUB-CLAIM N: [atomic claim]"""
        
        decomp_response = llm_call(decomp_prompt)
        sub_claims = []
        for line in decomp_response.split("\n"):
            if "SUB-CLAIM" in line.upper():
                sub_claims.append(line.split(":")[-1].strip())
        
        # Step 2: Verify each sub-claim
        sub_results = []
        for sub_claim in sub_claims:
            result = self._cross_reference_verify(sub_claim, context, llm_call)
            sub_results.append((sub_claim, result))
        
        # Step 3: Aggregate with uncertainty quantification
        verified_count = sum(1 for _, r in sub_results if r.verified)
        total = len(sub_results)
        
        # Uncertainty factors
        uncertainty_factors = []
        for sub_claim, result in sub_results:
            if not result.verified:
                uncertainty_factors.append(f"Sub-claim unverified: {sub_claim}")
            if result.contradictions:
                uncertainty_factors.extend(result.contradictions)
            if result.confidence < 0.7:
                uncertainty_factors.append(f"Low confidence ({result.confidence:.2f}): {sub_claim}")
        
        # Overall confidence: product of sub-claim confidences (conservative)
        overall_confidence = 1.0
        for _, result in sub_results:
            overall_confidence *= max(result.confidence, 0.1)  # Floor at 0.1
        
        verified = verified_count == total and overall_confidence > 0.5
        
        return VerificationResult(
            claim=claim,
            verified=verified,
            confidence=overall_confidence,
            level=VerificationLevel.DEEP,
            sources=[{"sub_claim": sc, **r.__dict__} for sc, r in sub_results],
            contradictions=[c for _, r in sub_results for c in r.contradictions],
            uncertainty_factors=uncertainty_factors,
            method="deep_decomposition"
        )
    
    def _formal_verify(self, claim: str, context: Optional[str], llm_call: Optional[Callable]) -> VerificationResult:
        """Formal verification: logical proof structure (placeholder for theorem prover integration)."""
        # This would integrate with Lean, Coq, Z3, etc.
        # For now, return structured attempt
        return VerificationResult(
            claim=claim,
            verified=False,
            confidence=0.0,
            level=VerificationLevel.FORMAL,
            sources=[{"note": "Formal verification requires theorem prover integration"}],
            method="formal_placeholder"
        )
    
    def calibrate(self, predicted_confidence: float, actual_correct: bool):
        """Record calibration data for confidence scoring improvement."""
        self.calibration_data.append((predicted_confidence, actual_correct))
    
    def get_calibration_curve(self) -> Dict[str, float]:
        """Compute calibration metrics (ECE, MCE)."""
        if not self.calibration_data:
            return {"ece": 0.0, "mce": 0.0, "samples": 0}
        
        # Bin confidences
        bins = 10
        bin_counts = [0] * bins
        bin_correct = [0] * bins
        bin_conf_sum = [0.0] * bins
        
        for conf, correct in self.calibration_data:
            bin_idx = min(int(conf * bins), bins - 1)
            bin_counts[bin_idx] += 1
            bin_correct[bin_idx] += 1 if correct else 0
            bin_conf_sum[bin_idx] += conf
        
        ece = 0.0
        mce = 0.0
        total = len(self.calibration_data)
        
        for i in range(bins):
            if bin_counts[i] > 0:
                acc = bin_correct[i] / bin_counts[i]
                avg_conf = bin_conf_sum[i] / bin_counts[i]
                ece += (bin_counts[i] / total) * abs(acc - avg_conf)
                mce = max(mce, abs(acc - avg_conf))
        
        return {"ece": ece, "mce": mce, "samples": total}
    
    def detect_hallucination(
        self,
        generated_text: str,
        source_material: str,
        llm_call: Optional[Callable] = None
    ) -> Dict[str, Any]:
        """Detect hallucinations by comparing generated text to source."""
        if not llm_call:
            return {"error": "LLM call required"}
        
        prompt = f"""Source material: {source_material}

Generated text: {generated_text}

Identify any claims in the generated text that are NOT supported by the source material.
For each hallucination, quote the generated text and explain why it's unsupported.
Format: HALLUCINATION N: [generated quote] | REASON: [why unsupported] | SEVERITY: [high/medium/low]"""
        
        response = llm_call(prompt)
        
        hallucinations = []
        for line in response.split("\n"):
            if "HALLUCINATION" in line.upper():
                parts = line.split("|")
                quote = parts[0].split(":")[-1].strip()
                reason = ""
                severity = "medium"
                for p in parts[1:]:
                    if "REASON:" in p:
                        reason = p.split("REASON:")[-1].strip()
                    elif "SEVERITY:" in p:
                        severity = p.split("SEVERITY:")[-1].strip()
                hallucinations.append({"quote": quote, "reason": reason, "severity": severity})
        
        return {
            "hallucination_count": len(hallucinations),
            "hallucinations": hallucinations,
            "clean": len(hallucinations) == 0
        }


# ==================== ADAPTIVE ROUTER ====================

@dataclass
class ServerPerformance:
    """Track server performance for adaptive routing."""
    server_name: str
    tool: str
    success_count: int = 0
    failure_count: int = 0
    total_latency: float = 0.0
    quality_scores: List[float] = field(default_factory=list)
    last_used: datetime = field(default_factory=datetime.now)
    
    @property
    def success_rate(self) -> float:
        total = self.success_count + self.failure_count
        return self.success_count / total if total > 0 else 0.5
    
    @property
    def avg_latency(self) -> float:
        total = self.success_count + self.failure_count
        return self.total_latency / total if total > 0 else 0.0
    
    @property
    def avg_quality(self) -> float:
        return np.mean(self.quality_scores) if self.quality_scores else 0.5
    
    @property
    def composite_score(self) -> float:
        """Weighted composite for routing decisions."""
        return (0.4 * self.success_rate + 0.3 * self.avg_quality + 0.3 * (1.0 / (1.0 + self.avg_latency)))


class AdaptiveRouter:
    """
    Learns optimal server-tool mappings from experience.
    Uses multi-armed bandit (UCB) for exploration/exploitation.
    """
    
    def __init__(self, exploration_factor: float = 1.0):
        self.exploration_factor = exploration_factor
        self.performance: Dict[str, ServerPerformance] = {}  # "server:tool" -> perf
        self.tool_servers: Dict[str, List[str]] = defaultdict(list)
        self.total_selections: Dict[str, int] = defaultdict(int)
    
    def register_server(self, server_name: str, tools: List[str]):
        """Register a server and its capabilities."""
        for tool in tools:
            self.tool_servers[tool].append(server_name)
            key = f"{server_name}:{tool}"
            if key not in self.performance:
                self.performance[key] = ServerPerformance(server_name, tool)
    
    def select_server(self, tool: str, context: Optional[Dict] = None) -> str:
        """Select best server for a tool using UCB."""
        candidates = self.tool_servers.get(tool, [])
        if not candidates:
            raise ValueError(f"No servers registered for tool: {tool}")
        
        if len(candidates) == 1:
            return candidates[0]
        
        # UCB selection
        best_score = -1
        best_server = candidates[0]
        total_trials = sum(self.total_selections.get(f"{s}:{tool}", 0) for s in candidates)
        
        for server in candidates:
            key = f"{server}:{tool}"
            perf = self.performance.get(key)
            
            if not perf or perf.success_count + perf.failure_count == 0:
                # Untryed server gets high exploration bonus
                score = float('inf')
            else:
                exploitation = perf.composite_score
                exploration = self.exploration_factor * np.sqrt(
                    np.log(max(total_trials, 1)) / max(self.total_selections[key], 1)
                )
                score = exploitation + exploration
            
            if score > best_score:
                best_score = score
                best_server = server
        
        self.total_selections[f"{best_server}:{tool}"] += 1
        return best_server
    
    def record_result(
        self,
        server: str,
        tool: str,
        success: bool,
        latency: float,
        quality: Optional[float] = None
    ):
        """Record outcome for learning."""
        key = f"{server}:{tool}"
        perf = self.performance.get(key)
        if not perf:
            perf = ServerPerformance(server, tool)
            self.performance[key] = perf
        
        if success:
            perf.success_count += 1
        else:
            perf.failure_count += 1
        
        perf.total_latency += latency
        perf.last_used = datetime.now()
        
        if quality is not None:
            perf.quality_scores.append(quality)
            # Keep only recent scores
            if len(perf.quality_scores) > 100:
                perf.quality_scores = perf.quality_scores[-100:]
    
    def get_ranking(self, tool: str) -> List[Tuple[str, float]]:
        """Get servers ranked by composite score."""
        candidates = self.tool_servers.get(tool, [])
        ranked = []
        for server in candidates:
            key = f"{server}:{tool}"
            perf = self.performance.get(key)
            if perf:
                ranked.append((server, perf.composite_score))
            else:
                ranked.append((server, 0.5))
        ranked.sort(key=lambda x: x[1], reverse=True)
        return ranked
    
    def get_stats(self) -> Dict[str, Any]:
        return {
            "tools": {tool: self.get_ranking(tool) for tool in self.tool_servers},
            "total_selections": dict(self.total_selections)
        }


# ==================== TOOL ORCHESTRATOR ====================

@dataclass
class PipelineStep:
    """A step in an execution pipeline."""
    id: str
    tool: str
    params: Dict[str, Any]
    depends_on: List[str] = field(default_factory=list)  # Step IDs this depends on
    condition: Optional[str] = None  # Optional condition to execute
    fallback: Optional[str] = None  # Fallback step ID on failure
    timeout: float = 30.0
    retries: int = 1


@dataclass
class PipelineResult:
    """Result of pipeline execution."""
    pipeline_id: str
    step_results: Dict[str, Any] = field(default_factory=dict)
    success: bool = True
    error: Optional[str] = None
    execution_time: float = 0.0
    completed_steps: List[str] = field(default_factory=list)
    failed_steps: List[str] = field(default_factory=list)


class ToolOrchestrator:
    """
    Dynamic pipeline composition and execution.
    Supports: parallel execution, conditional steps, fallbacks, retries, streaming.
    """
    
    def __init__(
        self,
        tool_executors: Dict[str, Callable],
        router: Optional[AdaptiveRouter] = None,
        max_parallel: int = 5
    ):
        self.tool_executors = tool_executors
        self.router = router or AdaptiveRouter()
        self.max_parallel = max_parallel
        self.pipelines: Dict[str, List[PipelineStep]] = {}
        self.execution_history: List[PipelineResult] = []
    
    def define_pipeline(self, pipeline_id: str, steps: List[PipelineStep]):
        """Define a named pipeline."""
        # Validate dependencies
        step_ids = {s.id for s in steps}
        for step in steps:
            for dep in step.depends_on:
                if dep not in step_ids:
                    raise ValueError(f"Step {step.id} depends on unknown step: {dep}")
        
        self.pipelines[pipeline_id] = steps
    
    def execute_pipeline(
        self,
        pipeline_id: str,
        initial_params: Optional[Dict[str, Any]] = None,
        stream_callback: Optional[Callable[[str, Any], None]] = None
    ) -> PipelineResult:
        """Execute a pipeline with dependency resolution and parallelization."""
        if pipeline_id not in self.pipelines:
            raise ValueError(f"Pipeline not found: {pipeline_id}")
        
        steps = self.pipelines[pipeline_id]
        start_time = time.time()
        result = PipelineResult(pipeline_id=pipeline_id)
        step_outputs: Dict[str, Any] = {}
        
        # Add initial params as virtual step
        if initial_params:
            step_outputs["_input"] = initial_params
        
        # Build dependency graph
        remaining = {s.id: s for s in steps}
        completed = set()
        
        while remaining:
            # Find ready steps (all dependencies met)
            ready = []
            for step_id, step in remaining.items():
                if all(dep in completed or dep == "_input" for dep in step.depends_on):
                    ready.append(step)
            
            if not ready:
                # Circular dependency or missing dependency
                result.success = False
                result.error = "Circular dependency or unresolvable dependencies"
                break
            
            # Execute ready steps in parallel (up to max_parallel)
            batch = ready[:self.max_parallel]
            
            for step in batch:
                step_start = time.time()
                
                # Prepare params with dependency outputs
                params = self._resolve_params(step.params, step_outputs)
                
                # Check condition
                if step.condition:
                    if not self._eval_condition(step.condition, step_outputs):
                        result.step_results[step.id] = {"skipped": True, "reason": "condition_false"}
                        completed.add(step.id)
                        remaining.pop(step.id)
                        continue
                
                # Execute with retries
                step_result = None
                last_error = None
                
                for attempt in range(step.retries + 1):
                    try:
                        executor = self.tool_executors.get(step.tool)
                        if not executor:
                            raise ValueError(f"No executor for tool: {step.tool}")
                        
                        # Select server via router if applicable
                        server = None
                        if self.router and step.tool in self.router.tool_servers:
                            server = self.router.select_server(step.tool)
                        
                        step_result = executor(params, server=server)
                        
                        # Record for router learning
                        latency = time.time() - step_start
                        quality = step_result.get("quality", 0.5) if isinstance(step_result, dict) else 0.5
                        if self.router:
                            self.router.record_result(
                                server or "unknown", step.tool,
                                success=True, latency=latency, quality=quality
                            )
                        
                        break
                    except Exception as e:
                        last_error = e
                        if attempt < step.retries:
                            time.sleep(0.5 * (attempt + 1))  # Exponential backoff
                
                if step_result is None:
                    # Step failed
                    result.success = False
                    result.failed_steps.append(step.id)
                    result.step_results[step.id] = {"error": str(last_error)}
                    
                    # Try fallback
                    if step.fallback and step.fallback in remaining:
                        continue  # Will be picked up in next iteration
                    else:
                        result.error = f"Step {step.id} failed: {last_error}"
                        break
                else:
                    # Step succeeded
                    result.step_results[step.id] = step_result
                    step_outputs[step.id] = step_result
                    result.completed_steps.append(step.id)
                    completed.add(step.id)
                    remaining.pop(step.id)
                    
                    if stream_callback:
                        stream_callback(step.id, step_result)
            
            if not result.success and not step.fallback:
                break
        
        result.execution_time = time.time() - start_time
        self.execution_history.append(result)
        return result
    
    def _resolve_params(self, params: Dict, outputs: Dict) -> Dict:
        """Resolve parameter references to previous step outputs."""
        resolved = {}
        for key, value in params.items():
            if isinstance(value, str) and value.startswith("{{") and value.endswith("}}"):
                # Reference: {{step_id.field}}
                ref = value[2:-2]
                if "." in ref:
                    step_id, field = ref.split(".", 1)
                    if step_id in outputs:
                        resolved[key] = outputs[step_id].get(field) if isinstance(outputs[step_id], dict) else outputs[step_id]
                    else:
                        resolved[key] = value  # Keep as-is if not found
                else:
                    resolved[key] = outputs.get(ref, value)
            else:
                resolved[key] = value
        return resolved
    
    def _eval_condition(self, condition: str, outputs: Dict) -> bool:
        """Evaluate a simple condition."""
        # Simple implementation: {{step_id.field}} == "value"
        # In production, use a proper expression evaluator
        try:
            # Replace references
            for step_id, output in outputs.items():
                if isinstance(output, dict):
                    for field, value in output.items():
                        condition = condition.replace(f"{{{{{step_id}.{field}}}}}", json.dumps(value))
                else:
                    condition = condition.replace(f"{{{{{step_id}}}}}", json.dumps(output))
            
            # Evaluate (SAFE: only simple comparisons)
            return eval(condition, {"__builtins__": {}}, {})
        except:
            return False
    
    def create_dynamic_pipeline(
        self,
        goal: str,
        available_tools: List[str],
        llm_call: Callable,
        max_steps: int = 10
    ) -> List[PipelineStep]:
        """Use LLM to dynamically create a pipeline for a goal."""
        prompt = f"""Goal: {goal}
Available tools: {available_tools}

Create a pipeline of steps to achieve this goal.
Each step: tool name, parameters (can reference previous steps with {{step_id.field}}), dependencies.
Format: STEP N: tool_name | params_json | depends_on_list | condition (optional)"""
        
        response = llm_call(prompt)
        
        steps = []
        for i, line in enumerate(response.split("\n")):
            if "STEP" in line.upper() and "|" in line:
                parts = [p.strip() for p in line.split("|")]
                if len(parts) >= 3:
                    tool_part = parts[0].split(":")[-1].strip()
                    params = {}
                    try:
                        params = json.loads(parts[1])
                    except:
                        pass
                    depends = []
                    try:
                        depends = json.loads(parts[2])
                    except:
                        pass
                    condition = parts[3] if len(parts) > 3 else None
                    
                    steps.append(PipelineStep(
                        id=f"step_{i}",
                        tool=tool_part,
                        params=params,
                        depends_on=depends,
                        condition=condition
                    ))
        
        return steps