# Kashkool Board Brief

## The Idea (from founder/idea.md)

**Kashkool (كشكول)** — Autonomous EdTech OS for the Egyptian market

- **What it is**: A unified platform connecting centers, teachers, students, secretaries, and parents with AI-powered automation, offline-first architecture, and immutable financial ledgers.
- **Target customer (buyers)**: Education center owners (مراكز الدروس الخصوصية) and independent teachers/tutors in Egypt. End users (free): Students (K-12, university), parents, center secretaries.
- **Product & Price**: 
  - B2B SaaS for centers: monthly subscription per center (price TBD)
  - B2C SaaS for independent teachers: monthly subscription per teacher (price TBD)
  - Free for students/parents (B2B2C model)
  - Core features: 0.3-second NFC/QR check-in, 1-tap daily settlement, AI academic rescue, family wallet with Instapay/Vodafone Cash/Fawry, DRM-protected content, live Egypt heatmap for super-admin
- **Where & How**: Egypt nationwide (online + offline-first). Mobile app (Flutter: iOS, Android, Windows) + Admin web dashboard. Distribution: direct sales to centers, teacher onboarding, app stores. Delivery: SaaS cloud (Supabase backend) + local Drift database for offline operation.
- **Budget & Constraints**: 
  - Existing codebase: Flutter 3.x, Supabase, Edge Functions, Spaceship AI Router (Port 4500)
  - Team: Technical team in place, building since 2024
  - Regulatory: Egyptian education market, data residency, payment integrations (Instapay, Fawry, Vodafone Cash)
  - Competitive: Local ERPs, generic LMS, WhatsApp-based operations
  - Key differentiator: Autonomous automation (6 engines 24/7), Space Glass UI, offline-first, Egyptian payment rails

## Additional Context for the Board

- The product is **already built and in production-ready state** (v2.5.0 Cosmic Edition) — not a concept.
- Six autonomous automation engines run 24/7: check-in, settlement, academic rescue, family wallet, AI router, admin radar.
- The "Space Glass" UI (CosmicScaffold, FloatingGlassCard, NeonButton) is a unique visual identity.
- Offline-first with local Drift DB is a major technical moat in Egypt where connectivity is unreliable.
- Payment integration with Egyptian rails (Instapay, Fawry, Vodafone Cash) is built-in.
- Super-admin "God-Mode HQ" with live Egypt heatmap, kill-switches, ghost impersonation is a unique control layer.
- Market: Egypt has ~25M students, massive private tutoring market (estimated $2B+ annually), highly fragmented, mostly cash/WhastApp operated.
- The team has deep domain knowledge of Egyptian education operations.