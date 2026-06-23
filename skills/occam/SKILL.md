---
name: occam
description: Review a diff for AI slop and over-engineering — single-use abstractions, reinvented helpers, scope creep, premature generality, dead weight, non-idiomatic code — then produce a short, ranked, low-noise findings list with concrete simpler rewrites. Runs in two modes: author-time on the uncommitted working-tree diff (default, before you commit) and review-time on a branch/PR diff. Use this whenever the user says "/occam", "check this for slop", "is this over-engineered?", "trim this PR", "review my diff for over-engineering", or wants the AI's own output simplified before a human reviews it. Prefer this over an ad-hoc eyeball pass for any over-engineering / simplification review.
---

# Occam

Occam reviews a diff with one job: **cut what the change didn't need.** It hunts the failure modes of AI-written code — too much abstraction, code that ignores what the repo already has, scope creep beyond the task — and returns a short, trustworthy list, not a wall of nitpicks.

## Why this shape (read before running)

A single broad review pass misses slop because it isn't *looking* for it — it optimizes for bugs. Occam fixes that three ways, and you must not collapse them:

1. **One focused pass per slop category** (fanned out as parallel subagents) — high recall, because each pass has one narrow job and concrete examples.
2. **An adversarial verify pass** — every candidate finding gets a skeptic that tries to *justify* the code. Anything the skeptic can defend is dropped. This is what keeps the output low-noise and trustworthy. A reviewer that cries wolf gets ignored.
3. **A ranked, short output** with a concrete simpler rewrite per finding — so it's actionable and (author-time) auto-applyable.

This is correctness-quality work, so do not guess. If the diff or intent is unclear, say so rather than inventing findings.

## Step 0 — Identify the repo and load its house style

This skill ships as a plugin and runs across repos, so first figure out where you are and load the matching house style.

1. Identify the repo: `git remote get-url origin` and `basename "$(git rev-parse --show-toplevel)"`.
2. Resolve the plugin root: if `$CLAUDE_PLUGIN_ROOT` is set, use it; otherwise find it with `find "$HOME/.claude" -type f -path '*/occam/house-style/*.md' 2>/dev/null | head -1` and take its parent's parent.
3. Read the matching house-style file `house-style/<key>.md` in full, where `<key>` is the repo-root basename (e.g. `web-app`, `mobile-app`). It carries the repo's slop-specific anti-patterns, reuse surfaces, scope rules, and **operational notes** (base branch, formatter command, version-bump rule). The plugin ships only a generic `house-style/EXAMPLE.md` template; real bundled styles exist only if you maintain your own fork.
4. If no bundled house-style matches, check for a repo-local `.claude/occam-house-style.md` and use it — this is the usual place a repo keeps its house style. If neither exists, proceed with the built-in lenses below and state in the output that no repo house style was loaded (findings will be convention-agnostic). The house style enriches the lenses; it is not required to run.

The house style deliberately does **not** duplicate the repo's convention rules; those live in the repo (e.g. `.cursor/rules/*.mdc`, `CLAUDE.md`). When present, skim their titles and read any a hunk plausibly touches. Occam enforces *simplicity and conformance*, not just taste.

## Modes

Occam runs against a diff. Pick the mode from how it's invoked:

- `/occam` (no arg) → **author-time**. Review the uncommitted working-tree diff (`git diff HEAD`). This is the default and the common case: catch slop before it becomes a PR. You may auto-apply approved fixes.
- `/occam pr` or `/occam <base-ref>` → **review-time**. Review the branch diff (`git diff <base>...HEAD`; base from the house-style operational notes, default `master`). Output is read-only findings; offer to post them as PR comments via `gh` only if asked.
- `/occam <path>` → scope the review to a single file or folder within the chosen diff.

If there is no diff to review (clean working tree in author-time mode), say so and stop.

## Step 1 — Get the diff and the intent

1. Resolve the diff for the mode above. Exclude noise: lockfiles, `*.snap`, generated files, build config (pbxproj/gradle/etc.).
2. Establish **intent** — what was this change *supposed* to do? In order of preference:
   - the linked issue / PR body (`gh pr view`, `gh issue view`) for review-time,
   - the current task / conversation goal for author-time,
   - the commit messages on the branch.
   Scope-creep detection is impossible without intent, so if you genuinely can't determine it, ask one short question before continuing.

## Step 2 — Fan out the slop lenses

Spawn one review subagent per lens **in parallel** (Task / Agent tool). Give each the diff, the intent, and the house style. Each returns findings as a list of `{ file, lines, lens, title, why, rewrite }` — `rewrite` is the concrete simpler version (a code sketch or a precise instruction), never just "simplify this".

The lenses:

1. **single-use-abstraction** — a new function / hook / component / type / config object / named constant introduced and used exactly once, where inlining is clearer. (Verify call-site count before flagging.)
2. **reinvented-helper** — logic that duplicates something the repo already has. Check the house-style reuse surfaces and grep before flagging; cite the existing thing it should have used.
3. **scope-creep** — files or hunks that do something other than the stated intent (drive-by refactors, unrelated renames, "while I was here" changes). These bloat the diff and the review.
4. **premature-generality** — params, options, flags, generic type parameters, or config that nothing in the diff actually uses; handling for cases that can't occur; "future-proofing"; platform branches the change doesn't target.
5. **dead-weight** — unused exports/params, defensive branches for impossible states, redundant try/catch beyond a mandated async rule, and **comment noise** (prose comments that restate the code).
6. **non-idiomatic** — constructs the codebase doesn't use, introduced when a plainer in-repo pattern exists. See the house style for the known offenders.

Tell each lens: verify before flagging (grep call sites / find the existing helper), cap at its highest-confidence findings, and bias toward precision.

## Step 3 — Adversarially verify

Dedupe overlapping candidates (same lines, different lenses → merge), then for each finding spawn a skeptic (parallel) that argues the code is **justified** — is the abstraction used elsewhere outside the diff? is the generality actually required by a real caller? is the "duplicate" subtly different? is the flagged change actually in scope per the intent/linked issue? is a "dead" pattern a pre-existing copied convention rather than something this diff introduced?

Verdicts: **keep** (real slop), **downgrade** (real but a judgment call → severity "consider"), **drop** (defensible / false positive / a correctness bug, not slop / pre-existing and not introduced here). Bias toward dropping: a short list people trust beats a long list they learn to skip.

## Step 4 — Rank and write the findings

Rank by impact: how much code removed / how much review burden saved. Severity is simplicity-flavored:

- **cut** — clear over-engineering; the simpler version is plainly better. Remove/inline.
- **consider** — a real simplification but a judgment call; reasonable to keep.

Write `.tasks/occam-<slug>-<YYYY-MM-DD>.md` in the repo under review (slug = branch name or target path, kebab-cased). Never overwrite same-day files; append `-2`, `-3`. Use markdown links **relative to `.tasks/`** — every source link starts with `../` (e.g. `[index.tsx:42](../src/.../index.tsx#L42)`), with GitHub line anchors `#L42` / `#L42-L51`.

```markdown
# Occam — <target> (<mode>)

**Date:** <YYYY-MM-DD>
**Diff:** <what was reviewed, e.g. working tree / master...HEAD>
**Intent:** <one line — what the change was meant to do>

## Summary
- Cut: N   ·   Consider: N   ·   Lines the cuts remove: ~N

## Cut
- [ ] **<title>** — [path:42](../path#L42) · *<lens>*
  - **Why:** <why it's more than the task needed>
  - **Rewrite:** <the simpler version — sketch or precise instruction>

## Consider
- [ ] ... (same shape)
```

Record findings the verify pass dropped or rerouted in short trailing sections (**Out of scope — possible bugs**, **Dropped by the verify pass**) so the reasoning is auditable and the tool can be calibrated. If nothing survives verification, write `No slop found — the change is about as small as the task allows.` and stop.

## Step 5 — Present, then (author-time) apply

Tell the user concisely: where the file is, the counts, lines saved, and the 2–3 biggest cuts. Then:

- **Author-time:** ask "Which should I apply? ('all cut', 'all', numbers/titles, or 'none')." Wait for an explicit answer. Apply one finding per edit, tick its checkbox in the same turn, then run the repo's formatter (from the house-style operational notes) on the edited file. Keep edits surgical.
- **Review-time:** stop after presenting. Offer to post as inline PR comments via `gh` only if asked.

## Guardrails

- Don't expand scope: Occam reviews simplicity/conformance. If you spot a real **bug**, note it in **Out of scope — possible bugs**; don't fix it here.
- Don't flag a "duplicate" or "single use" without verifying call sites / existing helpers first — a wrong cut is worse than a missed one.
- A pre-existing copied convention that this diff merely repeats is not slop *this PR introduced* — drop it (or note it separately), don't bill it to the author.
- Never batch findings into one edit. One finding, one edit, one checkbox — that's what keeps it reversible.
- The house style is a living seed. If the user confirms a new repo-specific anti-pattern during a run, offer to append it to whichever house style is in effect — the repo-local `.claude/occam-house-style.md`, or a bundled `house-style/<key>.md` if a fork uses one.
