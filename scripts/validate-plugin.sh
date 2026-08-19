#!/usr/bin/env bash
#
# Validates the Claude Code plugin and marketplace manifests.
#
# Run before pushing any change to .claude-plugin/ or skills/. The
# community-marketplace review pipeline runs `claude plugin validate` on every
# submission, so a failure here is a failure there.
#
# Usage: ./scripts/validate-plugin.sh
# Requires: claude (npm i -g @anthropic-ai/claude-code), jq
#
# No credentials needed — validation is entirely local.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

MARKETPLACE=".claude-plugin/marketplace.json"
PLUGIN=".claude-plugin/plugin.json"

for f in "${MARKETPLACE}" "${PLUGIN}"; do
  [ -f "${f}" ] || { echo "✘ missing ${f}"; exit 1; }
done

command -v claude >/dev/null 2>&1 \
  || { echo "✘ claude CLI not found. Install: npm i -g @anthropic-ai/claude-code"; exit 1; }
command -v jq >/dev/null 2>&1 \
  || { echo "✘ jq not found"; exit 1; }

echo "claude $(claude --version)"
echo

# --- 1. Marketplace manifest -------------------------------------------------
# --strict promotes warnings to errors. Worth it: the CLI reports a real defect
# as a mere warning — a marketplace entry whose `version` disagrees with
# plugin.json, where plugin.json silently wins — and that is exactly the kind
# of drift that ships a marketplace advertising a version nobody receives.
echo "==> Marketplace manifest"
claude plugin validate . --strict

# --- 2. Plugin manifest, in isolation ---------------------------------------
# The validator switches to marketplace mode as soon as it sees
# marketplace.json, so validating the repo root never exercises plugin.json's
# own schema. Copy the plugin without the marketplace file to force plugin mode.
echo
echo "==> Plugin manifest (isolated)"
WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT

cp -R .claude-plugin "${WORK}/"
rm -f "${WORK}/.claude-plugin/marketplace.json"
for d in skills commands agents hooks; do
  [ -d "${d}" ] && cp -R "${d}" "${WORK}/"
done
claude plugin validate "${WORK}" --strict

# --- 3. Entry name must match the plugin ------------------------------------
# The CLI does NOT check this: a marketplace entry named something plugin.json
# does not define passes validation cleanly, and only fails later at install
# time with "Plugin <name> not found in marketplace". Verified against
# claude 2.1.235.
echo
echo "==> Entry name matches plugin.json"
PLUGIN_NAME="$(jq -r '.name' "${PLUGIN}")"
MARKETPLACE_NAME="$(jq -r '.name' "${MARKETPLACE}")"

if ! jq -e --arg n "${PLUGIN_NAME}" \
     '[.plugins[].name] | index($n) != null' "${MARKETPLACE}" >/dev/null; then
  echo "✘ ${MARKETPLACE} has no entry named \"${PLUGIN_NAME}\""
  echo "  plugin.json declares:  ${PLUGIN_NAME}"
  echo "  marketplace entries:   $(jq -r '[.plugins[].name] | join(", ")' "${MARKETPLACE}")"
  echo "  Installs would fail with: Plugin \"${PLUGIN_NAME}\" not found in marketplace."
  exit 1
fi
echo "✔ installs as ${PLUGIN_NAME}@${MARKETPLACE_NAME}"

echo
echo "✔ All plugin validation passed"
