#!/usr/bin/env bash
# muster-read-test-patterns.sh — shared parser: per-platform test-file and test-function patterns (family: read — one table, many consumers).
#
# muster-lint-test-delta.sh (tests added/removed in a range) and the PM write-lane lint (assertion
# lines a PM commit may not touch) each need "what does a test look like on this platform". One
# table here, so a new platform is added once and an unknown platform is a no-op for every consumer.
#
# Sourced: defines  platform_of <path>   -> swift|kotlin|ts|python|go|'' (by extension)
#                   is_test_file <path>  -> 0 when the path is a test file by location or name
#                   test_fn_regex <plat> -> ERE matching a test-function/case declaration line
#                   assert_regex <plat>  -> ERE matching an assertion line
#                   PLATFORMS            -> the space-separated list above
# Executed: prints the table.
set -uo pipefail

PLATFORMS="swift kotlin ts python go"

platform_of(){ # $1=path
  case "$1" in
    *.swift) printf 'swift' ;;
    *.kt|*.kts) printf 'kotlin' ;;
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) printf 'ts' ;;
    *.py) printf 'python' ;;
    *.go) printf 'go' ;;
    *) printf '' ;;
  esac
}

is_test_file(){ # $1=path — location (a tests dir) or name (test suffix/prefix)
  case "$1" in
    */__tests__/*|*/test/*|*/tests/*|*/spec/*|*Tests/*|*Test/*) return 0 ;;
  esac
  local b; b="$(basename "$1")"
  case "$b" in
    *_test.*|*.test.*|*.spec.*|test_*|*Tests.swift|*Test.swift|*Tests.kt|*Test.kt) return 0 ;;
  esac
  return 1
}

test_fn_regex(){ # $1=platform — a line (diff prefix already stripped) that declares one test
  case "$1" in
    swift)  printf '%s' '^[[:space:]]*(@Test([[:space:](]|$)|func[[:space:]]+test[A-Za-z0-9_])' ;;
    kotlin) printf '%s' '^[[:space:]]*@Test([[:space:](]|$)' ;;
    ts)     printf '%s' '^[[:space:]]*(it|test)(\.(only|skip|each|concurrent))?[[:space:]]*\(' ;;
    python) printf '%s' '^[[:space:]]*(async[[:space:]]+)?def[[:space:]]+test_' ;;
    go)     printf '%s' '^func[[:space:]]+Test[A-Z0-9_]' ;;
    *)      printf '' ;;
  esac
}

assert_regex(){ # $1=platform — a line that asserts (the body a PM commit may not change)
  case "$1" in
    swift)  printf '%s' '(XCTAssert|XCTFail|#expect|#require)' ;;
    kotlin) printf '%s' '(assert[A-Z][A-Za-z]*\(|assertThat\(|\.shouldBe)' ;;
    ts)     printf '%s' '(expect\(|assert\.|assert\()' ;;
    python) printf '%s' '(^[[:space:]]*assert[[:space:]]|self\.assert[A-Z])' ;;
    go)     printf '%s' '(t\.(Error|Errorf|Fatal|Fatalf|Fail)\(|assert\.|require\.)' ;;
    *)      printf '' ;;
  esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  printf '%-8s %-60s %s\n' platform test-function assertion
  for p in $PLATFORMS; do printf '%-8s %-60s %s\n' "$p" "$(test_fn_regex "$p")" "$(assert_regex "$p")"; done
fi
