---
name: Surgical Build
description: Build, fix, or refactor code in an existing project using a pre-written repo map and a small context budget, with verification scaled to risk. Use this for any code change in an app or repository — adding a feature, field, screen, or endpoint; fixing a bug; refactoring; wiring an API; "make it work"; "extend this" — even when the user gives no file paths and no plan. Use it especially in unfamiliar or large repos, when an earlier attempt edited the wrong files, or when context is running low.
---

# Surgical Build

Two things dominate the cost of agent coding work: reading the repository, and being wrong. This skill attacks both. Pay for a map once, build against it forever, and spend verification where a mistake would actually hurt.

This file is plain Markdown and uses no host-specific features. It works whether an agent loads it as a skill or reads it as a file referenced from `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, or a rules file. It assumes only two capabilities: reading and writing files, and running one shell command.

Paths below are relative to the folder that contains this file.

## The contract

1. Read the map first, then open only the files it points to.
2. Plan before editing — five lines, not an essay.
3. Exploration is budgeted; the actual work is not.
4. Verify in proportion to risk, and never claim a result you did not see.
5. Leave the map more accurate than you found it.

## Step 0 — get the map

The map lives at `.agent/PROJECT_MAP.md` in the repo root. If your host hides or skips dot-directories, `docs/PROJECT_MAP.md` is equivalent — pick one and stay consistent.

- **Exists** → read it. That's the entire discovery step.
- **Missing, repo has fewer than ~25 source files** → skip the map and work directly. An index only pays for itself once finding a file costs more than reading the map. The scanner prints a file count, so this is a measurement, not a guess.
- **Missing, real repo** → bootstrap it: run the bundled scanner with whichever shell the machine has —
  - `powershell -NoProfile -File <skill-dir>/scripts/scan-project.ps1 -Root . -MaxFiles 150`
  - `sh <skill-dir>/scripts/scan-project.sh . 150`

  No shell available? List files with the host's own file tools, skipping `node_modules`, `.git`, `dist`, `build`, `out`, `vendor`, `.venv`, `__pycache__`, `target`, `coverage`, `.next`, `.dart_tool`, `Pods`, `obj`, and `bin`.

  Then read the manifests it names plus at most four entry points, and fill in the template from `references/repo-map.md`. Say one line — "Built a coarse map at `.agent/PROJECT_MAP.md`; it will sharpen as we work" — and move on. Don't narrate the bootstrap.

A coarse map now beats a perfect map never. Mark unknowns with `?` and refine them the first time a task touches that area.

## Step 1 — locate, don't explore

The map should hand you one to three target files. Open those.

- Grep with a path or `--include`, never from the repo root without one.
- Never re-read a file that's already in context.
- A file over ~300 lines: grep the symbol, then read ±40 lines around it. Don't load the whole thing to use 30 lines.
- Budget roughly three rounds of exploration: map + targets, then gaps, then confirmation. If you still haven't found it, name what's missing, pick the most likely place, and say you're unsure — that's cheaper than a repo tour.
- If a map pointer is wrong or a file is missing, fix that line immediately. Working around a bad map means paying the scan price twice.

## Step 2 — plan gate

Before the first edit, post this, nothing longer:

```
Plan: <one sentence: what changes and why>
Files: <path> (edit), <path> (new)
Risk: tier 0/1/2 — <why>
Verify: <command(s)>
```

Skip the gate only for a one-line fix whose location is obvious — but even then, name the file before changing it. Creating the map in step 0 is exempt: it's setup, not a code change. If you bootstrap and build in the same turn, post the plan before touching project code anyway; it costs one message and prevents the most expensive failure mode — confidently editing the wrong thing.

## Step 3 — build

- Edit files; don't rewrite them wholesale to change a few lines.
- Match the file you're editing over your general preferences: its naming, error handling, imports, and comment density. The best answer looks like the code around it.
- Smallest change that fully solves the problem. No drive-by renames, reformatting, or dead-code removal.
- New dependency → stop and ask, and say what the no-dependency version would cost in lines.
- More than five files → stop and confirm with the list. That's usually a sign the plan is wrong.
- Before writing a helper, one grep for an existing one. Parallel implementations are a permanent tax.
- If a shape is ambiguous (schema, API contract, expected behavior), ask one specific question rather than inventing an answer and building on it.

## Step 4 — verify

Verify once, on the finished change. This is a landing check, not test-driven development. Read your own diff first — the cheapest bug detector available — then typecheck, lint, test, and smoke.

| Tier | Applies to | Gate |
|---|---|---|
| 0 — always | every change | typecheck/compile + lint on touched files |
| 1 — risky | money, auth, dates/timezones, parsing, durable storage, trust boundaries, shared helpers | one test file: new behavior + failure case |
| 2 — presentation | copy, layout, styling, static markup | one smoke path, or state "not visually verified" |

Non-negotiables: quote real output rather than asserting success; a red check means fix it or report it, never "that should be fine"; don't run the whole suite to feel safe when a scoped run exists; don't edit a failing test you didn't cause — report it.

Read `references/verification.md` for tier-1 test rules, scoped commands per stack, and when widening is genuinely justified.

## Step 5 — close the loop

Update the map with anything you learned: new files, moved files, a command you had to dig for, a gotcha. Prune lines that are now false. Keep it under ~120 lines — a map that mirrors the repo has stopped being an index.

Then report exactly this:

```
Changed: <path> — <what>
Verified: <command> → <observed>
Not verified: <item> (<why>)
Map: updated (<n> lines) / unchanged
```

Empty "Not verified" is the goal, not a formality. If something wasn't checked, saying so costs one line and prevents a false sense of safety.

## Stop and ask instead of guessing

- Schema changes or migrations that could lose data
- Auth, permissions, payments, secrets, destructive file operations
- Deleting or renaming something other code imports
- A request that's ambiguous in a way that changes the design
- An existing test that contradicts what was asked

Ask one specific question. Not a menu.

## Anti-patterns

- **Exploration theater** — reading twenty files to feel certain. Certainty isn't the deliverable.
- **Test theater** — many shallow tests that restate the implementation.
- **Drive-by refactor** — unrelated cleanup hiding inside a feature change.
- **Silent assumption** — guessing a data shape and building three layers on it.
- **Map rot** — editing code without updating the map, so the next session pays the scan price again.

## References

Read on demand; don't preload all of them.

- `references/repo-map.md` — template, bootstrap procedure, drift check. Read when creating or repairing the map.
- `references/verification.md` — tier details, scoped commands per stack, test-writing rules. Read at step 4 for tier 1 or an unfamiliar stack.
- `references/recipes.md` — shortest paths for common changes: field end to end, endpoint, screen, bugfix, refactor. Read when the task matches one.
