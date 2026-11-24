# Pricing Strategy: Kashkool

## 1. The Price

**EGP 2,500/month per center** (all features included)
**EGP 800/month per independent teacher**

### Why this price?

| Factor | Input | Decision |
|--------|-------|----------|
| **Van Westendorp acceptable range** | EGP 898 – EGP 3,305 | EGP 2,500 sits comfortably inside (75th percentile of range) |
| **Optimal Price Point (OPP)** | EGP 1,408 | We price *above* OPP — we're not a commodity, we're a premium autonomous OS |
| **Indifference Price Point (IPP)** | EGP 1,798 | EGP 2,500 is above IPP — buyers see it as "getting expensive but worth it" |
| **Competitor range** | EGP 1,500 – 8,000/mo | EGP 2,500 beats EduMe/Madrasti entry, undercuts SchoolPlus/Classera |
| **CFO margin at EGP 2,500** | 74% profit margin | Exceptional — leaves massive room for CAC, discounts, partner commissions |
| **Break-even at EGP 2,500** | 7 centers/day | Trivially achievable (plan: 200/day) |
| **Panel buy rate at EGP 2,500** | 26% overall, 67% large centers | Acceptable for launch; will improve with offer stack |

**Verdict**: EGP 2,500 is the *right launch price* — premium enough to signal quality, well inside acceptable range, with 74% margins funding aggressive acquisition.

---

## 2. The Ladder (Good / Better / Best)

| Tier | Target | Price | Includes | Why step up |
|------|--------|-------|----------|-------------|
| **Good** | Independent teacher / micro-center (1 branch, <50 students) | **EGP 800/mo** | Check-in, settlement, family wallet, AI rescue, teacher app | Entry point; captures long tail |
| **Better** | Standard center (1-2 branches, 50-300 students) | **EGP 2,500/mo** | Everything in Good + Super-Admin radar, DRM, multi-branch, priority support | Core product — 80% of revenue here |
| **Best** | Large chain (3+ branches, 300+ students) | **EGP 6,000/mo** | Everything in Better + dedicated CSM, custom integrations, SLA, white-label parent app, API access | Enterprise — locks in chains, high LTV |

**Step-up logic**: Each tier adds *operational leverage* for the next complexity level, not just "more features."

---

## 3. Opening Offer (Launch Campaign)

| Element | Detail |
|---------|--------|
| **Intro price** | **EGP 1,990/mo** (20% off) for first 6 months — *not* a permanent discount |
| **Free onboarding** | NFC tags (50), thermal printer config, data migration — **worth EGP 15,000** |
| **Guarantee** | "First settlement matches cash or we refund 3 months" — CFO costed at <2% claim rate |
| **Deadline** | **30 days from launch** or first 50 centers — whichever comes first |
| **No fake urgency** | Real constraint: onboarding team capacity (4 people) |

**Why this works**: Answers top 3 panel objections — *price* (discount), *switching cost* (free onboarding + migration), *trust* (money-back guarantee). Doesn't train buyers to wait — it's a *launch* offer with hard deadline.

---

## 4. What to Test with Real Buyers

| Test | Method | Success Metric |
|------|--------|----------------|
| **EGP 2,500 vs EGP 2,990** | Two landing pages, split traffic 50/50, measure trial signups | If 2,990 converts >80% of 2,500 rate → raise price |
| **EGP 1,990 launch vs EGP 2,500 regular** | Pre-sale waitlist: "Lock in EGP 1,990 for 6 months" vs "Join at EGP 2,500" | If launch offer drives >3x signups → keep for launch only |
| **Teacher tier EGP 800 vs EGP 1,200** | Direct outreach to 50 independent teachers, A/B price in proposal | Teacher LTV > 12 months at either price → optimize for volume |

---

## 5. Top Panel Price Objections (Verbatim)

1. **"2500 جنيه في الشهر غالي أوي على مركز زي بتاعي، هفضل على الإكسل"** — Small center owner (P038, P039)
2. **"المصروفات كتير وكمان أدفع اشتراك شهري؟ مش مناسبلي دلوقتي"** — Cost-optimizer (P045)
3. **"أنا مدرس مش صاحب مركز، الميزات دي زيادة عليا"** — Independent teacher (P052)

**Marketing must answer these**: "EGP 2,500 = EGP 83/day. If you lose 2 students/month from no-shows, you've paid for Kashkool." + Teacher tier at EGP 800.

---

## 6. Price Sensitivity Triggers (Monitor Monthly)

| Metric | Green | Yellow | Red (Action) |
|--------|-------|--------|--------------|
| **Trial-to-paid conversion** | >25% | 15-25% | <15% → test lower price / improve onboarding |
| **Churn (monthly)** | <3% | 3-5% | >5% → price/value mismatch |
| **Expansion revenue** | >20% of centers upgrade tier | 10-20% | <10% → ladder not compelling |
| **CAC payback** | <3 months | 3-5 months | >5 months → price too low or CAC too high |

---

## 7. If Price Changed → Re-run CFO

Any price change → update `founder/numbers.json` → run `python founder/panel/unit_economics.py founder/numbers.json --out founder/cfo.md`

Current CFO at EGP 2,500: **74% margin, break-even 7/day, payback month 2, year 1 profit EGP 91.5M** — all green.