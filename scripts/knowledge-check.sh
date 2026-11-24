#!/usr/bin/env bash
# Run Savior Knowledge Base checks on the Kashkool monorepo

set -euo pipefail

KNOWLEDGE_ROOT="${KNOWLEDGE_ROOT:-$HOME/.config/opencode/kashkool-savior/knowledge}"
SAVIOR_CLI="$HOME/.config/opencode/kashkool-savior/cli/knowledge.mjs"
CHANGED_FILES=("$@")

echo "=== Kashkool Savior Knowledge Gate ==="
echo "Knowledge Root: $KNOWLEDGE_ROOT"

# Verify Savior Engine exists
if [[ ! -f "$SAVIOR_CLI" ]]; then
    echo "❌ Savior Engine CLI not found at $SAVIOR_CLI"
    echo "Run: git clone https://github.com/kashkool/savior-engine.git $HOME/.config/opencode/kashkool-savior"
    exit 1
fi

# Build args
ARGS=("check:project")
if [[ ${#CHANGED_FILES[@]} -gt 0 ]]; then
    ARGS+=("--changed")
    ARGS+=("${CHANGED_FILES[@]}")
done

echo "Running: node $SAVIOR_CLI ${ARGS[*]}"
echo ""

# Execute
node "$SAVIOR_CLI" "${ARGS[@]}"
EXIT_CODE=$?

echo ""
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "✅ Knowledge Gate: PASSED"
elif [[ $EXIT_CODE -eq 1 ]]; then
    echo "⚠️  Knowledge Gate: REQUIRES HUMAN REVIEW (high severity)"
else
    echo "❌ Knowledge Gate: BLOCKED (critical severity)"
fi

exit $EXIT_CODE