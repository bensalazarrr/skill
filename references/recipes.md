# Recipes

Read only the recipe that matches. Each is the shortest path that ends in a complete, verified change. If reality doesn't match a step, say which step broke — don't improvise a tour of the repo.

## Add a field end to end

1. Map → the schema/model file, the layer that exposes it, the UI that shows it. Three files, not more.
2. Schema: add it nullable or with a default. Old rows must survive.
3. Migration, if the project has them: append a new one; never edit one that's already applied.
4. Find the layer that owns the shape: serializer, DTO, field list, or schema — one grep for the existing field's name. If the shape is field-list-driven (a loop over schema fields), the schema edit is the entire propagation: check the consumer and stop. Don't add a redundant branch just to look thorough.
5. UI: render it, handle the empty case.
6. Tier 1 if it's durably stored, crosses a trust boundary, or is money-related; tier 2 if it's only displayed; otherwise tier 0.
7. Verify: typecheck, then the one test file or the smoke path.

## Add an endpoint or route

1. Map → an existing sibling route. Copy its shape rather than a remembered pattern.
2. Handler: validate input at the boundary, return the project's standard error shape.
3. Register the route where its siblings are registered.
4. Reuse the existing auth/permission helper — one grep for it. A second permission check is a future vulnerability.
5. Tier 1 only if it writes data or checks permissions; otherwise tier 0, plus a manual call if that's cheap.

## Add a screen or page

1. Map → the routing file and one existing screen.
2. Create the component beside its siblings and wire the route.
3. Reuse the existing layout, spacing, and state patterns.
4. No new global state, no new styling system, no new dependency.
5. Tier 2: build and render smoke. Say "not visually verified" if you couldn't see it.

## Fix a bug

1. Reproduce first: state the failing input, the observed behavior, and the expected one — before editing anything. If you can't reproduce it, say so and ask for the input rather than guessing.
2. One grep on the error text or the symbol in the report → the file that owns it.
3. Fix the cause, not the symptom. Keep the diff minimal.
4. Tier 1: add the regression case that failed, run it, keep it.
5. One grep for the same mistake in a sibling. Mention it; don't fix it unasked.

## Refactor safely

1. The goal must be explicit ("extract X from Y"), not "clean up".
2. Find the callers first: one grep for the symbol. The caller count is the size of the job.
3. Move in small steps: extract → typecheck → update callers → typecheck.
4. Behavior must not change, so no test edits. The existing tests are the safety net.
5. More than five files → confirm with the user before starting.
6. Tier 0; run the touched test file if one exists.

## Add a dependency (last resort)

1. First check whether the project already has a helper or the standard library covers it. One grep.
2. Say what it costs — bundle size, maintenance, security surface — and what the no-dependency version looks like in lines.
3. Ask before installing.
4. If approved: install with the project's package manager, pin the way its siblings are pinned, then verify the build.
