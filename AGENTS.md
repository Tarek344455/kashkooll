# KASHKOOL (`kashkool_app`) ARCHITECTURAL CONSTITUTION & STACK LOCK

## Stack Purity Laws
1. **Exclusive Stack (`kashkool-ai-client` + Supabase)**:
   - All AI capabilities route exclusively through `kashkool-ai-client` (`packages/kashkool-ai-client`, mirrored on the Node backend via `server/kashkoolAiRouter.ts` and optional Supabase Edge `smart-router`).
   - All cloud persistence, auth, real-time sync, and receipt storage run exclusively through **Supabase** (`@supabase/supabase-js`).
2. **Explicit Read-Only Lock on `packages/kashkool-ai-client`**:
   - The original extracted `kashkool-ai-client` package under `packages/kashkool-ai-client/` is strictly **READ-ONLY**.
   - Never modify, refactor, or alter files inside `packages/kashkool-ai-client/` unless Tarek explicitly authorizes a specific edit to it in the active prompt.
   - Integrity is verified continuously via `sha256sum -c CLIENT_INTEGRITY_HASHES.txt`.
3. **Zero-Gemini & Zero-Firebase Prohibition**:
   - Banned packages, keys, URLs, and SDKs: `@google/genai`, `google_generative_ai`, `generativelanguage.googleapis.com`, `GEMINI_API_KEY`, `firebase`, `firestore`, `firebase_core`, `firebase_auth`, `cloud_functions`, `google-services`.
   - Enforce before every build/commit using `bash scripts/enforce_pure_stack.sh`.
