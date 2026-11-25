# PURGE & INTEGRATION MANIFEST — `kashkool_app`

## 1. Environment Reality Note
- Active Workspace: `/app/applet` (React + TypeScript + Vite + Express `server.ts` web port of `Tarek344455/kashkooll`).
- Native Flutter/Android SDK: Not present in this container (`NO_FLUTTER`), so build/purity checks run via TypeScript (`npm run lint`), Vite (`npm run build`), Node tests (`npx --yes tsx --test`), and `scripts/enforce_pure_stack.sh`.

## 2. Firebase Scan Result
- **0 Firebase references** found across `src/`, `server.ts`, `package.json`, `metadata.json`, `index.html`, and `.env.example`.

## 3. Purged Gemini References
| File | Removed Artifact | Replacement |
|---|---|---|
| `package.json` | `"@google/genai": "^3.6.1"` (uninstalled 39 transitive packages) | `@supabase/supabase-js` + keyless `kashkool-ai-client` |
| `server.ts` | `import { GoogleGenAI, Type } from "@google/genai"`, `MODEL = "gemini-4-hydrogen"`, `GEMINI_API_KEY` / `API_KEY`, `aistudio-build` User-Agent | `server/kashkoolAiRouter.ts` (`KashkoolAiClient/1.0`, Kilo/llm7/Pollinations keyless + optional OpenRouter/NVIDIA/OpenCode/Local Gemma) |
| `metadata.json` | `"MAJOR_CAPABILITY_SERVER_SIDE_GEMINI_API"` | `[]` |
| `.env.example` | `GEMINI_API_KEY=` | `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, optional keyed provider vars |

## 4. Protected Read-Only `kashkool-ai-client` Module
- Extracted directly from `Tarek344455/kashkooll` (`a4218c4` -> `kashkool-ai-client.rar`).
- Preserved verbatim under `packages/kashkool-ai-client/` (24 source/build/doc files).
- SHA-256 checksums locked in `CLIENT_INTEGRITY_HASHES.txt` and verified on every run of `scripts/enforce_pure_stack.sh`.
