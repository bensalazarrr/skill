# The project map

**Location:** `.agent/PROJECT_MAP.md` at the repo root.
**Purpose:** an index, so a future session finds the right file in one read instead of a scan.
**Budget:** ≤120 lines. Past that it's becoming a second copy of the repo — cut it back.

## Format rules

- Index, not documentation: paths, roles, commands. No code snippets, no history, no design essays.
- Describe directories at the level a newcomer needs (`src/api/ — one handler per route`), and name only load-bearing files.
- Write `?` for anything you haven't confirmed. Guesses dressed as facts are worse than gaps.
- Scale to the repo. A small project deserves a ~20-line map; 120 is a ceiling for a large one, not a target. Delete empty sections rather than filling them with "none".
- Commit the map when the project is shared. It earns its line count for every teammate and every future session.
- One map per repo. In a monorepo with genuinely separate toolchains, one map per package, ≤80 lines each.

## Template

```markdown
# Project Map
<!-- updated: YYYY-MM-DD · keep ≤120 lines · index only -->

## What this is
<product in one line>. Stack: <lang/framework/runtime>. Package manager: <x>.

## Commands
- install:
- dev:
- typecheck:
- lint:
- test one file:
- full test:
- build:

## Layout
| Path | Holds | Go here for |
|---|---|---|
| `src/api/` | HTTP handlers | new endpoint |
| `src/ui/` | screens and components | UI change |
| `src/lib/` | shared helpers | utilities |
| `src/db/` | schema, queries, migrations | data model change |
| `tests/` | tests, mirroring src | adding a test |

## Key files
- `path` — why it matters (source of truth, central, dangerous to change)

## Conventions
- errors:
- naming:
- state/data:
- imports:

## Don't touch
- `path/**` — reason (generated, append-only, secret)

## Gotchas
- things that will bite a newcomer: env vars, codegen, ordering, a slow step
```

## Bootstrapping

When there's no map and the repo has at least ~25 source files (use the scanner's count):

1. Run the scanner. It prunes dependencies and build output, caps its output so it stays cheap to read, and lists what it pruned so you can still spot generated directories:
   - Windows: `powershell -NoProfile -File scripts/scan-project.ps1 -Root . -MaxFiles 150` (`pwsh` works too, if installed)
   - POSIX: `sh scripts/scan-project.sh . 150`
   - Paths inside the skill are relative to the skill directory; use the absolute path to the script if the working directory is the project.
2. Read the manifests it names, plus at most four entry points: app entry, router, schema/model, one representative feature file. That's the ceiling — a coarse map now beats a perfect map never.
3. Fill the template. Directories you didn't open get a one-line guess with `?`.
4. Tell the user in one line what you created, then continue with the task. The bootstrap is a means, not a deliverable.

Small repo (under ~25 source files): skip the map. An index costs more than working directly — a 45-line map for 5 files is a net loss, however well written.

## Drift check

At the end of every task, cheaply:

- `git status --porcelain` — paths only, never a full diff. Any changed path the map doesn't cover → add it, or generalize the directory line.
- If the map names a file that no longer exists → correct or delete that line.
- A command you had to dig for → add it to Commands. That's the highest-value line in the whole file, because it's the one that saves the most future tokens.

## Repairing a wrong map

A pointer is wrong or a file is missing → fix that line in the same turn you found it. Rescanning the repo to work around a bad map means paying full price twice, and the map stays broken for the next session.

## Anti-patterns

- Listing every file. That's `git ls-files` with extra steps and no value.
- Stale entries left "for later". The next session trusts a lie and pays for it.
- Regenerating the map from scratch every session. That's just expensive scanning with a nicer name.
