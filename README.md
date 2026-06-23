# occam

A Claude Code plugin that reviews a diff for **AI slop and over-engineering** — single-use abstractions, reinvented helpers, scope creep, premature generality, dead weight, and non-idiomatic code — and returns a short, ranked, low-noise list of cuts with concrete simpler rewrites.

Named for Occam's razor: don't multiply entities beyond necessity.

## Why

AI writes too much, too fast. PRs balloon, reviewing them is exhausting, and a single generic review pass misses the over-engineering and doesn't know your team's patterns. Occam is built for exactly that failure mode.

## How it works

1. **Fan out** one focused review pass per slop category (parallel subagents) — high recall, each pass has one narrow job.
2. **Adversarially verify** every candidate — a skeptic tries to *justify* each finding; anything defensible (or a pre-existing convention, or a real bug rather than slop) is dropped. This is what keeps the output trustworthy.
3. **Rank** the survivors into a short list with a concrete simpler rewrite each, written to `.tasks/occam-*.md` in the repo under review.

Two modes:

- `/occam` — **author-time**, reviews your uncommitted working-tree diff before you commit; can auto-apply approved cuts.
- `/occam pr` — **review-time**, reviews the branch vs the base branch; read-only, can post PR comments.

A `Stop` hook nudges you to run `/occam` when your uncommitted diff grows past `OCCAM_DIFF_THRESHOLD` changed lines (default 150). It never blocks.

## Install

```sh
claude plugin marketplace add <git-url-of-this-repo>
claude plugin install occam@occam
```

Then `/occam` is available in every project.

## House styles

The slop lenses are generic; the per-repo "we don't do X here" knowledge lives in a house style — its known non-idiomatic offenders, reuse surfaces, scope rules, and operational notes (base branch, formatter, version-bump rule). Copy [`house-style/EXAMPLE.md`](house-style/EXAMPLE.md) and fill it in.

The recommended place is a repo-local **`.claude/occam-house-style.md`** inside the repo it describes — it stays with the code (and private, if that repo is private), and Occam picks it up automatically. Alternatively, if you maintain your own fork of this plugin, bundle styles as `house-style/<repo-basename>.md` and Occam matches by repo-root basename. With neither, Occam falls back to convention-agnostic lenses.

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

- v1: a miner that proposes new house-style rules from merged-PR review comments, so it learns team patterns instead of being hand-fed.
- Later: extract the engine into a standalone CLI for non-Claude-Code use.
