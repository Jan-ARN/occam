# Occam house style — EXAMPLE (template)

Copy this into your repo as `.claude/occam-house-style.md` (preferred — it stays
with your code and never touches the plugin), or bundle it in the plugin as
`house-style/<your-repo-basename>.md` if you maintain your own fork. Delete the
guidance comments and fill in your repo's real anti-patterns.

This file captures the *over-engineering* layer — "we don't do X here" rules that
your lint/convention docs (`.cursor/rules/*.mdc`, `CLAUDE.md`) don't already cover.
Don't duplicate convention rules here; Occam reads those directly.

## Operational notes

- **Base branch:** `main` (the ref Occam diffs against in review-time mode).
- **Formatter (run after each edit):** `<your formatter command> <file>`.
- **Version bumps / release rules:** any expected, per-branch bump that should *not*
  be treated as scope creep — and the variant that should.

## Known non-idiomatic offenders (lens: non-idiomatic)

Constructs your codebase deliberately avoids. Flag them when introduced for a
single case where a plainer in-repo pattern exists. Examples to replace:

- Caching/memoization infrastructure the codebase doesn't already have.
- New abstraction layers (HOCs, render-prop wrappers, generic components,
  config-object factories) introduced for one call site — inline it.
- Defensive ceremony (try/catch, null-guards, optional chaining) for states that
  can't occur.
- Prose comments that restate the code.

## Reuse-first surfaces (lens: reinvented-helper)

The shared modules a new helper most often reinvents. List the real paths so the
lens can cite the existing thing the change should have used:

- `src/shared/utils.*` — shared helpers.
- `src/shared/hooks.*` — shared hooks.
- shared component / icon wrappers — raw primitives are usually a reinvention.

## Scope discipline (lens: scope-creep)

- Drive-by reformatting, unrelated renames, and "while I was here" refactors in
  files the task didn't require are scope creep, even when individually harmless.
- Note any pre-existing copied template/boilerplate that looks dead but should
  *not* be billed to the author.
