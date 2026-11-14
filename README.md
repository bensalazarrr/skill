# surgical-build

An OpenCode skill for building features in a codebase **without scanning the repo** and **without skipping verification**.

Most coding agents pay for the same discovery twice: they read half the repository to find the right file, then run a slow, broad test sweep to decide whether they're done. This skill replaces both with two cheaper things — an index and a landing check.

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

## Install

Once per machine. Skills are not copied into projects.

```sh
git clone https://github.com/bensalazarrr/skill.git ~/.config/opencode/skills/surgical-build
```

On Windows (PowerShell):

```powershell
git clone https://github.com/bensalazarrr/skill.git "$env:USERPROFILE\.config\opencode\skills\surgical-build"
```

The **folder name** is the skill ID, so it must be `surgical-build`. OpenCode scans `~/.config/opencode/skills` automatically — no configuration needed. If a running session doesn't see it, run `/reload`.

Update with `git pull` in that folder.

## Layout

```
surgical-build/
├── SKILL.md                  # the loop and the rules
├── references/
│   ├── repo-map.md           # map template, bootstrap, drift check
│   ├── verification.md       # tiers, scoped commands per stack, test rules
│   └── recipes.md            # field / endpoint / screen / bugfix / refactor
└── scripts/
    ├── scan-project.ps1      # bounded scan (Windows)
    └── scan-project.sh       # bounded scan (POSIX)
```

The scanner prunes dependency and build directories, caps its output, and then lists what it pruned so generated folders stay visible.

## Per-project artifact

`<project>/.agent/PROJECT_MAP.md` — created on the first task and committed with the project. That file, not this repo, is what makes later sessions cheap.
