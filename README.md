# occam

**A Claude Code plugin that reviews a diff for AI slop and over-engineering** — single-use abstractions, reinvented helpers, scope creep, premature generality, dead weight, non-idiomatic code — and hands back a short, ranked, low-noise list of cuts, each with a concrete simpler rewrite.

Named for Occam's razor: *don't multiply entities beyond necessity.*

```
/occam
```

```
Occam — feature/export-csv (author-time)
Cut: 3 · Consider: 1 · Lines the cuts remove: ~58

CUT
 1. Single-use formatter factory — src/export/format.ts:12 · single-use-abstraction
    makeFormatter() is called exactly once. Inline the three lines at the call site.
 2. Re-implements toCsvRow — src/export/csv.ts:40 · reinvented-helper
    Duplicates shared/csv.ts:rowToString. Import it instead.
 3. Unused `locale` option threaded through 4 functions — premature-generality
    Nothing passes it. Drop the param and the plumbing.

CONSIDER
 1. try/catch around a pure sync map — src/export/csv.ts:55 · dead-weight

Learned: don't flag the `useMemo` on the row count here (you rejected it last run).
```

## Why

AI writes too much, too fast. PRs balloon, reviewing them is exhausting, and a single generic review pass optimizes for *bugs* — it isn't even looking for the over-engineering, and it doesn't know your team's patterns. Occam is built for exactly that failure mode: it looks *only* for what the change didn't need, and it learns your "we don't do that here" over time.

## How it works

Occam isn't one prompt — it's a pipeline designed for **high recall, low noise**:

1. **Fan out.** One focused review pass per slop category, run as parallel subagents. Each has a single narrow job, so it catches what a broad pass skims past.
2. **Adversarially verify.** Every candidate finding gets a skeptic whose job is to *justify* the code. Anything defensible — a real use elsewhere, a genuine bug rather than slop, a pre-existing convention — gets dropped. This is what makes the output trustworthy; a reviewer that cries wolf gets ignored.
3. **Rank.** The survivors become a short list, each with a concrete simpler rewrite, written to `.tasks/occam-*.md` in the repo under review.
4. **Learn.** Your accept/reject decisions are recorded as calibration, so the next run is quieter and more on-target. (See below.)

### The slop lenses

| Lens | Catches |
|---|---|
| `single-use-abstraction` | A function/hook/component/type/constant introduced and used exactly once, where inlining is clearer. |
| `reinvented-helper` | Logic that duplicates something the repo already has. |
| `scope-creep` | Hunks doing something other than the stated task — drive-by refactors, unrelated renames. |
| `premature-generality` | Params, options, flags, type parameters nothing in the diff uses; handling for cases that can't occur. |
| `dead-weight` | Unused exports/params, defensive branches for impossible states, comment noise. |
| `non-idiomatic` | Constructs the codebase doesn't use, where a plainer in-repo pattern exists. |

## Two modes

- **`/occam`** — *author-time.* Reviews your uncommitted working-tree diff before you commit. Can auto-apply the cuts you approve. This is the common case: catch slop while the change is still small.
- **`/occam pr`** *(or `/occam <base-ref>`)* — *review-time.* Reviews the branch vs. its base. Read-only; can post findings as PR comments on request.
- **`/occam <path>`** — scope the review to a single file or folder.

A `Stop` hook nudges you to run `/occam` once your uncommitted diff grows past `OCCAM_DIFF_THRESHOLD` changed lines (default 150). It never blocks.

## It learns your repo

Occam gets sharper the more you use it. After each author-time run, it reads your decisions as calibration and records them to `.claude/occam-learnings.md` in the repo — **automatically, no prompts**:

- A finding you **rejected** becomes a *don't-flag* rule: Occam stops raising that pattern here.
- A finding you **applied** becomes a *confirmed* signal: that pattern is real over-engineering in this repo.

Next run, the lenses and the verify pass honor the ledger — so it stops repeating mistakes you already corrected. When a learning proves durable (it keeps recurring), Occam offers to **promote** it into your house style. That graduation is the only learning step that asks first; everything else happens quietly in the background.

Two stores, two roles:

- **Learnings** (`.claude/occam-learnings.md`) — Occam's own running memory, maintained automatically.
- **House style** (below) — curated, human-owned, often shared. The destination learnings graduate into.

## House styles

The slop lenses are generic. The per-repo "we don't do X here" knowledge — known non-idiomatic offenders, reuse-first surfaces, scope rules, and operational notes (base branch, formatter, version-bump rule) — lives in a **house style**.

Copy [`house-style/EXAMPLE.md`](house-style/EXAMPLE.md) into the repo it describes as **`.claude/occam-house-style.md`** and fill it in. That's the recommended home: it travels with the code, stays private if the repo is private, and Occam loads it automatically. (Maintaining your own fork? You can instead bundle styles as `house-style/<repo-basename>.md`, matched by repo-root basename.) With no house style, Occam falls back to convention-agnostic lenses.

The house style deliberately does **not** duplicate rules your tooling already enforces (`.cursor/rules/*.mdc`, `CLAUDE.md`, lint configs) — Occam reads those directly. It captures only the over-engineering layer they miss.

## Install

```sh
claude plugin marketplace add Jan-ARN/occam
claude plugin install occam@occam
```

Then `/occam` is available in every project.

## Configuration

| Knob | Default | What it does |
|---|---|---|
| `OCCAM_DIFF_THRESHOLD` | `150` | Changed-line count past which the Stop hook nudges you to run `/occam`. |
| `.claude/occam-house-style.md` | — | Per-repo house style (over-engineering rules). |
| `.claude/occam-learnings.md` | auto | Per-repo calibration ledger; created and maintained by Occam. |

Want the house style and learnings to stay on your machine only? Add them to `.git/info/exclude` (a local-only ignore that's never pushed) — Occam still reads them off disk.

## Layout

```
.claude-plugin/plugin.json        plugin manifest
.claude-plugin/marketplace.json   single-plugin marketplace
skills/occam/SKILL.md             the engine
hooks/hooks.json                  Stop-hook registration
hooks/occam-nudge.sh              the big-diff nudge
house-style/EXAMPLE.md            template for a per-repo house style
```

## Roadmap

- A miner that proposes house-style rules from merged-PR review comments — learning team patterns from history, not just from the current author's runs.
- Extract the engine into a standalone CLI for non-Claude-Code use.

## License

MIT
