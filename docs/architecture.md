# Dev Flow — Architecture Diagrams

## 1. Full Pipeline

```mermaid
flowchart TD
    USER([" /dev-flow &quot;project idea&quot; "]):::entry --> P1

    subgraph SUB["  Subagent Phases — each runs in an isolated context window  "]
        P1["**Phase 1: SCOPE**\n/project-scoper\n📦 1,284 tokens"]:::sub
        P2["**Phase 2: PLAN**\n/planner\n📋 816 tokens"]:::sub
        P3["**Phase 3: ARCHITECT**\n/architect\n🏗 1,182 tokens"]:::sub
        P4["**Phase 4: REVIEW**\n/santa-method\n⚔️ 1,653 tokens"]:::sub
    end

    subgraph MAIN["  Main Conversation — filesystem access  "]
        P5["**Phase 5: BOOTSTRAP**\n/repo-bootstrap + /dev-router\n🔧 3,424 + 510 tokens"]:::main
        P6["**Phase 6: EXECUTE**\n/ralph\n🚀 2,427 tokens"]:::main
    end

    P1 -->|"blueprint\n~500 tokens"| P2
    P2 -->|"plan\n~500 tokens"| P3
    P3 -->|"ADR\n~500 tokens"| P4

    P4 -->|"APPROVED ✅"| P5
    P4 -->|"NEEDS REWORK"| GATE{{"⚠️ Gate\nask user"}}:::gate
    GATE -->|"re-architect"| P3
    GATE -->|"proceed anyway"| P5

    P5 -->|"files written\nproject registered"| P6
    P6 --> DONE([" ✅ /ralph-loop invocation\nready for autonomous dev "]):::entry

    classDef entry fill:#1e293b,stroke:#7c3aed,color:#e2e8f0
    classDef sub fill:#1e3a5f,stroke:#3b82f6,color:#e2e8f0
    classDef main fill:#1a3a2a,stroke:#22c55e,color:#e2e8f0
    classDef gate fill:#4a1a1a,stroke:#ef4444,color:#fca5a5
```

---

## 2. Subagent Context Isolation

Why each thinking phase runs in its own agent:

```mermaid
block-beta
  columns 5

  block:MAIN["Main Context\n~9,972 tokens\n(stays lean)"]:1
    O["dev-flow\norch.\n2,348"]
    S1["summary\n500"]
    S2["summary\n500"]
    S3["summary\n500"]
    S4["summary\n400"]
  end

  ARROW1<[" "]:right>:1

  block:A1["Subagent 1\n~39K used\nthen released"]:1
    SK1["project\n-scoper\n1,284"]
    W1["deep\nwork\n8K+"]
  end

  block:A2["Subagent 2\n~39K used\nthen released"]:1
    SK2["planner\n816"]
    W2["deep\nwork\n8K+"]
  end

  block:A3["Subagent 3\n~40K used\nthen released"]:1
    SK3["architect\n1,182"]
    W3["deep\nwork\n10K+"]
  end

  A1-- "→ 500 tok" -->MAIN
  A2-- "→ 500 tok" -->MAIN
  A3-- "→ 500 tok" -->MAIN
```

---

## 3. Token Budget: Dev Flow vs Alternatives

```mermaid
xychart-beta horizontal
  title "Main Context Token Cost (lower = better)"
  x-axis ["Dev Flow (subagents)", "Sequential skills", "Mega-skill"]
  y-axis "tokens in main context" 0 --> 30000
  bar [9972, 27786, 17457]
```

---

## 4. Skill Map

```mermaid
graph LR
    DF["🎯 /dev-flow\norchestrator"]

    subgraph PIPELINE["Pipeline Skills"]
        PS["📦 /project-scoper\nclassify + filter scope"]
        PL["📋 /planner\nphases + steps"]
        AR["🏗 /architect\nsystem design + ADRs"]
        SM["⚔️ /santa-method\nadversarial review"]
        RB["🔧 /repo-bootstrap\nverify.sh + reviewer + CLAUDE.md"]
        RA["🚀 /ralph\ngated autonomous loop"]
        DR["🖥 /dev-router\nlocal launcher registration"]
    end

    subgraph ONDEMAND["On-Demand (not orchestrated)"]
        FD["🎨 /frontend-design"]
        WG["🔍 /web-design-guidelines"]
        SA["🔎 /skill-agent"]
    end

    DF -->|"Phase 1"| PS
    DF -->|"Phase 2"| PL
    DF -->|"Phase 3"| AR
    DF -->|"Phase 4"| SM
    DF -->|"Phase 5"| RB
    DF -->|"Phase 5"| DR
    DF -->|"Phase 6"| RA

    PS -.->|"blueprint"| PL
    PL -.->|"plan"| AR
    AR -.->|"ADR"| SM
    SM -.->|"consensus"| RB

    RA -.->|"during dev"| FD
    RA -.->|"during dev"| WG
    RA -.->|"when stuck"| SA

    style DF fill:#7c3aed,color:#fff
    style ONDEMAND fill:#1a1a2e,stroke:#555
```

---

## 5. Phase 5 Detail: Bootstrap + Dev Router

```mermaid
flowchart LR
    IN(["Phase 4\nconsensus\n+ blueprint\n+ plan"])

    subgraph P5["Phase 5: BOOTSTRAP (main conversation)"]
        direction TB
        D1["Create project dir\n~/Claude/Projects/"]
        D2["git init"]
        D3["scripts/verify.sh\n(stack-adapted)"]
        D4[".claude/agents/\nreviewer.md"]
        D5["CLAUDE.md\n(blueprint + ADR\n+ Ralph invocation)"]
        D6["GitHub CI\n.github/workflows/"]
        D7["dev-router\nregistration\n✓ entry point\n✓ localhost:4000"]

        D1 --> D2 --> D3 --> D4 --> D5 --> D6 --> D7
    end

    OUT(["Phase 6\nralph\ninvocation"])

    IN --> D1
    D7 --> OUT
```

---

## 6. Ralph Loop Mechanism

How Ralph differs from `/loop`:

```mermaid
sequenceDiagram
    participant U as User
    participant R as ralph-loop plugin
    participant H as Stop Hook
    participant C as Claude

    U->>R: /ralph-loop "task" --completion-promise 'DONE'
    R->>C: write .claude/ralph-loop.local.md
    R->>C: start with prompt

    loop Each Iteration
        C->>C: work on task
        C->>C: run bash scripts/verify.sh
        C->>C: if complete → read reviewer.md
        C-->>H: tries to exit
        H->>H: read transcript, check for <promise>DONE</promise>
        alt promise NOT found
            H->>C: block exit, re-feed same prompt
            Note over C: sees previous work in files + git
        else promise FOUND
            H->>U: allow exit ✅
        end
    end
```
