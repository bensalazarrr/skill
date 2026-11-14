# Verification

Read this when the change is tier 1 (money, auth, dates, parsing, data writes, shared helpers), the stack is unfamiliar, or you need the scoped command for this project.

## The rule

Verify once, after the change is complete and coherent — not test-first, not after every line. This is a rule, not a preference: tests written before the implementation tend to assert the design you imagined, not the behavior you shipped. The one exception is reproducing a reported bug, where a failing test is how you prove you found the right cause.

The goal is a landing check that catches a real mistake, not proof of correctness. A slow, broad suite usually tells you less than one targeted check plus reading your own diff.

Order: read the diff → typecheck → lint touched files → the relevant test → a smoke path for UI. Stop at the first failure and fix it; don't stack new output on a known-bad state.

**When in doubt, tier up.** A change sitting between tier 0 and tier 1 is tier 1. One focused test is cheaper than one missed edge case, every time.

## Tiers

### Tier 0 — every change

Cheap, fast, no excuses.

- Typecheck or compile the project (or the touched package).
- Lint only the files you touched, if a linter exists.
- Must pass before you report. Quote the real output, or state that there were no errors.

### Tier 1 — risky logic

Money, auth and permissions, dates and timezones, parsing and serialization, durable storage (database, files, external services), migrations, validation and trust boundaries, shared helpers with several callers, anything with a state machine.

A field on an in-memory object that is only displayed is not tier 1 — tier 2 plus the smoke path is proportionate. Over-verifying is a real cost: four shallow checks that could never fail are worse than one that would have caught the bug.

- One test file, at most ~80 lines: the new behavior, its failure or boundary case, and for a bugfix the case that used to fail.
- Run only that file.
- If a scoped run is impossible and the suite finishes in under a minute, run it once and say that you did.

### Tier 2 — presentation

Copy, styling, layout, icons, static markup.

- No new tests.
- One smoke path: the app builds and the touched screen renders, or the existing end-to-end test that covers it.
- If you couldn't render it, write "not visually verified" instead of implying otherwise.

## Finding the right command without scanning

1. The `Commands` section of `.agent/PROJECT_MAP.md`.
2. Still unknown → read the manifest only (`package.json` scripts, `pyproject.toml`, `pubspec.yaml`, `Makefile`, `go.mod`). One file, not the tree.
3. Never invent a command. If the project has no test runner, say so — don't add a toolchain just to satisfy the gate.

## Scoped commands by stack

| Stack | Typecheck | Lint (files) | One test |
|---|---|---|---|
| TS/JS | `npx tsc --noEmit` | `npx eslint <paths>` | `npx vitest run <path>` / `npx jest <path>` |
| Node, no build | `node --check <file>` | — | `node --test <path>` |
| Python | `python -m mypy <paths>` or `pyright <paths>` | `ruff check <paths>` | `pytest <file>::<test> -q` |
| Dart/Flutter | `dart analyze <paths>` | covered by analyze | `flutter test <file>` |
| Go | `go build ./<pkg>/...` | `go vet ./<pkg>/...` | `go test ./<pkg> -run <Name>` |
| Rust | `cargo check` | `cargo clippy -p <crate>` | `cargo test <name>` |
| Ruby | `ruby -c <file>` | `rubocop <paths>` | `rspec <file>:<line>` |

A whole-project typecheck is usually the cheapest broad signal that exists. Run it even when it takes a while, then report only errors in your scope — and mention whether pre-existing errors exist, so the user isn't misled.

## When widening is justified

Run more than the touched scope only for: a shared helper with many callers, a build or config change, a dependency bump, a migration. Say why in one clause. "Just in case" is not a reason, and an unchanged suite is not evidence the feature works.

## Writing the tier-1 test

- Arrange / act / assert. One behavior per test, named after the behavior.
- Assert observable output, not internals. Never mock the unit under test.
- Table-driven when the logic is a parser or mapper.
- For a bugfix: if you can't explain why the test failed on the old code, it isn't a regression test — delete it rather than keep a decorative one.
- No snapshots for logic, no tests that assert an implementation detail a refactor would legitimately change.

## Two strikes, then stop

If the same check fails twice on the same change, stop and report: what you tried, the exact failure, and your best guess at the cause. Editing toward green turns a two-line fix into a fifty-line diff, and a second failure usually means the diagnosis is wrong rather than the code.

## Conflicts

An existing test contradicts the request, or fails for unrelated reasons → stop and report the test name, what it asserts, and the tension. Do not edit or delete it to get green. A passing suite bought by weakening a test is worse than a red one.

## Done checklist

- [ ] Diff read end to end; nothing unrelated touched
- [ ] Typecheck clean for the touched scope
- [ ] Tier-1 test written and run, if the change is tier 1
- [ ] Real output quoted in the report
- [ ] Callers of changed signatures checked
- [ ] Map updated
