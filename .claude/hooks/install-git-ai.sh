#!/bin/bash
# Installs git-ai (AI code attribution) in Claude Code on the web sessions.
# https://usegitai.com/docs/agents/claude-web
#
# Hardened against the vendor snippet: the installer is fetched from a pinned
# GitHub release and its SHA-256 is checked before it runs. That release build
# of install.sh pins the same version and verifies the binary's checksum.
# To upgrade, bump both values below from the release's SHA256SUMS file.
set -euo pipefail

# Only run in remote (Claude Code on the web) environments
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

GIT_AI_VERSION="v1.7.5"
GIT_AI_INSTALLER_SHA256="11ece07a73940f1c069543896b58265a8374e4595878176ca987117dc5f85cc3"

if ! command -v git-ai &> /dev/null && [ ! -x "$HOME/.git-ai/bin/git-ai" ]; then
  installer="$(mktemp)"
  trap 'rm -f "$installer"' EXIT
  curl -fsSL -o "$installer" \
    "https://github.com/git-ai-project/git-ai/releases/download/${GIT_AI_VERSION}/install.sh"
  if command -v sha256sum &> /dev/null; then
    actual="$(sha256sum "$installer" | awk '{print $1}')"
  else
    actual="$(shasum -a 256 "$installer" | awk '{print $1}')"
  fi
  if [ "$actual" != "$GIT_AI_INSTALLER_SHA256" ]; then
    echo "git-ai: installer checksum mismatch (expected ${GIT_AI_INSTALLER_SHA256}, got ${actual}); not installing" >&2
    exit 1
  fi
  bash "$installer"
fi

# Ensure git-ai is on the PATH for the session
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"\$HOME/.git-ai/bin:\$HOME/.local/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi
