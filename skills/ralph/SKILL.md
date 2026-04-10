---
name: ralph
description: >
  Autonomous development orchestrator wrapping the official Anthropic ralph-loop plugin.
  Ralph uses a Stop hook to block Claude's exit and re-feed the SAME prompt, creating a
  self-referential loop where Claude sees its own previous work in files and git history.
  This skill adds verification gates and reviewer checkpoints INTO the prompt, so Ralph
  won't output the completion promise until verify passes + reviewer approves.
  Trigger on: "ralph", "ralph loop", "autonomous loop", "autonomous dev",
  "iterate until done", "run ralph on this".
user_invocable: true
argument-hint: "<task_description> — what Ralph should work on autonomously"
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Agent
license: MIT
metadata:
  version: "2.0.0"
  author: jerry-yang
  category: dev-workflow
  tags:
    - autonomous-dev
    - ralph-loop
    - verification
    - quality-gates
    - self-correction
---

# Ralph: Gated Autonomous Development

Ralph is a gated autonomous loop built on top of the **official Anthropic ralph-loop plugin**
(`/ralph-loop`). The plugin uses a Stop hook to intercept Claude's exit attempts and re-feed
the same prompt, creating a self-referential loop where Claude sees its own previous work in
files and git history.

This skill adds quality gates by embedding verification and reviewer requirements directly
into the Ralph prompt — so Claude will only output the `<promise>` completion tag when
the work genuinely passes all checks.

## How Real Ralph Works (vs /loop)

| Aspect | `/loop` (built-in) | `/ralph-loop` (plugin) |
|--------|--------------------|-----------------------|
| Mechanism | Interval timer, polls | Stop hook blocks exit, re-feeds same prompt |
| Purpose | Cron-like monitoring | Deep iterative development |
| Memory | Fresh each tick | Sees previous work in files + git |
| Exit | Timer or manual | `<promise>` tag or `--max-iterations` |
| Metaphor | Security camera | Construction crew that keeps building |

**Ralph is NOT `/loop`**. Ralph blocks Claude from exiting and forces re-iteration on the
same task until the completion promise is genuinely fulfilled.

## Prerequisites

| Requirement | Check | If Missing |
|------------|-------|------------|
| ralph-loop plugin | `/ralph-loop --help` | Should be pre-installed from Anthropic marketplace |
| scripts/verify.sh | `test -f scripts/verify.sh` | Run `/repo-bootstrap` first |
| .claude/agents/reviewer.md | `test -f .claude/agents/reviewer.md` | Run `/repo-bootstrap` first |

If prerequisites are missing:
```
Ralph cannot start. Missing:
- [ ] scripts/verify.sh — run /repo-bootstrap first
- [ ] .claude/agents/reviewer.md — run /repo-bootstrap first
```

## Input

User task: `$ARGUMENTS`

## Profile Selection

Analyze the task and select a profile:

| Task Signal | Profile | Max Iterations | Why |
|-------------|---------|----------------|-----|
| "fix", "bug", "typo", "update", single file | **Sprint** | 10 | Small scope, fast convergence |
| "add", "implement", "feature", 2-5 files | **Build** | 20 | Medium scope, needs room to iterate |
| "refactor", "redesign", "migrate", 5+ files | **Marathon** | 50 | Large scope, may need many passes |
| Unclear | **Build** | 20 | Safe default |

## Prompt Construction

The key insight: since Ralph re-feeds the SAME prompt every iteration, all quality gates
must be embedded IN the prompt itself. The prompt is the contract.

### Template: Sprint

```
/ralph-loop {task_description}

ITERATION PROTOCOL:
1. Check git status and files to see what was done in previous iterations
2. Plan: state what you will change this iteration (1-2 sentences max)
3. Implement the changes
4. Run: bash scripts/verify.sh
   - If FAIL: read the error output, fix the issue, re-run (up to 3 retries)
   - If still FAIL after 3 retries: commit what works, document the blocker
5. Check: is the task FULLY complete?
   - If NO: exit normally (Ralph will re-feed this prompt for next iteration)
   - If YES: proceed to step 6
6. Review: read .claude/agents/reviewer.md and apply its FULL checklist to your changes
   - Run git diff to see all accumulated changes
   - If reviewer verdict is FAIL: address Critical findings, exit for next iteration
   - If reviewer verdict is PASS or CONDITIONAL PASS: proceed to step 7
7. Output completion:
   <promise>DONE</promise>

RULES:
- Do NOT output <promise>DONE</promise> unless verify PASSES and reviewer PASSES
- Do NOT lie to escape the loop — the promise must be genuinely true
- If you are stuck, describe the blocker clearly and exit for next iteration
- Each iteration should make meaningful progress — no empty iterations

--completion-promise 'DONE' --max-iterations 10
```

### Template: Build

```
/ralph-loop {task_description}

ITERATION PROTOCOL:
1. Orientation: check git log, git status, and key files to see previous iteration work
2. Plan: what specific progress will this iteration make? (reference file paths)
3. Implement: make changes, follow existing code patterns
4. Verify: run bash scripts/verify.sh
   - If FAIL: diagnose root cause, fix, re-run (up to 3 retries)
   - If still FAIL: try a different approach, exit for next iteration
5. Progress check:
   - What percentage of the task is complete?
   - What remains?
   - If <100%: exit normally for next iteration
   - If 100%: proceed to review
6. Full review: read .claude/agents/reviewer.md and execute full protocol
   - Run git diff to see ALL changes since task started
   - Apply every checklist item
   - Critical findings: must fix before completion
   - Important findings: fix if possible
   - Minor findings: document but don't block
7. If reviewer PASS or CONDITIONAL PASS:
   <promise>DONE</promise>

RULES:
- Do NOT output <promise>DONE</promise> unless verify PASSES and reviewer PASSES
- Do NOT lie to escape the loop — the promise must be genuinely true
- If stuck on the same issue for 2+ iterations, try a fundamentally different approach
- Never modify scripts/verify.sh to make it pass — that defeats the purpose

--completion-promise 'DONE' --max-iterations 20
```

### Template: Marathon

```
/ralph-loop {task_description}

ITERATION PROTOCOL:
1. Orientation: check git log --oneline -20, git status, read CLAUDE.md if exists
2. Sub-task planning: break remaining work into sub-tasks, pick ONE for this iteration
   Track in a scratchpad file (.claude/ralph-progress.local.md):
   - [ ] Sub-task 1
   - [ ] Sub-task 2
   - ...
3. Implement the chosen sub-task
4. Verify: run bash scripts/verify.sh
   - If FAIL: diagnose, fix, re-run (up to 3 retries)
   - If still FAIL: revert this iteration's changes, try different approach
5. Update scratchpad: mark completed sub-tasks
6. Checkpoint (every 3 iterations): review overall progress
   - Are we still on track?
   - Has scope crept?
   - Any architectural concerns?
7. Completion check: are ALL sub-tasks done?
   - If NO: exit for next iteration
   - If YES: full review
8. Full review: read .claude/agents/reviewer.md, review ALL accumulated changes
   - Critical/Important findings must be resolved
9. If reviewer PASS or CONDITIONAL PASS:
   <promise>DONE</promise>

RULES:
- Do NOT output <promise>DONE</promise> unless verify PASSES and reviewer PASSES
- Do NOT lie to escape the loop
- If fundamentally stuck, document blocker in scratchpad and move to next sub-task
- Never modify verify.sh to make it pass
- Commit working code incrementally (don't accumulate massive uncommitted changes)

--completion-promise 'DONE' --max-iterations 50
```

## Execution

After constructing the prompt, show it to the user and run:

```
Ralph Configuration:
  Profile: {Sprint/Build/Marathon}
  Max iterations: {10/20/50}
  Completion promise: DONE
  Verify: scripts/verify.sh
  Reviewer: .claude/agents/reviewer.md
  Task: {description}

  Cancel anytime: /cancel-ralph
  Monitor: grep '^iteration:' .claude/ralph-loop.local.md

Running: /ralph-loop {constructed prompt}
```

## Completion Guarantee

Ralph MUST NOT output `<promise>DONE</promise>` unless ALL of these are true:

1. `bash scripts/verify.sh` exits 0
2. Reviewer agent verdict is PASS or CONDITIONAL PASS
3. All Critical findings from reviewer are addressed
4. The task described in the prompt is actually complete

If Ralph hits `--max-iterations` without completing:

```
RALPH TIMEOUT — the loop stopped at iteration {max}.
Check .claude/ralph-progress.local.md for progress tracking.
Check git log for what was accomplished.
Remaining work: {what's left}
```

## Cancellation

At any time: `/cancel-ralph`

This removes `.claude/ralph-loop.local.md` and allows Claude to exit normally.

## Integration with repo-bootstrap

```bash
# Step 1: Bootstrap the repo (generates verify.sh + reviewer + CLAUDE.md)
/repo-bootstrap

# Step 2: Autonomous development with Ralph
/ralph "implement feature X"
```

The repo-bootstrap skill generates a recommended Ralph invocation in CLAUDE.md.

## Anti-Patterns

1. **Never skip verification** — even for "trivial" changes
2. **Never output `<promise>` falsely** — the loop is designed to continue until genuine completion
3. **Never modify verify.sh to make it pass** — fix the actual code
4. **Never loop without progress** — if stuck, try a different approach or document the blocker
5. **Always set --max-iterations** — infinite loops are dangerous; use the profile defaults
6. **Never use Ralph for ambiguous tasks** — if success criteria are unclear, clarify first

## Monitoring a Running Ralph

```bash
# Current iteration
grep '^iteration:' .claude/ralph-loop.local.md

# Full state
head -10 .claude/ralph-loop.local.md

# Git progress
git log --oneline -10
```
