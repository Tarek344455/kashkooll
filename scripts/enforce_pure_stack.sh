#!/usr/bin/env bash
set -euo pipefail

echo "=== Kashkool Pure Stack & Client Integrity Guard ==="

# 1. Verify read-only kashkool-ai-client SHA-256 checksums
if [[ ! -f CLIENT_INTEGRITY_HASHES.txt ]]; then
  echo "FAIL: CLIENT_INTEGRITY_HASHES.txt is missing!"
  exit 1
fi
sha256sum -c CLIENT_INTEGRITY_HASHES.txt >/dev/null
echo "PASS: packages/kashkool-ai-client integrity checksums verified."

# 2. Scan active runtime files for any banned Gemini or Firebase remnants
BANNED_REGEX='(@google/genai|google_generative_ai|generativelanguage\.googleapis\.com|GEMINI_API_KEY|gemini-[0-9]|firebase|firestore|google-services\.json|GoogleService-Info\.plist|MAJOR_CAPABILITY_SERVER_SIDE_GEMINI_API)'

SCAN_TARGETS=(
  "src"
  "server"
  "server.ts"
  "package.json"
  "metadata.json"
  ".env.example"
  "index.html"
)

FOUND=0
for target in "${SCAN_TARGETS[@]}"; do
  if [[ -e "$target" ]]; then
    if grep -rnEi "$BANNED_REGEX" "$target"; then
      FOUND=1
    fi
  fi
done

if [[ "$FOUND" -ne 0 ]]; then
  echo "FAIL: Banned Gemini or Firebase dependency/reference detected!"
  exit 1
fi

echo "PASS: 0 Gemini and 0 Firebase references in runtime stack."
