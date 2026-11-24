# Launch Plan: Kashkool

**Launch Date**: Day 0 = **January 15, 2027** (after 30-day pilot validation)
**Launch Pack**: EGP 1,990/mo for 6 months + EGP 20K bonuses (50 centers max)

---

## 1. Pre-Launch Timeline (T-30 to T-0)

| Date | Milestone | Owner | Done Criteria |
|------|-----------|-------|---------------|
| **T-30 (Dec 16)** | Pilot kickoff: 10 centers onboarded | Founder + CS | 10 centers live, first settlement successful |
| **T-25 (Dec 21)** | Case study #1 captured (Al-Maadi Center) | Marketing + CS | 2-min video, PDF, owner testimonial recorded |
| **T-20 (Dec 26)** | Landing page V2 live with proof | Marketing + Eng | Case studies, demo videos, Launch Pack countdown |
| **T-15 (Dec 31)** | Paid ads launched (FB/IG + Google) | Marketing | CPL < EGP 200, 50 trial signups |
| **T-10 (Jan 5)** | Referral program active | CS + Marketing | 5 pilot centers referred 2+ each |
| **T-7 (Jan 8)** | Webinar #1: "Autonomous Center Ops" | Founder | 50+ registrants, 30% trial conversion |
| **T-3 (Jan 12)** | Hardware inventory confirmed (50 printers, 10K NFC) | Ops | All in warehouse, labeled, ready to ship |
| **T-1 (Jan 14)** | Launch rehearsal: full onboarding dry-run | All teams | 3 centers onboarded in <15 min each |
| **T-0 (Jan 15)** | **LAUNCH** — Landing page switches to "Live" | Founder | Countdown hits zero, first 5 Launch Pack sales |

---

## 2. Launch Day (T-0) Runbook

| Time | Activity | Owner | Channel |
|------|----------|-------|---------|
| 08:00 | Final smoke test: app, dashboard, payments, NFC | Eng Lead | — |
| 09:00 | Landing page flip: "Coming Soon" → "Live" + countdown | Marketing | Web |
| 09:15 | WhatsApp broadcast to 5K opted-in center owners | Marketing | WhatsApp Business API |
| 09:30 | Facebook/IG ads switch to "Launch Pack" creative | Marketing | Ads Manager |
| 10:00 | Founder posts on LinkedIn + Facebook groups | Founder | Social |
| 10:30 | Email to waitlist: "Launch Pack is live — 50 spots" | Marketing | Email |
| 11:00 | **First Launch Pack sale** — ring the bell (literal Slack bell) | Sales | — |
| 12:00 | Live demo stream (30 min): "Onboarding in 10 min" | Founder + CS | YouTube/Facebook Live |
| 14:00 | Webinar #2: "From WhatsApp to Autonomous in 1 Week" | Founder | Zoom |
| 16:00 | Check: 10+ Launch Pack sales? If not → ad boost | Founder + Marketing | — |
| 18:00 | End-of-day sync: sales, trials, support tickets | All Leads | Slack huddle |
| 20:00 | Founder tweet/LinkedIn: "Day 1: X centers joined" | Founder | Social |

---

## 3. Launch Week (T+1 to T+7)

| Day | Focus | Key Activities | Success Metric |
|-----|-------|----------------|----------------|
| **T+1** | **Momentum** | Process Day 1 sales, ship hardware, capture first-day content | 5+ new sales |
| **T+2** | **Social Proof** | Publish "Day 1: 12 centers joined" post, tag centers (permission) | 100+ shares |
| **T+3** | **Objection Handling** | Release "Offline Demo" video (airplane mode), FAQ update | Trial-to-paid > 20% |
| **T+4** | **Referral Push** | Email pilot centers: "Earn EGP 1,000 per referral" | 10+ referrals |
| **T+5** | **Teacher Angle** | Teacher testimonial video: "I got paid exactly, on time" | Teacher tier signups |
| **T+6** | **Mid-Week Review** | Metrics check: CAC, trial conversion, support volume | Adjust ads if CAC > EGP 10K |
| **T+7** | **Weekly Webinar** | "Live Q&A: Your Center on Kashkool" | 30+ attendees |

---

## 4. Launch Month (T+0 to T+30) — The 50 Center Sprint

| Week | Target | Activities | Gate |
|------|--------|------------|------|
| **Week 1** | 15 centers | Process launch week leads, onboard 3/day, capture case studies | 15 onboarded |
| **Week 2** | 15 centers | Referral program kicks in, ads optimized, webinar #2 | 30 onboarded |
| **Week 3** | 10 centers | Governorate partnership announced, teacher tier push | 40 onboarded |
| **Week 4** | 10 centers | Final push: "Last 10 spots at Launch Pack price" | **50 onboarded** |

**Daily Rhythm**:
- 08:00 — Ops standup: hardware shipments, migrations, onboarding schedule
- 10:00 — Sales standup: pipeline, demos booked, objections
- 14:00 — Support standup: tickets, bugs, escalations
- 18:00 — Founder review: metrics, blockers, decisions

---

## 5. Launch Pack Fulfillment (Per Center)

| Item | When | How | Verification |
|------|------|-----|--------------|
| **NFC Tags (50)** | Day 0 (with welcome box) | Aramex/Barq, tracking shared in WhatsApp group | Secretary confirms count + photo |
| **Thermal Printer** | Day 0 (if ordered) | Same shipment, pre-configured | Test receipt prints on Day 1 |
| **Data Migration** | Day -1 to Day 1 | Engineer runs script, owner validates counts | Owner signs PDF report |
| **Onboarding Call** | Day 1 | CS Agent + Owner + Secretary | 10-min target, recorded |
| **Launch Pack Price Lock** | Immediate | Billing set to EGP 1,990 × 6 months | Stripe/Supabase confirmed |
| **Bonus: Priority Support** | Day 1 | Added to dedicated WhatsApp group | Group invite sent |
| **Bonus: Teacher DRM Setup** | Day 3 | Auto-config when first teacher uploads content | Teacher confirms |

---

## 6. Risk Mitigation (Launch-Specific)

| Risk | Probability | Impact | Mitigation | Owner |
|------|-------------|--------|------------|-------|
| **Payment rails not live** | Medium | High | Sandbox mode for launch, real rails by Week 2, guarantee covers | Eng Lead |
| **Hardware delivery delays** | Low | High | 20% buffer stock, local Cairo pickup option | Logistics |
| **Onboarding bottleneck** | Medium | Medium | Max 50 centers = hard cap, waitlist after | Founder |
| **Major bug on launch day** | Low | Critical | 48-hr freeze before launch, rollback plan, hotfix process | Eng Lead |
| **Negative social media** | Low | Medium | Pre-approved response templates, founder responds personally | Founder |
| **Competitor launches same week** | Low | Low | Differentiation is moat (offline, payments, AI) — ignore | Founder |
| **CAC spikes > EGP 15K** | Medium | High | Pause ads, double down on referrals + organic | Marketing |

---

## 7. Post-Launch (T+30 to T+90)

| Phase | Focus | Target |
|-------|-------|--------|
| **Month 2** | **Optimize** | CAC < EGP 8K, trial-to-paid > 25%, churn < 3% |
| **Month 3** | **Scale** | 100 centers total, referral = 30% of new, teacher tier = 15% revenue |
| **Month 4** | **Expand** | Governorate partnership live, Upper Egypt pilot (10 centers) |

**Launch Pack Sunset**: After 50 centers or 30 days (whichever first) → price reverts to EGP 2,500. No extensions. No exceptions.

---

## 8. Launch Budget (T-30 to T+30)

| Category | Amount | Notes |
|----------|--------|-------|
| **Hardware (NFC + Printers + Boxes)** | EGP 350,000 | 200 centers worth, 50 for launch |
| **Paid Ads (FB/IG/Google)** | EGP 200,000 | 60-day campaign, optimized daily |
| **Content Production** | EGP 50,000 | Videos, case studies, landing page |
| **Referral Bonuses** | EGP 50,000 | 50 centers × EGP 1,000 |
| **Events/Webinars** | EGP 30,000 | Zoom, streaming, promotion |
| **Legal/Compliance** | EGP 50,000 | Payment licenses, terms, contracts |
| **Buffer (10%)** | EGP 73,000 | Unforeseen |
| **Total** | **EGP 803,000** | Funded from startup budget (numbers.json) |

---

## 9. Success Definition (Launch Verdict)

| Metric | Minimum | Target | Stretch |
|--------|---------|--------|---------|
| **Centers Onboarded** | 30 | 50 | 60 |
| **Trial-to-Paid** | 20% | 30% | 40% |
| **CAC** | < EGP 12K | < EGP 8K | < EGP 5K |
| **First Settlement Success** | 95% | 99% | 100% |
| **NPS (Day 30)** | > 40 | > 50 | > 60 |
| **Monthly Churn** | < 5% | < 3% | < 2% |
| **Teacher Tier Adoption** | 5% | 15% | 25% |

**If Minimum Not Met**: Pause marketing spend, fix product/onboarding, extend pilot. Do not scale broken machine.

**If Target Met**: Greenlight Month 2 budget (EGP 300K ads), hire 2nd sales person, plan governorate expansion.

**If Stretch Met**: Series A conversations start immediately.