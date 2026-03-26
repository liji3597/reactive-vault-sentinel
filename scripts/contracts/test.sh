#!/usr/bin/env bash
set -euo pipefail

FORGE_BIN="$(command -v forge || true)"

if [ -z "${FORGE_BIN}" ] && [ -x "${HOME}/.foundry/bin/forge" ]; then
  FORGE_BIN="${HOME}/.foundry/bin/forge"
fi

if [ -z "${FORGE_BIN}" ] && [ -n "${USERPROFILE:-}" ] && [ -x "${USERPROFILE}/.foundry/bin/forge.exe" ]; then
  FORGE_BIN="${USERPROFILE}/.foundry/bin/forge.exe"
fi

if [ -z "${FORGE_BIN}" ]; then
  echo "Missing forge binary in PATH and fallback locations"
  exit 1
fi

"${FORGE_BIN}" test --root contracts "$@"
