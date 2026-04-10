# Token Budget Analysis

## Why Token Efficiency Matters

Claude Code has a ~200K token context window. In practice, ~30-60K is consumed by the system prompt, tool definitions, and conversation history before any skill loads. Every token spent on skill definitions reduces the space available for:

- Your conversation and follow-up questions
- Code being read, written, or reviewed
- Tool call results (file contents, command output)
- Claude's reasoning about your project

A 12K token mega-skill leaves you with ~128-158K of usable context. Over a long session with many file reads and edits, this can cause Claude to lose earlier context — the "forgot what we discussed" problem.

## Three Architectures Compared

### Architecture A: Mega-Skill (all skills merged)

```
Context Window (200K)
├── System + Tools              ~40K
├── Mega-Skill (always loaded)  ~12,457 tokens ← FIXED COST
├── Conversation                ~remaining
└── Available for work          ~147K
```

**Problem**: 12,457 tokens consumed even when you only need one capability. The scoping logic, planning framework, architecture patterns, Santa Method rounds, verification templates, and Ralph protocols all sit in context competing for Claude's attention.

### Architecture B: Sequential Skills (load one by one)

```
Context Window (200K)
├── System + Tools              ~40K
├── /project-scoper loaded      +1,284 tokens  (never unloads)
├── conversation output         +2,000
├── /planner loaded             +816 tokens     (never unloads)
├── conversation output         +3,000
├── /architect loaded           +1,182 tokens   (never unloads)
├── conversation output         +4,000
├── /santa-method loaded        +1,653 tokens   (never unloads)
├── conversation output         +5,000
├── /repo-bootstrap loaded      +3,424 tokens   (never unloads)
├── conversation output         +3,000
├── /ralph loaded               +2,427 tokens   (never unloads)
├── Total skill tokens          ~10,786         ← ACCUMULATES
├── Total conversation          ~17,000
└── Available for work          ~132K (and shrinking)
```

**Problem**: Skills load but don't unload. By Phase 6, all skills plus all intermediate conversation history occupy ~28K tokens. This is worse than the mega-skill because you also have the verbose intermediate output.

### Architecture C: Dev Flow (subagent-based)

```
Context Window (200K)
├── System + Tools              ~40K
├── dev-flow orchestrator       ~2,348 tokens   ← ONLY THIS LOADS
├── Phase 1 summary returned    +500
├── Phase 2 summary returned    +500
├── Phase 3 summary returned    +500
├── Phase 4 summary returned    +400
├── Phase 5 (bootstrap inline)  +3,424          ← loads here, needed for file writes
├── Phase 6 output              +200
├── Total in main context       ~7,872 tokens
└── Available for work          ~152K           ← MOST HEADROOM
```

**Where did the deep work go?** Into subagent contexts:

```
Subagent 1 context: system (~30K) + scoper (1,284) + deep work (~8K) = ~39K → released
Subagent 2 context: system (~30K) + planner (816) + blueprint (500) + deep work (~8K) → released
Subagent 3 context: system (~30K) + architect (1,182) + blueprint+plan (1K) + deep work (~10K) → released
Subagent 4 context: system (~30K) + santa-method (1,653) + accumulated (1.5K) + deep work (~8K) → released
```

Each subagent gets a **full context window** for deep reasoning, then returns a compressed result. The main conversation never sees the intermediate thinking.

## Summary Table

| Metric | Mega-Skill | Sequential | Dev Flow |
|--------|-----------|------------|----------|
| Main context (skills) | 12,457 | ~10,786 | ~7,872 |
| Main context (conversation) | ~5,000 | ~17,000 | ~2,100 |
| **Total main context** | **~17,457** | **~27,786** | **~9,972** |
| Deep work quality | Shallow | Medium | Deep |
| Available for more work | ~143K | ~132K | ~150K |
| **Savings vs mega-skill** | baseline | -10K worse | **+7.5K better** |

## Why 500-Word Summaries?

Each phase returns a summary capped at ~500 words (~650 tokens). This is calibrated to:

1. **Preserve essential decisions** — tech stack, architecture choices, risk assessments survive compression
2. **Drop implementation details** — subagents do the detailed reasoning, summaries carry the conclusions
3. **Stay within 3% of context** — 500 tokens is ~0.25% of 200K, negligible noise
4. **Accumulate safely** — 4 summaries × 500 tokens = 2,000 tokens total, still tiny

The compression ratio is roughly **10:1** — a subagent may produce 5,000 tokens of reasoning but returns 500 tokens of conclusions.

## Long Session Sustainability

In a long development session (3+ hours), context management becomes critical:

```
Hour 0: Start dev-flow
  Main context: ~10K (orchestrator + summaries + bootstrap)

Hour 1: Ralph loop running, iteration 5
  Main context: ~10K + ~15K (ralph work) = ~25K
  Still have ~135K available

Hour 2: Ralph loop, iteration 15
  Main context: ~10K + ~40K (accumulated changes) = ~50K
  Still have ~110K available

Hour 3: Ralph loop, iteration 25
  Main context: ~10K + ~70K = ~80K
  Still have ~80K available — healthy
```

Compare with mega-skill approach:

```
Hour 0: Mega-skill loaded
  Main context: ~17K (skill + initial planning)

Hour 1: Still coding
  Main context: ~17K + ~15K = ~32K

Hour 2: Context getting full
  Main context: ~17K + ~40K = ~57K

Hour 3: Running low
  Main context: ~17K + ~70K = ~87K
  Only ~73K available — 10% less headroom
```

The 7.5K token savings from Dev Flow compounds over time. In a 3-hour session, that's the difference between having comfortable headroom and hitting context limits.

## Cost Implications

Claude API pricing is per-token. While the token savings from Dev Flow vs a mega-skill are modest per-invocation (~7.5K tokens), they compound:

- Over 10 dev-flow runs: ~75K tokens saved
- Over a month of active development: ~500K-1M tokens saved
- At Claude API rates: meaningful cost reduction for teams

More importantly, **quality is the real win** — each subagent getting a full context window for deep reasoning produces better architecture decisions, more thorough reviews, and more robust implementation plans than a mega-skill competing for attention in a cluttered context.
