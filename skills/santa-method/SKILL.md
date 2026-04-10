---
name: santa-method
description: Two-agent adversarial consensus protocol. One agent proposes (Proposer), one agent aggressively challenges every assumption (Challenger). They iterate until a stress-tested consensus emerges. Use PROACTIVELY before any major technical decision, architecture choice, or implementation plan — especially when AI has generated the initial proposal. Prevents overconfidence in AI-generated ideas by forcing them through structured adversarial pressure.
---

# Santa Method: Adversarial Consensus Protocol

## Philosophy

AI-generated proposals are fluent, confident, and often subtly wrong. The Santa Method forces every proposal through structured adversarial pressure before it becomes a plan. Named after the Socratic tradition of "playing devil's advocate" — like Santa checking his list twice, we check every assumption at least once against a hostile critic.

**The core loop:**
```
Proposer → makes claim/plan
Challenger → attacks every weak point, no mercy
Proposer → defends or concedes
Challenger → accepts defense or escalates
→ Repeat until Challenger cannot find new attacks
→ Result = stress-tested consensus
```

## When to Invoke

- AI has generated a technical architecture or plan
- Choosing between two tech stacks or approaches
- Before committing to an API, library, or third-party dependency
- When you feel "this seems right" without being able to say why
- Any decision that's hard to reverse

## The Two Roles

### Role A: The Proposer
- States the proposal clearly and confidently
- Provides specific reasoning (not vague justifications)
- Must defend every claim when challenged
- Can concede weak points — concession is strength, not failure
- Goal: arrive at the **most defensible version** of the idea

### Role B: The Challenger
- Assumes the proposal is **wrong until proven right**
- Attacks on all dimensions: technical feasibility, hidden costs, ecosystem maturity, edge cases, failure modes, alternatives the Proposer ignored, assumptions baked in silently
- Must propose a **concrete alternative** for each attack — not just "this is bad" but "this is bad, and here's what's better"
- Does NOT accept hand-wavy defenses
- Goal: **break the proposal** or force it to evolve into something unbreakable

## Round Structure

### Round 1: Proposal
Proposer states the full plan/decision with reasoning.

### Round 2: Full Attack
Challenger identifies every weak point. Format:
```
ATTACK [1]: [Specific claim being attacked]
Why it's wrong: [concrete technical/business reason]
Better alternative: [specific alternative]

ATTACK [2]: ...
```

### Round 3: Defense + Concession
Proposer responds to each attack:
```
RE: ATTACK [1]
Status: DEFENDED / CONCEDED / PARTIALLY CONCEDED
Reasoning: [why the attack lands or doesn't]
Updated proposal: [if conceded, what changes]
```

### Round 4: Re-attack
Challenger attacks the updated proposal. Only escalates on points not adequately defended. Accepts clean defenses.

### Round 5+: Convergence
Repeat until:
- Challenger runs out of new attacks, OR
- Both sides agree the remaining disagreements are **acceptable known risks** (documented explicitly)

## Consensus Output Format

```markdown
## Santa Method Consensus: [Decision Name]

### Final Decision
[What was decided, in one clear sentence]

### What Survived Adversarial Review
- [Point 1]: Defended because [reason]
- [Point 2]: Defended because [reason]

### What Changed Under Pressure
- [Original claim] → [Updated claim]: Changed because [Challenger's attack was valid]

### Known Risks (Accepted)
- [Risk]: Accepted because [reason], mitigated by [mitigation]

### Rejected Alternatives
- [Alternative]: Rejected because [why the Proposer's approach is still stronger]

### Confidence Level
[HIGH / MEDIUM / LOW] — [one sentence rationale]
```

## Example Application: Tech Stack Decision

**Proposer:** "We should use Three.js WebGPU + React Three Fiber as our primary stack."

**Challenger attacks:**
```
ATTACK [1]: WebGPU browser support
TSL is still experimental. Three.js r171 docs warn TSL node-based materials
have incomplete coverage. Many Drei helpers still use WebGL shaders internally.
Alternative: Stick with Three.js WebGL2 only — more stable, same visual quality
for 90% of effects.

ATTACK [2]: R3F overhead
React reconciler adds overhead. For high-frequency updates (particles, fluid sims),
React re-renders kill performance. Three.js vanilla with manual requestAnimationFrame
is faster for compute-heavy work.
Alternative: Vanilla Three.js for the library core, R3F only for the React wrapper.

ATTACK [3]: Spark.js stability
Spark.js is 0.x, World Labs-backed but community-driven. Their v2.0 API changed
significantly. Pinning to a version risks missing security/perf updates.
Alternative: Use antimatter15/splat (zero dependencies, more stable API) for
Gaussian Splatting, or wait for glTF KHR_gaussian_splatting standardization.
```

**Proposer defends:**
```
RE: ATTACK [1] — PARTIALLY CONCEDED
TSL is experimental but Three.js provides automatic GLSL fallback. We accept
the risk for compute shaders (where WebGPU gains are 150x) and use traditional
GLSL for everything else. Updated: TSL only for particle compute shaders.

RE: ATTACK [2] — DEFENDED
The library core (packages/core, packages/particles) is vanilla Three.js.
R3F is only in packages/react — an optional wrapper. High-frequency updates
bypass React via useFrame which runs outside React's render cycle.

RE: ATTACK [3] — CONCEDED
Spark.js 0.x is a real risk. Updated: abstract behind our own SplatLoader
interface, pin exact version, monitor KHR_gaussian_splatting standard.
Add antimatter15/splat as fallback if Spark.js breaks.
```

**Result: Consensus reached with documented changes.**

## Rules

1. **No vague attacks.** "This might not scale" is invalid. "This fails when X happens because Y" is valid.
2. **No vague defenses.** "It'll be fine" is invalid. "It's fine because Z, and if Z fails, we do W" is valid.
3. **Concession is free.** Conceding a weak point makes the final plan stronger. Refusing to concede under valid pressure makes the plan fragile.
4. **Document what died.** Every rejected alternative and every conceded point must appear in the consensus output. Future Claude sessions can see what was already tested.
5. **Stop when attacks repeat.** If the Challenger is cycling through the same attacks with no new substance, consensus is reached.
6. **Maximum 5 rounds.** If unresolved after 5 rounds, escalate to the user with a clear "here's the unresolved disagreement, here are both sides."
