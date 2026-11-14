# surgical-build

A portable agent skill for building features in a codebase **without scanning the repo** and **without skipping verification**.

Plain Markdown plus two shell scripts. No dependencies, no tool-specific features — it works with any coding agent that can read files and run a shell command.

## What it does

On every build, fix, or refactor request:

1. Reads `.agent/PROJECT_MAP.md` — a ~120-line index of the repo — instead of scanning
2. Opens 1–3 files the map points to
3. Posts a five-line plan (files, risk tier, verify command) before editing
4. Makes the smallest correct change, matching local style
5. Verifies once, in proportion to risk
6. Updates the map and reports `Changed / Verified / Not verified / Map`

The map is built once per repo (skipped entirely under ~25 source files) and improves with every task, so the cost of each session stays flat while the repo grows.

## Verification tiers

| Tier | Applies to | Gate |
|---|---|---|
| 0 — always | every change | typecheck/compile + lint on touched files |
| 1 — risky | money, auth, dates, parsing, durable storage, trust boundaries | one focused test: behavior + failure case |
| 2 — presentation | UI, copy, styling | one smoke path, or an explicit "not visually verified" |

Strictness comes from honesty and blast-radius checks, not from test volume.

## Use with any agent

Clone **once per machine** into a folder that never moves — the agent reads it from there. Don't copy it into each project.

### If your agent supports skills

Put the folder where that agent looks, keeping the name `surgical-build`:

| Agent | Skills folder |
|---|---|
| OpenCode | `~/.config/opencode/skills` |
| Claude Code | `~/.claude/skills` |
| Cursor, Codex, Copilot, Gemini CLI | varies by version — check that tool's docs |

```powershell
git clone https://github.com/bensalazarrr/skill.git "$env:USERPROFILE\.config\opencode\skills\surgical-build"
```

Already have a copy? Link instead of duplicating (no admin needed on Windows):

```powershell
cmd /c mklink /J "%USERPROFILE%\.claude\skills\surgical-build" "%USERPROFILE%\.config\opencode\skills\surgical-build"
```

### If your agent has no skills support

Add one line to that agent's **global** instruction file — `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.gemini/GEMINI.md`, or the global rules equivalent:

```
Before changing code, read <absolute-path>/surgical-build/SKILL.md and follow it.
```

Same behavior, minus automatic discovery.

### If you want it in the project, not the machine

Copy the folder to `.agent/skill/surgical-build/` and reference it with a **relative** path from the committed `AGENTS.md`, so teammates and CI get it too. Trade-off: each project's copy drifts.

## Layout

```
surgical-build/
├── SKILL.md                  # the loop and the rules
├── references/
│   ├── repo-map.md           # map template, bootstrap, drift check
│   ├── verification.md       # tiers, scoped commands per stack, test rules
│   └── recipes.md            # field / endpoint / screen / bugfix / refactor
└── scripts/
    ├── scan-project.ps1      # bounded scan (any PowerShell)
    └── scan-project.sh       # bounded scan (any POSIX shell)
```

The scanner prunes dependency and build directories, caps its output, and lists what it pruned so generated folders stay visible. No shell? `SKILL.md` names the directories to skip so an agent can do the same by hand.

## Per-project artifact

`<project>/.agent/PROJECT_MAP.md` — created on the first task and committed with the project. That file, not this repo, is what makes later sessions cheap.
