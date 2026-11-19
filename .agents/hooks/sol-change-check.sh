#!/usr/bin/env bash
# Runs when an agent stops: keeps changed Solidity formatted, contracts/
# compiling and the hermetic unit tests passing. Fork tests need RPC URLs
# from .env, which agents cannot read, so they are left to pre-commit.
set -u

input=$(cat)
[ "$(jq -r '.stop_hook_active' <<<"$input")" = "true" ] && exit 0

cd "$(git rev-parse --show-toplevel)" || exit 0
[ -z "$(git status --porcelain -- '*.sol')" ] && exit 0

just fmt >/dev/null 2>&1

if ! out=$(just build 2>&1); then
    { echo "just build failed:"; tail -n 60 <<<"$out"; } >&2
    exit 2
fi

if ! out=$(just test-unit 2>&1); then
    { echo "just test-unit failed:"; tail -n 60 <<<"$out"; } >&2
    exit 2
fi
