#!/usr/bin/env bash
# occam-nudge — author-time slop guard.
# When Claude stops, if the uncommitted diff has grown large, nudge to run
# /occam before committing, so over-engineering gets caught while the change
# is still small. Never blocks; always exits 0. Safe in any repo (no-ops
# outside a git work tree or below the threshold).

THRESHOLD="${OCCAM_DIFF_THRESHOLD:-150}"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

changed=$(git diff HEAD --numstat 2>/dev/null \
    | grep -vE '(package-lock\.json|yarn\.lock|\.snap$)' \
    | awk '{ a += $1; d += $2 } END { print a + d + 0 }')
changed="${changed:-0}"

if [ "$changed" -lt "$THRESHOLD" ] 2>/dev/null; then
    exit 0
fi

printf '{"systemMessage": "occam — uncommitted diff is %s changed lines (threshold %s). Consider running /occam before committing to catch slop and over-engineering while the change is still small."}\n' "$changed" "$THRESHOLD"
exit 0
