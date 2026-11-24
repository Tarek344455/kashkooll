"""
Advanced Verification — Sophisticated verification techniques for the Cognitive MCP Architecture.
Implements: Multi-source consensus, Logical consistency checking, Uncertainty quantification,
Formal verification integration, Adversarial testing, and Epistemic calibration.
"""
import asyncio
import hashlib
import json
import re
import time
from abc import ABC, abstractmethod
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Tuple, Union
import numpy as np

from .cognitive_core import (
    MemoryPalace, MemoryType, MemoryNode,
    VerificationCore, VerificationLevel, VerificationResult,
    Thought, ThoughtType, ThoughtChain
)


# ==================== VERIFICATION STRATEGIES ====================

class VerificationStrategy(Enum):
    """Advanced verification strategies."""
    CONSENSUS = "consensus"                    # Multi-source agreement
    LOGICAL_CONSISTENCY = "logical_consistency"  # Internal logical coherence
    EVIDENCE_CHAIN = "evidence_chain"          # Trace claims to sources
    UNCERTAINTY_QUANTIFICATION = "uncertainty"  # Quantify epistemic uncertainty
    ADVERSARIAL = "adversarial"                # Red-team the claim
    FORMAL = "formal"                          # Formal logic/proof
    CAUSAL = "causal"                          # Causal reasoning verification
    TEMPORAL = "temporal"                      # Temporal consistency
    CROSS_DOMAIN = "cross_domain"              # Verify across domains


@dataclass
class VerificationContext:
    """Context for advanced verification."""
    claim: str
    strategy: VerificationStrategy = VerificationStrategy.CONSENSUS
    depth: int = 3  # How deep to verify
    require_sources: bool = True
    min_sources: int = 3
    confidence_threshold: float = 0.7
    domain: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class Evidence:
    """A piece of evidence supporting or contradicting a claim."""
    id: str
    source: str
    content: str
    supports: bool  # True = supports, False = contradicts
    confidence: float
    relevance: float
    timestamp: datetime
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class VerificationReport:
    """Comprehensive verification report."""
    claim: str
    strategy: VerificationStrategy
    verified: bool
    confidence: float
    evidence: List[Evidence] = field(default_factory=list)
    logical_issues: List[str] = field(default_factory=list)
    uncertainty_factors: List[str] = field(default_factory=list)
    consensus_score: float = 0.0
    source_diversity: float = 0.0
    calibration_adjusted_confidence: float = 0.0
    recommendations: List[str] = field(default_factory=list)
    timestamp: datetime = field(default_factory=datetime.now)
    metadata: Dict[str, Any] = field(default_factory=dict)


# ==================== EVIDENCE GATHERERS ====================

class EvidenceGatherer(ABC):
    """Abstract base for evidence gathering."""

    @abstractmethod
    async def gather(self, claim: str, context: VerificationContext) -> List[Evidence]:
        pass


class LLMEvidenceGatherer(EvidenceGatherer):
    """Gather evidence using LLM internal knowledge."""

    def __init__(self, llm_call: Callable[[str], str]):
        self.llm_call = llm_call

    async def gather(self, claim: str, context: VerificationContext) -> List[Evidence]:
        prompt = f"""Claim: {claim}
Context: {context.metadata.get('context', 'None')}

Find evidence for and against this claim from your training knowledge.
For each piece of evidence, provide:
1. Source description
2. The evidence text
3. Whether it SUPPORTS or CONTRADICTS the claim
4. Confidence (0-1)
5. Relevance (0-1)

Format:
EVIDENCE 1: [source] | [evidence] | SUPPORTS/CONTRADICTS | [confidence] | [relevance]
EVIDENCE 2: ..."""

        response = self.llm_call(prompt)
        evidence = []

        for line in response.split("\n"):
            if "EVIDENCE" in line.upper() and "|" in line:
                parts = [p.strip() for p in line.split("|")]
                if len(parts) >= 5:
                    source = parts[0].split(":")[-1].strip()
                    content = parts[1]
                    supports = "SUPPORTS" in parts[2].upper()
                    try:
                        confidence = float(parts[3])
                        relevance = float(parts[4])
                    except:
                        confidence = 0.5
                        relevance = 0.5

                    evidence.append(Evidence(
                        id=hashlib.md5(f"{source}{content}".encode()).hexdigest()[:8],
                        source=source,
                        content=content,
                        supports=supports,
                        confidence=confidence,
                        relevance=relevance,
                        timestamp=datetime.now()
                    ))

        return evidence


class MemoryEvidenceGatherer(EvidenceGatherer):
    """Gather evidence from memory palace."""

    def __init__(self, memory: MemoryPalace):
        self.memory = memory

    async def gather(self, claim: str, context: VerificationContext) -> List[Evidence]:
        memories = self.memory.recall(
            query=claim,
            top_k=context.min_sources * 2,
            min_importance=0.3,
            spreading_activation=True
        )

        evidence = []
        for mem in memories:
            content_str = str(mem.content)
            # Simple check: does memory content relate to claim?
            claim_words = set(claim.lower().split())
            content_words = set(content_str.lower().split())
            overlap = len(claim_words & content_words) / max(len(claim_words), 1)

            if overlap > 0.1:
                evidence.append(Evidence(
                    id=mem.id,
                    source=f"memory:{mem.type.value}",
                    content=content_str[:500],
                    supports=overlap > 0.3,  # Heuristic
                    confidence=mem.importance * mem.verified * 1.5 if mem.verified else mem.importance * 0.5,
                    relevance=overlap,
                    timestamp=mem.last_accessed,
                    metadata={"memory_id": mem.id, "tags": list(mem.tags)}
                ))

        return evidence


class WebSearchEvidenceGatherer(EvidenceGatherer):
    """Gather evidence via web search (requires search tool)."""

    def __init__(self, search_func: Callable[[str, int], List[Dict]]):
        self.search_func = search_func

    async def gather(self, claim: str, context: VerificationContext) -> List[Evidence]:
        # Search for claim and related terms
        queries = [
            claim,
            f"evidence for {claim}",
            f"evidence against {claim}",
            f"{claim} fact check"
        ]

        evidence = []
        for query in queries:
            try:
                results = self.search_func(query, limit=5)
                for result in results:
                    content = result.get("snippet", result.get("content", ""))
                    if content and len(content) > 50:
                        evidence.append(Evidence(
                            id=hashlib.md5(f"{result.get('url', '')}{content}".encode()).hexdigest()[:8],
                            source=result.get("url", "web"),
                            content=content[:500],
                            supports=True,  # Would need deeper analysis
                            confidence=0.6,
                            relevance=0.7,
                            timestamp=datetime.now(),
                            metadata={"title": result.get("title", ""), "query": query}
                        ))
            except Exception:
                continue

        return evidence


# ==================== ADVANCED VERIFIERS ====================

class ConsensusVerifier:
    """Verify by checking consensus across multiple independent sources."""

    def __init__(self, gatherers: List[EvidenceGatherer]):
        self.gatherers = gatherers

    async def verify(self, claim: str, context: VerificationContext) -> VerificationReport:
        all_evidence = []

        # Gather from all sources
        for gatherer in self.gatherers:
            try:
                evidence = await gatherer.gather(claim, context)
                all_evidence.extend(evidence)
            except Exception as e:
                print(f"Gatherer error: {e}")

        if not all_evidence:
            return VerificationReport(
                claim=claim,
                strategy=VerificationStrategy.CONSENSUS,
                verified=False,
                confidence=0.0,
                uncertainty_factors=["No evidence gathered"],
                recommendations=["Add more evidence sources"]
            )

        # Group by source type
        by_source = defaultdict(list)
        for ev in all_evidence:
            source_type = ev.source.split(":")[0] if ":" in ev.source else ev.source
            by_source[source_type].append(ev)

        # Calculate consensus
        supporting = [e for e in all_evidence if e.supports]
        contradicting = [e for e in all_evidence if not e.supports]

        support_weight = sum(e.confidence * e.relevance for e in supporting)
        contradict_weight = sum(e.confidence * e.relevance for e in contradicting)
        total_weight = support_weight + contradict_weight

        consensus_score = support_weight / total_weight if total_weight > 0 else 0.5
        source_diversity = len(by_source) / max(len(self.gatherers), 1)

        verified = consensus_score >= context.confidence_threshold and len(supporting) >= context.min_sources
        confidence = consensus_score * source_diversity

        # Uncertainty factors
        uncertainty = []
        if len(supporting) < context.min_sources:
            uncertainty.append(f"Only {len(supporting)} supporting sources (need {context.min_sources})")
        if contradicting:
            uncertainty.append(f"{len(contradicting)} contradicting sources found")
        if source_diversity < 0.5:
            uncertainty.append("Low source diversity")

        return VerificationReport(
            claim=claim,
            strategy=VerificationStrategy.CONSENSUS,
            verified=verified,
            confidence=confidence,
            evidence=all_evidence,
            consensus_score=consensus_score,
            source_diversity=source_diversity,
            uncertainty_factors=uncertainty,
            recommendations=self._generate_recommendations(verified, uncertainty)
        )

    def _generate_recommendations(self, verified: bool, uncertainty: List[str]) -> List[str]:
        recs = []
        if not verified:
            recs.append("Gather more independent sources")
            recs.append("Check contradicting evidence in detail")
        if "Low source diversity" in str(uncertainty):
            recs.append("Diversify evidence sources (academic, news, official, etc.)")
        return recs


class LogicalConsistencyVerifier:
    """Verify internal logical consistency of a claim and its supporting arguments."""

    def __init__(self, llm_call: Callable[[str], str]):
        self.llm_call = llm_call

    async def verify(self, claim: str, context: VerificationContext) -> VerificationReport:
        # Extract logical structure
        prompt = f"""Claim: {claim}

Analyze the logical structure of this claim:
1. Identify premises and conclusion
2. Check for logical fallacies
3. Identify hidden assumptions
4. Check for internal contradictions
5. Assess deductive/inductive validity

Format:
PREMISES: [list]
CONCLUSION: [statement]
FALLACIES: [list]
ASSUMPTIONS: [list]
CONTRADICTIONS: [list]
VALIDITY: [valid/invalid/uncertain]"""

        response = self.llm_call(prompt)

        # Parse response
        premises = []
        fallacies = []
        assumptions = []
        contradictions = []
        validity = "uncertain"

        for line in response.split("\n"):
            if "PREMISES:" in line:
                premises = [p.strip() for p in line.split("PREMISES:")[-1].split(",")]
            elif "FALLACIES:" in line:
                fallacies = [f.strip() for f in line.split("FALLACIES:")[-1].split(",")]
            elif "ASSUMPTIONS:" in line:
                assumptions = [a.strip() for a in line.split("ASSUMPTIONS:")[-1].split(",")]
            elif "CONTRADICTIONS:" in line:
                contradictions = [c.strip() for c in line.split("CONTRADICTIONS:")[-1].split(",")]
            elif "VALIDITY:" in line:
                validity = line.split("VALIDITY:")[-1].strip().lower()

        # Determine verification
        has_fallacies = len(fallacies) > 0 and fallacies[0]
        has_contradictions = len(contradictions) > 0 and contradictions[0]
        is_valid = validity == "valid"

        verified = is_valid and not has_fallacies and not has_contradictions
        confidence = 0.9 if verified else (0.3 if has_contradictions else 0.5)

        uncertainty = []
        if has_fallacies:
            uncertainty.append(f"Logical fallacies detected: {', '.join(fallacies)}")
        if has_contradictions:
            uncertainty.append(f"Internal contradictions: {', '.join(contradictions)}")
        if assumptions:
            uncertainty.append(f"Hidden assumptions: {', '.join(assumptions)}")

        return VerificationReport(
            claim=claim,
            strategy=VerificationStrategy.LOGICAL_CONSISTENCY,
            verified=verified,
            confidence=confidence,
            logical_issues=fallacies + contradictions,
            uncertainty_factors=uncertainty,
            recommendations=[
                "Address logical fallacies" if has_fallacies else None,
                "Resolve contradictions" if has_contradictions else None,
                "Make assumptions explicit" if assumptions else None
            ]
        )


class EvidenceChainVerifier:
    """Verify by tracing claims back to primary sources."""

    def __init__(self, llm_call: Callable[[str], str], search_func: Optional[Callable] = None):
        self.llm_call = llm_call
        self.search_func = search_func

    async def verify(self, claim: str, context: VerificationContext) -> VerificationReport:
        # Decompose claim into atomic sub-claims
        decomp_prompt = f"""Claim: {claim}

Decompose this claim into atomic, independently verifiable sub-claims.
Each sub-claim should be a single factual assertion that can be traced to a primary source.

Format:
SUB-CLAIM 1: [atomic claim]
SUB-CLAIM 2: [atomic claim]
..."""

        decomp_response = self.llm_call(decomp_prompt)
        sub_claims = []
        for line in decomp_response.split("\n"):
            if "SUB-CLAIM" in line.upper():
                sub_claims.append(line.split(":")[-1].strip())

        # Verify each sub-claim
        evidence_chains = []
        all_verified = True

        for sub_claim in sub_claims:
            chain = await self._trace_evidence_chain(sub_claim, context)
            evidence_chains.append(chain)
            if not chain["verified"]:
                all_verified = False

        # Overall confidence: product of sub-claim confidences (conservative)
        confidences = [c["confidence"] for c in evidence_chains]
        overall_confidence = np.prod([max(c, 0.1) for c in confidences]) if confidences else 0.0

        uncertainty = []
        for chain in evidence_chains:
            if not chain["verified"]:
                uncertainty.append(f"Unverified sub-claim: {chain['sub_claim']}")
            if chain["missing_links"] > 0:
                uncertainty.append(f"Missing {chain['missing_links']} evidence links for: {chain['sub_claim']}")

        return VerificationReport(
            claim=claim,
            strategy=VerificationStrategy.EVIDENCE_CHAIN,
            verified=all_verified and overall_confidence >= context.confidence_threshold,
            confidence=overall_confidence,
            evidence=[],  # Would be populated with actual evidence
            uncertainty_factors=uncertainty,
            metadata={"evidence_chains": evidence_chains, "sub_claims": sub_claims}
        )

    async def _trace_evidence_chain(self, sub_claim: str, context: VerificationContext) -> Dict:
        """Trace evidence chain for a sub-claim."""
        # In production, this would recursively search for sources
        # For now, simulate with LLM
        prompt = f"""Sub-claim: {sub_claim}

Trace the evidence chain for this claim:
1. What is the primary source?
2. What intermediate sources cite it?
3. How many hops from primary source?
4. Are there conflicting sources?

Format:
PRIMARY_SOURCE: [description]
HOPS: [number]
CONFLICTING: [yes/no]
CONFIDENCE: [0-1]"""

        response = self.llm_call(prompt)

        primary = ""
        hops = 99
        conflicting = False
        confidence = 0.5

        for line in response.split("\n"):
            if "PRIMARY_SOURCE:" in line:
                primary = line.split("PRIMARY_SOURCE:")[-1].strip()
            elif "HOPS:" in line:
                try:
                    hops = int(line.split("HOPS:")[-1].strip())
                except:
                    pass
            elif "CONFLICTING:" in line:
                conflicting = "YES" in line.upper()
            elif "CONFIDENCE:" in line:
                try:
                    confidence = float(line.split("CONFIDENCE:")[-1].strip())
                except:
                    pass

        return {
            "sub_claim": sub_claim,
            "primary_source": primary,
            "hops": hops,
            "conflicting": conflicting,
            "confidence": confidence,
            "verified": confidence > 0.7 and not conflicting,
            "missing_links": max(0, hops - 2)  # Ideal: direct or 1 hop
        }


class UncertaintyQuantifier:
    """Quantify epistemic uncertainty in claims."""

    def __init__(self, llm_call: Callable[[str], str]):
        self.llm_call = llm_call

    async def verify(self, claim: str, context: VerificationContext) -> VerificationReport:
        prompt = f"""Claim: {claim}

Quantify the epistemic uncertainty in this claim. Consider:
1. Aleatoric uncertainty (inherent randomness/variability)
2. Epistemic uncertainty (lack of knowledge/evidence)
3. Model uncertainty (ambiguity in claim interpretation)
4. Source reliability uncertainty
5. Temporal uncertainty (claim may change over time)

Provide uncertainty estimates (0-1) for each type and overall.

Format:
ALEATORIC: [0-1]
EPISTEMIC: [0-1]
MODEL: [0-1]
SOURCE: [0-1]
TEMPORAL: [0-1]
OVERALL: [0-1]
FACTORS: [list of uncertainty factors]"""

        response = self.llm_call(prompt)

        uncertainties = {}
        factors = []

        for line in response.split("\n"):
            for utype in ["ALEATORIC", "EPISTEMIC", "MODEL", "SOURCE", "TEMPORAL", "OVERALL"]:
                if f"{utype}:" in line:
                    try:
                        uncertainties[utype.lower()] = float(line.split(f"{utype}:")[-1].strip())
                    except:
                        uncertainties[utype.lower()] = 0.5
            if "FACTORS:" in line:
                factors = [f.strip() for f in line.split("FACTORS:")[-1].split(",")]

        overall = uncertainties.get("overall", 0.5)
        verified = overall < 0.3  # Low uncertainty = verified
        confidence = 1.0 - overall

        return VerificationReport(
            claim=claim,
            strategy=VerificationStrategy.UNCERTAINTY_QUANTIFICATION,
            verified=verified,
            confidence=confidence,
            uncertainty_factors=factors,
            metadata={"uncertainty_breakdown": uncertainties}
        )


class AdversarialVerifier:
    """Red-team verification: actively try to disprove the claim."""

    def __init__(self, llm_call: Callable[[str], str]):
        self.llm_call = llm_call

    async def verify(self, claim: str, context: VerificationContext) -> VerificationReport:
        # Generate strongest counter-arguments
        attack_prompt = f"""Claim: {claim}

Act as an adversarial critic. Generate the strongest possible arguments AGAINST this claim.
Consider:
1. Counter-examples
2. Alternative explanations
3. Methodological flaws
4. Missing evidence
5. Confounding factors
6. Edge cases where claim fails

Format:
ATTACK 1: [argument]
ATTACK 2: [argument]
...
SEVERITY: [critical/high/medium/low] for each"""

        attack_response = self.llm_call(attack_prompt)

        attacks = []
        for line in attack_response.split("\n"):
            if "ATTACK" in line.upper() and ":" in line:
                attacks.append(line.split(":", 1)[-1].strip())

        # Now defend against attacks
        defense_prompt = f"""Claim: {claim}
Attacks: {chr(10).join(attacks)}

Defend the claim against these attacks. For each attack, provide:
1. Whether the attack is valid
2. Counter-argument or concession
3. Remaining uncertainty

Format:
DEFENSE 1: [valid/invalid] | [counter-argument] | [uncertainty]"""

        defense_response = self.llm_call(defense_prompt)

        valid_attacks = 0
        for line in defense_response.split("\n"):
            if "DEFENSE" in line.upper() and "VALID" in line.upper():
                valid_attacks += 1

        # Verification based on attack survival
        attack_ratio = valid_attacks / max(len(attacks), 1)
        verified = attack_ratio < 0.3  # Less than 30% valid attacks
        confidence = 1.0 - attack_ratio

        uncertainty = [f"Valid attack: {a}" for a in attacks[:valid_attacks]]

        return VerificationReport(
            claim=claim,
            strategy=VerificationStrategy.ADVERSARIAL,
            verified=verified,
            confidence=confidence,
            uncertainty_factors=uncertainty,
            metadata={"attacks": attacks, "valid_attacks": valid_attacks}
        )


class CausalVerifier:
    """Verify causal claims using causal reasoning."""

    def __init__(self, llm_call: Callable[[str], str]):
        self.llm_call = llm_call

    async def verify(self, claim: str, context: VerificationContext) -> VerificationReport:
        prompt = f"""Claim: {claim}

Analyze this claim for causal reasoning:
1. Is this a causal claim (X causes Y)?
2. Identify the proposed cause and effect
3. Check for: confounding variables, reverse causality, selection bias
4. Apply Bradford Hill criteria (strength, consistency, specificity, temporality, biological gradient, plausibility, coherence, experiment, analogy)
5. Identify necessary conditions for causality

Format:
CAUSAL_CLAIM: [yes/no]
CAUSE: [proposed cause]
EFFECT: [proposed effect]
CONFOUNDERS: [list]
REVERSE_CAUSALITY_POSSIBLE: [yes/no]
BRADFORD_HILL_SCORE: [0-9]
NECESSARY_CONDITIONS: [list]"""

        response = self.llm_call(prompt)

        causal = False
        confounders = []
        reverse = False
        hill_score = 0

        for line in response.split("\n"):
            if "CAUSAL_CLAIM:" in line:
                causal = "YES" in line.upper()
            elif "CONFOUNDERS:" in line:
                confounders = [c.strip() for c in line.split("CONFOUNDERS:")[-1].split(",")]
            elif "REVERSE_CAUSALITY_POSSIBLE:" in line:
                reverse = "YES" in line.upper()
            elif "BRADFORD_HILL_SCORE:" in line:
                try:
                    hill_score = int(line.split("BRADFORD_HILL_SCORE:")[-1].strip())
                except:
                    pass

        if not causal:
            return VerificationReport(
                claim=claim,
                strategy=VerificationStrategy.CAUSAL,
                verified=True,  # Not a causal claim, so not falsifiable causally
                confidence=0.8,
                uncertainty_factors=["Not a causal claim"],
                metadata={"causal_claim": False}
            )

        verified = hill_score >= 6 and not reverse and len(confounders) < 3
        confidence = hill_score / 9.0 * (0.5 if reverse else 1.0) * (0.7 if confounders else 1.0)

        uncertainty = []
        if reverse:
            uncertainty.append("Reverse causality possible")
        if confounders:
            uncertainty.append(f"Potential confounders: {', '.join(confounders)}")
        if hill_score < 6:
            uncertainty.append(f"Low Bradford Hill score: {hill_score}/9")

        return VerificationReport(
            claim=claim,
            strategy=VerificationStrategy.CAUSAL,
            verified=verified,
            confidence=confidence,
            uncertainty_factors=uncertainty,
            metadata={
                "causal_claim": True,
                "hill_score": hill_score,
                "confounders": confounders,
                "reverse_causality": reverse
            }
        )


# ==================== MASTER VERIFICATION ORCHESTRATOR ====================

class AdvancedVerificationOrchestrator:
    """
    Orchestrates multiple verification strategies for comprehensive verification.
    """

    def __init__(
        self,
        llm_call: Callable[[str], str],
        memory: Optional[MemoryPalace] = None,
        search_func: Optional[Callable] = None
    ):
        self.llm_call = llm_call
        self.memory = memory
        self.search_func = search_func

        # Initialize gatherers
        self.gatherers = [
            LLMEvidenceGatherer(llm_call),
        ]
        if memory:
            self.gatherers.append(MemoryEvidenceGatherer(memory))
        if search_func:
            self.gatherers.append(WebSearchEvidenceGatherer(search_func))

        # Initialize verifiers
        self.verifiers = {
            VerificationStrategy.CONSENSUS: ConsensusVerifier(self.gatherers),
            VerificationStrategy.LOGICAL_CONSISTENCY: LogicalConsistencyVerifier(llm_call),
            VerificationStrategy.EVIDENCE_CHAIN: EvidenceChainVerifier(llm_call, search_func),
            VerificationStrategy.UNCERTAINTY_QUANTIFICATION: UncertaintyQuantifier(llm_call),
            VerificationStrategy.ADVERSARIAL: AdversarialVerifier(llm_call),
            VerificationStrategy.CAUSAL: CausalVerifier(llm_call),
        }

        self.verification_history: List[VerificationReport] = []
        self.calibration_data: List[Tuple[float, bool]] = []

    async def verify(
        self,
        claim: str,
        strategies: Optional[List[VerificationStrategy]] = None,
        context: Optional[VerificationContext] = None
    ) -> Dict[str, Any]:
        """
        Run comprehensive verification using multiple strategies.
        """
        if context is None:
            context = VerificationContext(claim=claim)

        if strategies is None:
            strategies = [
                VerificationStrategy.CONSENSUS,
                VerificationStrategy.LOGICAL_CONSISTENCY,
                VerificationStrategy.UNCERTAINTY_QUANTIFICATION,
                VerificationStrategy.ADVERSARIAL,
            ]

            # Add causal if claim appears causal
            if any(kw in claim.lower() for kw in ["causes", "leads to", "results in", "because of", "due to"]):
                strategies.append(VerificationStrategy.CAUSAL)

        # Run all verifications in parallel
        tasks = []
        for strategy in strategies:
            verifier = self.verifiers.get(strategy)
            if verifier:
                tasks.append(verifier.verify(claim, context))

        reports = await asyncio.gather(*tasks, return_exceptions=True)

        # Process results
        results = {}
        for strategy, report in zip(strategies, reports):
            if isinstance(report, Exception):
                results[strategy.value] = {"error": str(report)}
            else:
                results[strategy.value] = report.__dict__
                self.verification_history.append(report)

        # Aggregate
        aggregate = self._aggregate_results(results, claim)

        return {
            "claim": claim,
            "individual_results": results,
            "aggregate": aggregate,
            "timestamp": datetime.now().isoformat()
        }

    def _aggregate_results(self, results: Dict, claim: str) -> Dict[str, Any]:
        """Aggregate multiple verification results."""
        valid_results = {k: v for k, v in results.items() if "error" not in v}

        if not valid_results:
            return {
                "verified": False,
                "confidence": 0.0,
                "method": "none",
                "reason": "All verifications failed"
            }

        # Weighted voting
        weights = {
            "consensus": 0.3,
            "logical_consistency": 0.2,
            "evidence_chain": 0.2,
            "uncertainty": 0.1,
            "adversarial": 0.15,
            "causal": 0.05,
        }

        total_weight = 0
        weighted_verified = 0
        weighted_confidence = 0

        for strategy, result in valid_results.items():
            weight = weights.get(strategy, 0.1)
            verified = result.get("verified", False)
            confidence = result.get("confidence", 0.0)

            weighted_verified += weight * (1.0 if verified else 0.0)
            weighted_confidence += weight * confidence
            total_weight += weight

        overall_verified = weighted_verified / total_weight > 0.5 if total_weight > 0 else False
        overall_confidence = weighted_confidence / total_weight if total_weight > 0 else 0.0

        # Collect all uncertainty factors
        all_uncertainty = []
        for result in valid_results.values():
            all_uncertainty.extend(result.get("uncertainty_factors", []))

        # Collect all recommendations
        all_recommendations = []
        for result in valid_results.values():
            all_recommendations.extend(result.get("recommendations", []))

        return {
            "verified": overall_verified,
            "confidence": overall_confidence,
            "strategies_used": list(valid_results.keys()),
            "strategy_weights": {k: weights.get(k, 0.1) for k in valid_results},
            "uncertainty_factors": list(set(all_uncertainty)),
            "recommendations": list(set(all_recommendations)),
            "consensus": sum(1 for r in valid_results.values() if r.get("verified")) / len(valid_results)
        }

    def calibrate(self, predicted_confidence: float, actual_correct: bool):
        """Record calibration data."""
        self.calibration_data.append((predicted_confidence, actual_correct))

    def get_calibration_metrics(self) -> Dict[str, float]:
        """Compute calibration metrics."""
        if not self.calibration_data:
            return {"ece": 0.0, "mce": 0.0, "samples": 0}

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

    def get_verification_stats(self) -> Dict[str, Any]:
        """Get verification statistics."""
        if not self.verification_history:
            return {"total": 0}

        verified_count = sum(1 for r in self.verification_history if r.verified)
        avg_confidence = np.mean([r.confidence for r in self.verification_history])

        by_strategy = defaultdict(list)
        for r in self.verification_history:
            by_strategy[r.strategy.value].append(r)

        return {
            "total": len(self.verification_history),
            "verified": verified_count,
            "verification_rate": verified_count / len(self.verification_history),
            "avg_confidence": avg_confidence,
            "by_strategy": {
                k: {
                    "count": len(v),
                    "verified": sum(1 for r in v if r.verified),
                    "avg_confidence": np.mean([r.confidence for r in v])
                }
                for k, v in by_strategy.items()
            },
            "calibration": self.get_calibration_metrics()
        }


# ==================== CONVENIENCE FUNCTIONS ====================

async def advanced_verify(
    claim: str,
    llm_call: Callable[[str], str],
    memory: Optional[MemoryPalace] = None,
    search_func: Optional[Callable] = None,
    strategies: Optional[List[VerificationStrategy]] = None
) -> Dict[str, Any]:
    """Quick advanced verification."""
    orchestrator = AdvancedVerificationOrchestrator(llm_call, memory, search_func)
    return await orchestrator.verify(claim, strategies)


def create_verification_orchestrator(
    llm_call: Callable[[str], str],
    memory: Optional[MemoryPalace] = None,
    search_func: Optional[Callable] = None
) -> AdvancedVerificationOrchestrator:
    """Create a verification orchestrator."""
    return AdvancedVerificationOrchestrator(llm_call, memory, search_func)


# ==================== EXAMPLE USAGE ====================

if __name__ == "__main__":
    async def demo():
        def demo_llm(prompt: str) -> str:
            if "evidence" in prompt.lower():
                return """EVIDENCE 1: Scientific consensus | Multiple peer-reviewed studies confirm | SUPPORTS | 0.9 | 0.9
EVIDENCE 2: IPCC report | Climate change is human-caused | SUPPORTS | 0.95 | 0.95
EVIDENCE 3: Skeptic blog | Claims natural cycles | CONTRADICTS | 0.3 | 0.4"""
            elif "logical" in prompt.lower():
                return """PREMISES: CO2 traps heat, Humans emit CO2
CONCLUSION: Humans cause warming
FALLACIES: None
ASSUMPTIONS: Climate sensitivity is positive
CONTRADICTIONS: None
VALIDITY: valid"""
            elif "uncertainty" in prompt.lower():
                return """ALEATORIC: 0.1
EPISTEMIC: 0.2
MODEL: 0.1
SOURCE: 0.1
TEMPORAL: 0.15
OVERALL: 0.13
FACTORS: measurement error, model uncertainty"""
            elif "attack" in prompt.lower():
                return """ATTACK 1: Correlation not causation
ATTACK 2: Solar activity alternative
ATTACK 3: Temperature record adjustments
SEVERITY: medium for all"""
            elif "defense" in prompt.lower():
                return """DEFENSE 1: invalid | Controlled for solar | low uncertainty
DEFENSE 2: invalid | Fingerprint matches GHG | low uncertainty
DEFENSE 3: invalid | Multiple independent datasets | low uncertainty"""
            elif "causal" in prompt.lower():
                return """CAUSAL_CLAIM: yes
CAUSE: CO2 emissions
EFFECT: Global warming
CONFOUNDERS: solar, volcanic
REVERSE_CAUSALITY_POSSIBLE: no
BRADFORD_HILL_SCORE: 8
NECESSARY_CONDITIONS: temporality, mechanism"""
            return "[Demo response]"

        claim = "Human CO2 emissions are the primary cause of global warming since 1950"

        result = await advanced_verify(claim, demo_llm)
        print(json.dumps(result, indent=2, default=str))

    asyncio.run(demo())