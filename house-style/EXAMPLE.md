# Occam house style — EXAMPLE (template)

> Copy this file, delete these quoted instructions, and fill in your repo's real
> patterns. Everything below is a placeholder.

**Where to put it.** Save it as `.claude/occam-house-style.md` in the repo it
describes — that's the recommended home: it lives with the code, stays private if
the repo is private, and Occam picks it up automatically. (If you maintain your own
fork of the Occam plugin, you can instead bundle it as
`house-style/<your-repo-basename>.md` and Occam matches it by repo-root basename.)

**What belongs here vs. not.** This file is the *over-engineering* layer — the
"we don't do X here" judgment calls that a linter can't catch. Do **not** restate
rules your tooling already enforces (`.cursor/rules/*.mdc`, `CLAUDE.md`, ESLint,
etc.); Occam reads those directly. Capture only what they miss.

**You don't write the learnings file.** Occam keeps a separate
`.claude/occam-learnings.md` that *it* maintains automatically from your accept/reject
decisions each run. When a learning there proves durable, Occam offers to promote it
*into this file*. So this house style is the curated, intentional layer; learnings is
the running memory that feeds it.

---

## Operational notes

> Facts Occam needs to operate. Fill in the real values.

- **Base branch:** `main` — the ref review-time mode diffs against (`<base>...HEAD`).
- **Formatter (run after each applied edit):** `<your formatter command> <file>`
  (e.g. `npx prettier --write`, `gofmt -w`, `ruff format`).
- **Expected, non-creep changes:** any change that *looks* like scope creep but is
  required every branch — e.g. a version bump in a touched module — so Occam doesn't
  flag it. Note the variant that *would* be creep (e.g. bumping it twice).

## Known non-idiomatic offenders (lens: non-idiomatic)

> Constructs your codebase deliberately avoids — flag them when introduced for a
> single case where a plainer in-repo pattern already exists. Replace with yours.

- Caching / memoization infrastructure the codebase doesn't already have
  (hand-rolled `Map`/`WeakMap` caches, memo wrappers) — prefer the existing pattern.
- New abstraction layers (HOCs, render-prop wrappers, generic `<Foo<T>>` components,
  config-object factories) introduced for **one** call site — inline it.
- Defensive ceremony (try/catch, null-guards, optional chaining) for states that
  cannot occur.
- Prose comments that restate what the code does.

## Reuse-first surfaces (lens: reinvented-helper)

> The shared modules a new helper most often reinvents. List **real paths** so the
> lens can name the existing thing the change should have used.

- `src/shared/utils.*` — shared helpers (formatting, HTTP, etc.).
- `src/shared/hooks.*` — shared hooks.
- `src/shared/components/*`, `src/icons/*` — wrappers for primitives already exist;
  a raw primitive is usually both a convention violation and a reinvention.

## Scope discipline (lens: scope-creep)

> What counts as drifting beyond the task in this repo.

- Drive-by reformatting, unrelated renames, and "while I was here" refactors in files
  the task didn't require are scope creep, even when individually harmless.
- Cross-platform / multi-target handling added for a target the task didn't aim at is
  premature generality, not robustness.

## Leave alone (not slop — don't flag)

> Deliberate patterns that look like slop but are correct here. Listing them up front
> saves the verify pass work and stops false positives.

- e.g. literal hex colors that must stay literal unless they match a design token —
  a correctness rule, out of scope for simplicity review.
