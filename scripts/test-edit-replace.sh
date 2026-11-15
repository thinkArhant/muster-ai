#!/usr/bin/env bash
# test-edit-replace.sh — fixture gate for muster-edit-replace.sh (exactly-one-match replacement, dry run by default).
# Asserts: dry run writes nothing; --check is silent on success; --apply writes once; zero and multiple
# matches are refused with nothing written; a heading matches only at column 0 outside fences and
# blockquotes; the section body stops at the next same-or-higher heading; a no-op is refused; usage exits 3.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
R="$HERE/muster-edit-replace.sh"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0
ok(){ echo "PASS: $1"; pass=$((pass+1)); }; ko(){ echo "FAIL: $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/  got: /'; fail=$((fail+1)); }
F="$T/f.md"
seed(){ cat > "$F" <<'EOF'
# Packet

## Numbers
| S1 | sets per exercise | PROPOSED |
| S2 | rest between sets | PROPOSED |

> ## Verdict
> quoted heading, not a section

## Verdict
old verdict line

```
## Verdict
fenced heading, not a section
```

### Sub
sub body

## Tail
tail body
EOF
}

seed; before="$(cat "$F")"
out="$(bash "$R" --file "$F" --text "| S1 | sets per exercise | PROPOSED |" --to "| S1 | sets per exercise | RATIFIED |" 2>&1)"; rc=$?
[ "$rc" = 0 ] && grep -qF "DRY RUN" <<<"$out" && [ "$(cat "$F")" = "$before" ] && ok "dry run prints diff, writes nothing" || ko "dry run" "$out"
grep -qF -- "-| S1 | sets per exercise | PROPOSED |" <<<"$out" && grep -qF -- "+| S1 | sets per exercise | RATIFIED |" <<<"$out" && ok "dry run shows the diff" || ko "dry diff" "$out"

out="$(bash "$R" --file "$F" --text "| S1 | sets per exercise | PROPOSED |" --to "| S1 | sets per exercise | RATIFIED |" --check 2>&1)"; rc=$?
[ "$rc" = 0 ] && [ -z "$out" ] && ok "--check is silent on a unique match" || ko "--check silent" "$out"

out="$(bash "$R" --file "$F" --text "PROPOSED" --to "RATIFIED" --check 2>&1)"; rc=$?
[ "$rc" = 1 ] && grep -qF "matches 2 time(s)" <<<"$out" && [ "$(cat "$F")" = "$before" ] && ok "two matches refused, nothing written" || ko "two matches" "$out"

out="$(bash "$R" --file "$F" --text "nowhere" --to "x" --apply 2>&1)"; rc=$?
[ "$rc" = 1 ] && grep -qF "matches 0 time(s)" <<<"$out" && ok "zero matches refused" || ko "zero matches" "$out"

out="$(bash "$R" --file "$F" --text "| S1 | sets per exercise | PROPOSED |" --to "| S1 | sets per exercise | RATIFIED |" --apply 2>&1)"; rc=$?
[ "$rc" = 0 ] && grep -qF "APPLIED" <<<"$out" && grep -qF "| S1 | sets per exercise | RATIFIED |" "$F" && grep -qF "| S2 | rest between sets | PROPOSED |" "$F" && ok "--apply writes exactly the one match" || ko "apply" "$out"

out="$(bash "$R" --file "$F" --text "| S1 | sets per exercise | RATIFIED |" --to "| S1 | sets per exercise | RATIFIED |" --apply 2>&1)"; rc=$?
[ "$rc" = 1 ] && grep -qF "no-op" <<<"$out" && ok "no-op replacement refused" || ko "no-op" "$out"

# section mode: the real "## Verdict" is the only hit — the blockquote and fenced copies are ignored
seed; printf 'S1 — RATIFY\nS2 — AMEND 3\n' > "$T/body.md"
out="$(bash "$R" --file "$F" --section "## Verdict" --with "$T/body.md" --apply 2>&1)"; rc=$?
[ "$rc" = 0 ] && grep -qF "S2 — AMEND 3" "$F" && ! grep -qF "old verdict line" "$F" && ok "section body replaced" || ko "section replace" "$out"
grep -qF "> quoted heading, not a section" "$F" && ok "blockquote look-alike (in another section) untouched" || ko "quote untouched" "$(cat "$F")"
! grep -qF "fenced heading, not a section" "$F" && ! grep -qF "### Sub" "$F" && ok "fenced copy and lower-level subsection were inside the body and went with it" || ko "body extent" "$(cat "$F")"
grep -qF "## Tail" "$F" && grep -qF "tail body" "$F" && ok "next same-level section kept" || ko "tail kept" "$(cat "$F")"

seed
out="$(bash "$R" --file "$F" --section "## Nope" --with "$T/body.md" --check 2>&1)"; rc=$?
[ "$rc" = 1 ] && grep -qF "found 0 time(s)" <<<"$out" && ok "missing heading refused" || ko "missing heading" "$out"

out="$(printf 'from stdin\n' | bash "$R" --file "$F" --section "## Tail" --with - --apply 2>&1)"; rc=$?
[ "$rc" = 0 ] && grep -qF "from stdin" "$F" && ! grep -qF "tail body" "$F" && ok "stdin body + last section to EOF" || ko "stdin/EOF" "$out"

out="$(bash "$R" --file "$F" 2>&1)"; rc=$?; [ "$rc" = 3 ] && ok "usage without a mode exits 3" || ko "usage" "$out"
out="$(bash "$R" --file "$T/none.md" --text a --to b 2>&1)"; rc=$?; [ "$rc" = 3 ] && ok "missing file exits 3" || ko "missing file" "$out"

echo "-----------------------------------------------"
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1
