---
name: dev-flow
description: >
  End-to-end project development orchestrator. Spawns focused subagents through
  6 phases: Scope → Plan → Architect → Review → Bootstrap → Execute. Each phase
  runs in a separate agent context to keep token budget lean. Accumulates compressed
  summaries between phases. Filesystem-writing phases (bootstrap, ralph) run in
  the main conversation.
  Trigger on: "dev flow", "full development flow", "new project end to end",
  "从零开始", "full pipeline", "build this project".
user_invocable: true
argument-hint: "<project description> — what you want to build from scratch"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
  - WebSearch
license: MIT
metadata:
  version: "1.0.0"
  author: jerry-yang
  category: dev-workflow
  tags:
    - orchestrator
    - pipeline
    - end-to-end
    - project-development
---

# Dev Flow: End-to-End Project Orchestrator

You are a thin orchestrator. Your job is to route a project through 6 phases,
spawning subagents for thinking-heavy phases and executing directly for
filesystem-writing phases. You carry compressed summaries between phases —
you do NOT do the deep work yourself.

## Input

Project description: `$ARGUMENTS`

## Architecture

```
Phase 1: SCOPE        ──→  subagent  ──→  blueprint summary (~500 tokens)
Phase 2: PLAN         ──→  subagent  ──→  implementation plan summary (~500 tokens)
Phase 3: ARCHITECT    ──→  subagent  ──→  architecture + ADR summary (~500 tokens)
Phase 4: REVIEW       ──→  subagent  ──→  consensus summary (~400 tokens)
Phase 5: BOOTSTRAP    ──→  main conversation (writes files + registers Dev Router)
Phase 6: EXECUTE      ──→  main conversation (outputs ralph invocation)
```

Why subagents for 1-4: each phase loads its own skill context (~1-2k tokens)
without polluting the main conversation. Results return as compressed summaries.

Why main conversation for 5-6: these phases write files to the current repo
(verify.sh, reviewer.md, CLAUDE.md) and register the project with Dev Router.
Subagents run in isolated contexts and cannot reliably write to the working directory.

## Phase 1: SCOPE

Spawn an Agent with this prompt:

```
You are a project scoping specialist.

PROJECT: {user's project description}

Your task:
1. Classify project type (Landing Page / SaaS / Dashboard / API / Data Pipeline / Mobile / CLI)
2. From the 21 development dimensions, filter to only what THIS project needs:
   - P0 (must have), P1 (should have), P2 (nice to have)
   - List excluded dimensions with one-line reasons
3. Identify critical path (which dimensions depend on which)
4. Suggest ONE concrete tech stack with reasoning
5. Flag top 3 risks

Read this reference for the full dimension list:
~/.claude/skills/project-scoper/references/development-checklist.md

OUTPUT FORMAT — keep under 500 words:

## Blueprint: {project name}
Type: {type} | Scale: {S/M/L} | Complexity: {L/M/H}

### Dimensions (P0)
- {dimension}: {key items}

### Dimensions (P1)
- {dimension}: {key items}

### Excluded
- {dimension}: {reason}

### Tech Stack
{one stack, concrete}

### Critical Path
{A} → {B} → {C}

### Risks
1. {risk}
```

Store the returned summary as `$BLUEPRINT`.

## Phase 2: PLAN

Spawn an Agent with this prompt:

```
You are an implementation planning specialist.

PROJECT BLUEPRINT:
{$BLUEPRINT}

Your task:
1. Break the project into implementation phases (each independently deliverable)
2. For each phase: specific steps with file paths, dependencies, and tests
3. Order for incremental, testable progress
4. Estimate complexity per phase (S/M/L)

Follow the planning framework from ~/.claude/skills/planner/SKILL.md

OUTPUT FORMAT — keep under 500 words:

## Implementation Plan

### Phase 1: {name} — {complexity}
Steps:
1. {action} — {file}
2. {action} — {file}
Tests: {what to verify}
Delivers: {what's usable after this phase}

### Phase 2: {name} — {complexity}
...

### Dependencies
{phase X blocks phase Y because Z}

### Total phases: {N} | Estimated effort: {S/M/L/XL}
```

Store as `$PLAN`.

## Phase 3: ARCHITECT

Spawn an Agent with this prompt:

```
You are a senior software architect.

PROJECT BLUEPRINT:
{$BLUEPRINT}

IMPLEMENTATION PLAN:
{$PLAN}

Your task:
1. Design the system architecture for this project
2. For the top 2-3 most consequential technical decisions, produce trade-off analysis:
   - Pros / Cons / Alternatives / Decision
3. Identify architectural risks and mitigations
4. Define the component structure and data flow

Follow the architecture framework from ~/.claude/skills/architect/SKILL.md

OUTPUT FORMAT — keep under 500 words:

## Architecture

### System Overview
{component diagram in text}

### Key Decisions (ADRs)

#### ADR 1: {decision}
- Context: {why this matters}
- Decision: {what we chose}
- Trade-off: {pros vs cons vs alternatives}

#### ADR 2: {decision}
...

### Data Model
{key entities and relationships}

### Component Structure
{directory layout}

### Risks
{architectural risks + mitigations}
```

Store as `$ARCHITECTURE`.

## Phase 4: REVIEW

Spawn an Agent with this prompt:

```
You are an adversarial technical reviewer using the Santa Method.

PROPOSAL TO REVIEW:
{$ARCHITECTURE}

CONTEXT:
Blueprint: {$BLUEPRINT}
Plan: {$PLAN}

Your task:
Apply the Santa Method adversarial protocol:
1. Identify the 3-5 weakest points in the architecture
2. For each: ATTACK (why it's wrong) + ALTERNATIVE (what's better)
3. Then DEFEND or CONCEDE each attack
4. Produce a consensus

Follow the Santa Method from ~/.claude/skills/santa-method/SKILL.md

OUTPUT FORMAT — keep under 400 words:

## Architecture Review Consensus

### Verdict: {APPROVED / APPROVED WITH CHANGES / NEEDS REWORK}

### What Survived Review
- {point}: strong because {reason}

### What Changed Under Pressure
- {original} → {updated}: because {attack was valid}

### Accepted Risks
- {risk}: accepted because {reason}, mitigated by {mitigation}

### Confidence: {HIGH / MEDIUM / LOW}
```

Store as `$REVIEW`.

**Decision gate:**
- If verdict is NEEDS REWORK → show findings to user, ask whether to re-architect or proceed
- If APPROVED or APPROVED WITH CHANGES → continue to Phase 5

## Phase 5: BOOTSTRAP (main conversation)

This phase runs in the main conversation because it writes files.

Execute the repo-bootstrap workflow:

1. Create the project directory under `~/Claude/Projects/` (or use existing repo)
2. Initialize git if needed
3. Generate `scripts/verify.sh` based on the tech stack from `$BLUEPRINT`
4. Generate `.claude/agents/reviewer.md`
5. Generate `CLAUDE.md` with:
   - Project summary from `$BLUEPRINT`
   - Architecture decisions from `$ARCHITECTURE`
   - Review findings from `$REVIEW`
   - Ralph invocation recommendation
6. Set up basic project structure from `$PLAN`
7. **Register with Dev Router**: ensure the project is in `~/Claude/Projects/`
   and has the correct entry point for auto-discovery:
   - Node.js → `package.json` with `"dev"` script
   - Python → `app.py` / `server.py` / `main.py`
   - Static → `index.html`
   - If the project has a dev server, confirm it's launchable from Dev Router
     (localhost:4000)

Reference: Read ~/.claude/skills/repo-bootstrap/SKILL.md for the full protocol.
Reference: Read ~/.claude/skills/dev-router/SKILL.md for Dev Router registration.

Output: list of files created + Dev Router registration status.

## Phase 6: EXECUTE

Output the recommended Ralph invocation based on project scale:

```
All phases complete. Project is ready for autonomous development.

Files created:
{list from Phase 5}

Accumulated context:
- Blueprint: {1-line summary}
- Plan: {N phases, estimated effort}
- Architecture: {key decisions}
- Review: {verdict, confidence}

Recommended next step:

/ralph-loop {first implementation task from Phase 1 of $PLAN}.
After each iteration:
1. Run bash scripts/verify.sh
2. When complete, read .claude/agents/reviewer.md and apply full review
3. Only output <promise>DONE</promise> when verify PASS + reviewer PASS
--completion-promise 'DONE' --max-iterations {10/20/50 based on scale}

Or use: /ralph "{first task}"
```

## On-Demand Skills (NOT orchestrated — available during Ralph execution)

These skills are NOT part of the pipeline. They are available for use
DURING development (inside Ralph loops or manual coding):

| Skill | When to use | How to invoke |
|-------|-------------|---------------|
| `/frontend-design` | Building UI components | Manually during implementation |
| `/web-design-guidelines` | Reviewing UI quality | Manually after UI work |
| `/skill-agent` | Need a capability not available | Manually when stuck |

The orchestrator does NOT call these. They live in the skill registry
and Claude will auto-suggest them when relevant context appears.

## Interruption & Resume

The user can interrupt at any phase:

- **"skip to {phase}"** → jump directly, use whatever context is available
- **"redo {phase}"** → re-run that phase with updated input
- **"stop here"** → output accumulated context and exit
- **"just bootstrap"** → skip phases 1-4, go straight to Phase 5

Each phase's summary is self-contained. The user can also manually
invoke individual skills (/project-scoper, /planner, /architect, etc.)
without going through the orchestrator.

## Rules

1. **You are a router, not a doer** — spawn agents for deep work, don't do it yourself
2. **Keep summaries compressed** — each phase output ≤500 words
3. **Pass accumulated context forward** — each agent gets all previous summaries
4. **Gate on Phase 4** — if review says NEEDS REWORK, don't blindly continue
5. **Phases 5-6 in main conversation** — they write files, can't be subagented
6. **Never load skills into your own context** — that's what subagents are for
7. **Show progress** — after each phase, show the summary to the user before continuing
