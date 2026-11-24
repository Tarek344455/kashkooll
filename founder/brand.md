# Brand Design: Kashkool (كشكول)

**Brand Promise**: "Kashkool runs your center while you sleep."

---

## 1. Name & Meaning

| Language | Form | Meaning |
|----------|------|---------|
| **Arabic (Egyptian)** | كشكول | "كشكول" = notebook/binder (what every student carries). Also: "كشك" (kiosk/booth) + "كول" (all/everything) = "everything in one booth" |
| **English** | Kashkool | Phonetic, memorable, owns the .com/.eg |
| **Tagline (AR)** | كشكول.. يدير سنترك وانت نايم | "Kashkool.. runs your center while you sleep" |
| **Tagline (EN)** | Kashkool runs your center while you sleep | Same promise |

---

## 2. Visual Identity: Cosmic Space Glass (The "Space Glass" System)

**Already built in code** — this is the *production* design system, not a concept.

| Component | Spec | Usage |
|-----------|------|-------|
| **CosmicScaffold** | 3D nebula background (WebGL shaders), parallax on scroll/tilt | All screens — the "canvas" |
| **FloatingGlassCard** | `BackdropFilter` 24px blur, 1px neon border (rgba 255,255,255,0.15), 16px radius, 8px elevation | Every card, modal, bottom sheet |
| **NeonButton** | Gradient fill (primary: #00F5FF → #7B2FFF), glow animation on press, haptic feedback | Primary CTAs: "Settle Now", "Check In", "Top Up" |
| **CosmicText** | Gradient text (same neon gradient), subtle glow | Headlines, key numbers (revenue, students) |
| **OrbitLoader** | 3 rotating rings (neon colors), replaces circular progress | All loading states |
| **StardustParticles** | Subtle particle field on background, responds to touch | CosmicScaffold only |

**Color Palette (Production Values)**:
```dart
// Primary Neon
static const Color neonCyan = Color(0xFF00F5FF);
static const Color neonPurple = Color(0xFF7B2FFF);
static const Color neonPink = Color(0xFFFF2D95);

// Glass Surfaces
static const Color glassWhite = Color(0x1AFFFFFF);      // 10% opacity
static const Color glassBorder = Color(0x26FFFFFF);    // 15% opacity
static const Color glassDark = Color(0x1A000000);      // 10% black

// Nebula Background (CSS gradients for web, shaders for mobile)
static const List<Color> nebulaStops = [
  Color(0xFF0A0A2E),  // Deep space
  Color(0xFF1A1A4E),  // Purple haze
  Color(0xFF0F0F3E),  // Midnight
];
```

**Typography**:
- **Arabic**: `Cairo` (Variable: 300-700) — geometric, readable at small sizes, Egyptian feel
- **English/Numbers**: `Space Grotesk` (Variable: 300-700) — technical, matches neon aesthetic
- **Monospace**: `JetBrains Mono` — settlement numbers, codes, NFC IDs

---

## 3. Voice & Tone (Egyptian Arabic First)

| Context | Voice | Example |
|---------|-------|---------|
| **Marketing (Ads, Landing)** | Confident, slightly playful, Egyptian slang | "كشكول يدير سنترك وانت نايم. التسوية بضغطة، الكاش مفيش تسريب، والأهالي مبسوطين." |
| **Product UI** | Clear, directive, zero fluff | "اضغط تسوية" / "الطالب حضر" / "الفلوس في المحفظة" |
| **Onboarding** | Warm, step-by-step, reassuring | "أهلاً بيك في كشكول! هنجهز كل حاجة في 10 دقايق. ابدأ من هنا 👇" |
| **Support** | Respectful, fast, ownership | "أيوة يا فندم، المشكلة دي اتحلت. خليني أتابع معاك بكره الصبح أتأكد." |
| **Error States** | Honest, actionable, not robotic | "النت قطع، بس كشكول شغال أوفلاين. الحضور اتسجل، وهيتسويلك أول ما النت يرجع." |

**Forbidden Words**: "مستخدم" (user) → say "صاحب المركز" / "المدرس" / "السكرتيرة" / "الطالب" / "ولي الأمر"
**Forbidden Tone**: Corporate, apologetic, passive, English-heavy without need.

---

## 4. Logo System

| Variant | Usage | Spec |
|---------|-------|------|
| **Primary (Full)** | App icon, landing hero, signage | "كشكول" in Cairo Bold + neon cyan gradient, dot above "ك" = NFC pulse animation |
| **Symbol Only** | Favicon, notification icon, watermark | The "ك" with pulsing neon ring (4px stroke, 2s loop) |
| **Wordmark Horizontal** | Email signature, partner decks | "كشكول" + "Autonomous EdTech OS" in Space Grotesk |
| **Monochrome** | Print (thermal receipts), fax, single-color | Solid #1A1A2E or white on dark |

**Animation**: The dot above "ك" pulses like a heartbeat (1.2s ease-in-out) — represents *live center*.

---

## 5. Photography & Illustration Style

| Asset Type | Style | Examples |
|------------|-------|----------|
| **Center Photography** | Real Egyptian centers (not stock), warm lighting, messy desks = authenticity | Secretary at desk with NFC reader, teacher checking phone, students tapping tags |
| **UI Screenshots** | Actual app screens (Space Glass), annotated with neon callouts | Settlement screen with "1 tap" arrow, heatmap with "live" pulse |
| **Illustrations** | Minimal line art + neon accent, Egyptian cultural cues | Felucca on Nile with neon sail, pyramid with neon capstone, koshary bowl with neon steam |
| **No Stock Photos** | Ever. If we don't have the photo, we use the UI or illustration. | |

---

## 6. Motion & Micro-interactions

| Interaction | Spec | Purpose |
|-------------|------|---------|
| **NFC Tap Success** | Green ripple (300ms) + haptic + thermal print sound | Instant confirmation, dopamine |
| **Settlement Tap** | Neon cyan → purple gradient sweep (500ms) + "تمت التسوية" toast | Ceremony for the 11 PM moment |
| **Wallet Top-Up** | Coin burst animation (Instapay/Fawry/Vodafone logo) | Visual proof of digital payment |
| **Offline → Online Sync** | Stardust particles flow upward from card → cloud icon | Makes invisible visible |
| **Heatmap Pulse** | Governorates breathe (scale 1.0 → 1.05) on real-time data | Live feeling |

---

## 7. Brand Applications (Production Ready)

| Touchpoint | Status | Spec |
|------------|--------|------|
| **Mobile App (iOS/Android/Windows)** | ✅ Built | Space Glass system, RTL perfect, Arabic first |
| **Admin Web Dashboard** | ✅ Built | Same system, responsive, dark-only |
| **Thermal Receipt** | ✅ Built | 58mm, monochrome logo, Arabic, settlement summary |
| **NFC Tag Sticker** | ✅ Designed | 30mm round, logo + "اضغط هنا" + neon ring print |
| **Printer Config Card** | ✅ Designed | Credit card size, QR to setup video, support WhatsApp |
| **Welcome Box** | 📦 Designed | Matte black box, neon cyan tissue, NFC tags (50), config card, thank you note |
| **Landing Page** | 🌐 V1 done, V2 with case studies | Next.js, Space Glass web port, Arabic first |
| **Pitch Deck** | 📊 Template done | Figma, Space Glass slides, auto-updates from Notion |
| **Email Templates** | 📧 7 sequences coded | MJML, Space Glass buttons, RTL support |
| **WhatsApp Business Templates** | 💬 12 approved | Meta-approved, variable injection, Arabic |

---

## 8. Competitive Differentiation (Visual)

| Competitor | Visual Language | Kashkool Wins On |
|------------|-----------------|------------------|
| EduMe | Corporate blue, dense tables, desktop-first | **Space Glass = premium, mobile-first, Egyptian** |
| SchoolPlus | Medical white, complex menus, dated | **Neon glow = modern, simple, trust-building** |
| Madrasti | Academic green, content-heavy, cluttered | **Focus = operations only, not LMS** |
| Classera | Enterprise gray, government aesthetic | **Consumer-grade delight, not procurement-grade** |
| WhatsApp/Excel | No brand | **We *are* the brand for center ops** |

---

## 9. Brand Guidelines (The "No" List)

- ❌ No stock photos of students in uniforms (looks like government portal)
- ❌ No blue/white corporate palette (looks like bank)
- ❌ No English-only UI (Egyptian market = Arabic first)
- ❌ No "dashboard" language — say "شاشة المتابعة" / "الرادار" / "التسوية"
- ❌ No generic "features" page — every feature has a *moment* (11 PM settlement, 7 AM check-in)
- ❌ No fake urgency (countdown timers without real constraint)
- ❌ No "AI-powered" badges unless it's the *actual* AI router (Port 4500) doing work

---

## 10. Brand Measurement (Monthly)

| Metric | Target | Tool |
|--------|--------|------|
| **Unaided recall** ("ما أول نظام يخطر ببالك لإدارة السناتر؟") | >15% in 6th October | Survey |
| **NPS (pilot centers)** | >50 | In-app prompt |
| **Trial signup → brand search** ("كشكول" on Google/App Store) | >30% | Analytics |
| **Thermal receipt photo shares** (organic) | >5/month | Social listening |
| **Teacher app "share" taps** | >20% of teachers | Mixpanel |