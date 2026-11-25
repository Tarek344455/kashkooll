# Kashkool — كشكول

Smart Egyptian Educational Center & Study Management Platform built with **React + TypeScript + Vite + Tailwind CSS** and an **Express (`server.ts`)** backend.

## Core Capabilities
- **Bilingual RTL/LTR Workspace**: Instant switching between Arabic (RTL) and English (LTR) with Cairo, Plus Jakarta Sans, and JetBrains Mono typography.
- **Role-Based Workspaces**:
  - **Student**: Dynamic 30-second HMAC QR attendance pass, static activation card, 15-minute study rescue knapsack planner, Streak Shield, protected video lectures (360p data-saver / 720p), active-recall flashcards, adaptive practice quizzes, and multi-turn Study Helper with problem photo support.
  - **Secretary**: Rush-hour attendance desk with Erlang-C wait SLA estimates, camera & photo QR attendance scanner (`getUserMedia` + `BarcodeDetector`), session gate verifier, walk-in registration, flexible cash/installment/booklet/discount desk ledger, drawer reconciliation, thermal shift receipts, and parent follow-up notices.
  - **Teacher**: Live attendance analytics dashboard (7d/14d/30d Area & Stacked Bar SVG charts), Operations Research hall capacity rebalancer, break-even & net payout calculator with live center split / assistant wages controls, immutable ledger verification, payment receipt approval queue, payment channels & center subscription plans, and 90-minute lesson pacing builder.
  - **Parent**: Instant reassurance check, dignity balance alerts, WhatsApp shareable encouragement & family reports, calm weekly digest, and attendance log.

## Scripts
- `npm run dev` — Run Express + Vite development server on port `3000`
- `npm run build` — Build frontend bundle into `dist/`
- `npm run start` — Serve production build via `server.ts`
- `npm run lint` — Type-check with `tsc --noEmit`
