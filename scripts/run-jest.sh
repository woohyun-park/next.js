#!/usr/bin/env bash
#
# Set up environment variables for a Next.js jest test run and exec jest
# in a single hop, replacing this shell process.
#
# Usage:
#   scripts/run-jest.sh \
#     [--mode=<dev|start|deploy>] \
#     [--bundler=<webpack|turbo|rspack>] \
#     [--experimental] \
#     [--headless] \
#     -- [jest args...]
#
# All arguments after `--` are forwarded verbatim to jest.

set -eo pipefail

while [ $# -gt 0 ]; do
  case "$1" in
    --mode=dev|--mode=start|--mode=deploy)
      export NEXT_TEST_MODE="${1#--mode=}"
      ;;
    --mode=*)
      echo "run-jest.sh: unknown mode: ${1#--mode=}" >&2
      exit 1
      ;;
    --bundler=webpack)
      export IS_WEBPACK_TEST=1
      ;;
    --bundler=turbo)
      export IS_TURBOPACK_TEST=1
      ;;
    --bundler=rspack)
      export NEXT_RSPACK=1
      export NEXT_TEST_USE_RSPACK=1
      ;;
    --bundler=*)
      echo "run-jest.sh: unknown bundler: ${1#--bundler=}" >&2
      exit 1
      ;;
    --experimental)
      export __NEXT_CACHE_COMPONENTS=true
      ;;
    --headless)
      export HEADLESS=true
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "run-jest.sh: unknown argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

# `__NEXT_TEST_VARIANT` names the *variant* run of the test matrix: CI runs the
# suites twice, once plain and once with this set, and a fixture uses it to
# cover both states of an experiment. Key the flag so it is *enabled* by
# default and disabled in the variant run:
#
#   experimental: {
#     useOffline: process.env.__NEXT_TEST_VARIANT !== 'true',
#   }
#
# paired with a `// @gate useOffline` on the suite: a plain run — including a
# local run with no special env — exercises the feature, and the variant run
# asserts it is inert when disabled (see test/lib/gate/README.md).
#
# For now the variant run is an alias for `__NEXT_CACHE_COMPONENTS` (the
# `--experimental` shard) rather than a CI dimension of its own. That works
# because most experiments hard-code `cacheComponents: true` in their fixture
# anyway — the shard's cache-components default only applies to fixtures that
# don't set it themselves, so for these fixtures the shard is free to double as
# the variant run. Setting either name implies the other.
if [ "${__NEXT_TEST_VARIANT:-}" = "true" ]; then
  export __NEXT_CACHE_COMPONENTS=true
elif [ "${__NEXT_CACHE_COMPONENTS:-}" = "true" ]; then
  export __NEXT_TEST_VARIANT=true
fi

# Resolves to `node_modules/.bin/jest` via `$PATH`. This relies on being
# invoked through pnpm (or another package runner), which prepends the
# workspace's `node_modules/.bin/` to `$PATH` before running the script.
exec jest --runInBand "$@"
