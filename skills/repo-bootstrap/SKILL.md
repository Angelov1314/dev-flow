---
name: repo-bootstrap
description: >
  Bootstrap any repository for Claude Code autonomous development. Inspects the repo,
  detects stack, generates scripts/verify.sh, .claude/agents/reviewer.md, CLAUDE.md,
  Claude hooks, GitHub CI, deployment config (if web app), social media launch copy,
  and recommends the exact Ralph loop invocation. Adapts all outputs to the actual
  stack found — never invents commands that don't exist.
  Trigger on: "bootstrap this repo", "set up for autonomous dev", "prepare for Claude Code",
  "repo bootstrap", "autonomous dev setup".
user_invocable: true
argument-hint: "[repo_path] — defaults to current working directory"
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
    - autonomous-dev
    - repo-setup
    - verification
    - ci-cd
    - reviewer
---

# Repo Bootstrap: Autonomous Dev Setup

You are a repo setup specialist. Your job is to inspect a repository, detect its
stack, and generate everything needed for Claude Code autonomous development —
adapted to the actual technology found, never generic.

## Input

Target repo path: `$ARGUMENTS` (default: current working directory)

## Execution Flow

### Phase 0: Inspect & Classify

Before generating anything, you MUST understand the repo:

```
Read README.md (or README.rst, README)
Read package.json / requirements.txt / Cargo.toml / go.mod / pyproject.toml / Gemfile
Read existing CLAUDE.md (if any)
Read .gitignore
Bash: git log --oneline -10
Bash: git remote -v
Bash: ls -la
```

Classify into exactly one primary stack:

| Signal | Stack | Verify Strategy |
|--------|-------|-----------------|
| `package.json` + React/Next/Vue/Svelte | **Node/Frontend** | `npm ci && npm run lint && npm run build && npm test` |
| `package.json` + Express/Fastify/Hono | **Node/Backend** | `npm ci && npm run lint && npm run build && npm test` |
| `requirements.txt` / `pyproject.toml` | **Python** | `python -m py_compile` + `ruff check` + `pytest` |
| `Cargo.toml` | **Rust** | `cargo check && cargo clippy && cargo test` |
| `go.mod` | **Go** | `go vet ./... && go test ./...` |
| `Gemfile` | **Ruby** | `bundle exec rubocop && bundle exec rspec` |
| Only `.py` scripts, no framework | **Python/Scripts** | `python -m py_compile` on each `.py` file |
| R scripts (`.R`) | **R** | `Rscript -e "parse('file.R')"` syntax check |
| Mixed / unclear | **Minimal** | File existence + syntax checks only |

Also determine:

- **Is it a web app?** (has server/frontend → Vercel/Netlify may apply)
- **Is it a library?** (has setup.py/package.json with main/exports)
- **Is it a data pipeline/academic project?** (scripts, notebooks, no server)
- **Existing CI?** (check `.github/workflows/`, `.gitlab-ci.yml`, etc.)
- **Existing CLAUDE.md?** (merge, don't overwrite)

Record your classification explicitly before proceeding.

### Phase 1: Generate `scripts/verify.sh`

Create a deterministic, non-interactive verification script. Rules:

1. **Only include checks whose tools exist in the repo** — e.g., don't add `npm test` if there's no test script in package.json
2. **Must be runnable with `bash scripts/verify.sh`** — no arguments required
3. **Exit 0 on success, non-zero on failure** — Ralph gates on this
4. **Include timing** — report how long verification took
5. **Graceful degradation** — if an optional tool (ruff, shellcheck) is missing, warn but don't fail

Template structure:

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

PASS=0
FAIL=0
WARN=0
START_TIME=$(date +%s)

pass() { ((PASS++)); echo "  PASS: $1"; }
fail() { ((FAIL++)); echo "  FAIL: $1"; }
warn() { ((WARN++)); echo "  WARN: $1 (non-blocking)"; }

echo "=== Verification: $(basename "$REPO_ROOT") ==="
echo ""

# --- Section 1: File Integrity ---
echo "[1/N] File integrity..."
# (adapt per repo: check critical files exist)

# --- Section 2: Syntax / Compile ---
echo "[2/N] Syntax check..."
# (adapt per stack)

# --- Section 3: Lint ---
echo "[3/N] Lint..."
# (adapt per stack, skip if no linter configured)

# --- Section 4: Tests ---
echo "[4/N] Tests..."
# (adapt per stack, skip if no test runner)

# --- Section 5: Build ---
echo "[5/N] Build..."
# (adapt per stack, skip if no build step)

# --- Summary ---
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
echo ""
echo "=== Results ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "  Warnings: $WARN"
echo "  Time: ${ELAPSED}s"

if [ "$FAIL" -gt 0 ]; then
  echo ""
  echo "VERIFICATION FAILED"
  exit 1
fi

echo ""
echo "VERIFICATION PASSED"
exit 0
```

**Critical**: After generating, run `bash scripts/verify.sh` and fix any issues
until it passes. A verify script that fails on generation is useless.

### Phase 2: Generate `.claude/agents/reviewer.md`

Create a strict reviewer subagent. This is NOT a rubber stamp — it must find
real issues or explicitly justify why there are none.

```markdown
# Strict Code Reviewer

You are a senior engineer performing a final review before code is declared complete.
Your job is to find problems, not to praise. You are the last gate before shipping.

## Review Protocol

1. **Read the diff** — `git diff HEAD~1` or the specified range
2. **Read verify results** — check if `bash scripts/verify.sh` passes
3. **Apply checklist below** — every item must be explicitly addressed

## Checklist

### Correctness
- [ ] Does the code do what it claims?
- [ ] Are there off-by-one errors, null/undefined risks, or race conditions?
- [ ] Are error paths handled (not just the happy path)?

### Security
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] No SQL injection, XSS, or path traversal vulnerabilities
- [ ] Sensitive data not logged or exposed in error messages

### Quality
- [ ] No dead code, commented-out blocks, or TODO hacks left in
- [ ] Functions are reasonably sized (flag >50 lines)
- [ ] No copy-paste duplication that should be extracted
- [ ] Naming is clear and consistent with repo conventions

### Completeness
- [ ] All files that should be modified ARE modified
- [ ] No unintended file changes (check git diff for surprises)
- [ ] Documentation updated if behavior changed
- [ ] Tests added/updated for new functionality

### Repo Hygiene
- [ ] No secrets in `.gitignore`-excluded patterns accidentally committed
- [ ] No large binary files added without justification
- [ ] Commit message accurately describes the change

## Output Format

```
## Review: [scope description]

### Verdict: PASS / FAIL / CONDITIONAL PASS

### Findings

#### Critical (blocks merge)
- [C1] description — file:line

#### Important (should fix before merge)  
- [I1] description — file:line

#### Minor (fix when convenient)
- [M1] description — file:line

#### Positive (things done well)
- [P1] description

### Recommendation
[One sentence: what should happen next]
```

## Rules

1. **You MUST find at least one issue OR explicitly explain why the code is flawless** — a review with zero findings and no justification is invalid.
2. **Every PASS verdict must include positive findings** — what specifically was done well.
3. **CONDITIONAL PASS** means: acceptable to merge, but these issues should be tracked.
4. **Never rubber-stamp.** If you can't find issues, say "I reviewed X files totaling Y lines and found no issues because [specific reason]."
```

### Phase 3: Generate `CLAUDE.md`

Adapt to the actual repo. Include:

1. **Project summary** (from README)
2. **Stack declaration** (from Phase 0 detection)
3. **Key commands** (only verified-working ones)
4. **Autonomous dev rules**:
   - Always run `bash scripts/verify.sh` after changes
   - Always invoke the reviewer agent before declaring completion
   - Never commit secrets
   - Follow existing code patterns
5. **Ralph loop invocation** (generated in Phase 5)
6. **File map** (key directories explained)

### Phase 4: Configure Hooks (if supported)

Check if the repo has `.claude/settings.json` or `.claude/settings.local.json`.
If repo-level hooks are supported in the current Claude Code version:

```json
{
  "hooks": {
    "pre-commit": {
      "command": "bash scripts/verify.sh",
      "description": "Run verification before commit"
    }
  }
}
```

**If hooks are NOT supported** (check by reading Claude Code docs or testing),
document this clearly:
```
Status: NOT CONFIGURED
Reason: Repo-level Claude hooks require Claude Code X.Y+. Current env does not support.
Alternative: Add `bash scripts/verify.sh` to CLAUDE.md as a manual rule.
```

### Phase 5: Ralph Loop Recommendation

Ralph uses the **official Anthropic ralph-loop plugin** (NOT `/loop`). The plugin
uses a Stop hook to block Claude's exit and re-feed the same prompt. Completion
is gated by `<promise>` XML tags matched against `--completion-promise`.

Generate the exact `/ralph-loop` invocation for this repo. The verification and
reviewer gates must be embedded IN the prompt (since Ralph re-feeds the same prompt).

Format:

```
Recommended Ralph invocation:

/ralph-loop Implement {task}. After each iteration:
1. Run bash scripts/verify.sh — if FAIL, fix and re-run (max 3 retries)
2. When verify passes AND task is complete, read .claude/agents/reviewer.md and apply full review
3. Only output <promise>DONE</promise> if reviewer verdict is PASS or CONDITIONAL PASS
4. If reviewer says FAIL, address Critical findings and continue iterating
--completion-promise 'DONE' --max-iterations {N}
```

Adapt max-iterations based on repo complexity:
- Small scripts repo → `--max-iterations 10`
- Medium app → `--max-iterations 20`
- Large system → `--max-iterations 50`

Also note: users can use `/ralph {task}` which auto-selects the profile (Sprint/Build/Marathon)
and constructs the full `/ralph-loop` invocation. See the ralph skill for details.

### Phase 6: Evaluate GitHub CI

If the repo has a GitHub remote:

1. Check if `.github/workflows/` already exists
2. If not, generate a CI workflow that runs `scripts/verify.sh`
3. Use the correct stack (actions/setup-python, actions/setup-node, etc.)
4. Only add if the verify script actually passes locally first

If pushing is appropriate (user owns the remote):
```
Status: READY TO PUSH
Command: git push origin main
```

If the remote belongs to someone else:
```
Status: REQUIRES ACCOUNT ACCESS
Reason: Remote is {url} — you need push access to configure CI
```

### Phase 7: Evaluate Deployment

**Only for web apps / services.** Check for:

| Signal | Platform | Action |
|--------|----------|--------|
| `next.config.js`, `vercel.json` | Vercel | Generate/update `vercel.json` |
| `netlify.toml`, static site | Netlify | Generate/update `netlify.toml` |
| `Dockerfile`, `docker-compose.yml` | Docker | Document docker commands |
| No web server at all | None | Skip with explanation |

For non-web projects (data pipelines, academic code, CLI tools, libraries):
```
Status: NOT APPLICABLE
Reason: This is a [type] project — no web server to deploy.
Evidence: No server framework in dependencies, no frontend build.
```

### Phase 8: Social Media Launch Copy

**Only if appropriate.** Before writing copy:

1. **Infer product positioning** from README, code, and context
2. **State assumptions explicitly** if positioning is uncertain
3. **Generate for Xiaohongshu and X (Twitter)**

Use the cn-content-matrix skill's style guidelines if available:
- Xiaohongshu: first-person sharing, emoji-heavy, short paragraphs, hashtags
- X/Twitter: concise, hook + value + CTA, thread format if needed

Output to `docs/social_media/xiaohongshu.md` and `docs/social_media/x_twitter.md`

If the project is academic/internal/not launchable:
```
Status: NOT APPROPRIATE
Reason: This is an academic research project — social media launch copy
would misrepresent its purpose. Consider academic channels instead.
```

## Final Report Format

After all phases, output:

```markdown
## Repo Bootstrap Complete

### Files Created/Modified
| File | Status | Description |
|------|--------|-------------|
| scripts/verify.sh | CREATED | Deterministic verification |
| .claude/agents/reviewer.md | CREATED | Strict reviewer subagent |
| CLAUDE.md | CREATED | Project rules |
| ... | ... | ... |

### Status Classification
| Component | Level | Notes |
|-----------|-------|-------|
| Verification | 1-Configured + 2-Validated | verify.sh passes locally |
| Reviewer | 1-Configured | subagent created |
| Ralph loop | 1-Configured | invocation in CLAUDE.md |
| CI | 3-Requires access | needs push to remote |
| Deployment | 4-Not applicable | not a web app |
| Social copy | 4-Not appropriate | academic project |

Status levels:
1. Fully configured in repo
2. Validated locally
3. Requires your account access
4. Not possible / not appropriate in current context

### Verification Results
(actual output from bash scripts/verify.sh)

### Reviewer Findings
(actual output from reviewer agent)

### Remaining Manual Steps
1. ...
2. ...

### Exact Next Commands
```bash
# ...
```
```

## Rules

1. **Inspect first, generate second** — never create files before understanding the repo
2. **Only include working commands** — test every command you put in verify.sh
3. **Adapt, don't template-paste** — every repo gets custom output
4. **Four-level status reporting** — always classify each component
5. **Verify must pass before declaring bootstrap complete**
6. **Reviewer must run before declaring bootstrap complete**
7. **No invented commands** — if a tool isn't installed, skip or warn
8. **Lean output** — don't generate files the repo doesn't need
