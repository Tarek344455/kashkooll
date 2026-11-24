# Product lens
Score: 9 | Vote: FUND
## What is strong
- **Focus — the one thing**: "Autonomous operations for Egyptian tutoring centers." Not an LMS, not a CRM, not a payment app — *the OS that runs the center*. Every feature (check-in, settlement, rescue, wallet, AI, radar) serves that one thing. The product says *no* to: generic course libraries, video hosting, parent-teacher chat, gradebooks — those are features of the *center*, not the *OS*.
- **Experience-first, work back**: 
  - *Secretary at 7 AM*: scans NFC tag → green light → thermal receipt prints → done in 0.3 sec. No typing, no waiting.
  - *Teacher at 11 PM*: opens app → sees "Settlement Ready" → taps once → money in wallet. No spreadsheets, no arguments.
  - *Student*: opens app → sees "5-min Challenge" → dopamine hit → streak saved. No homework dread.
  - *Parent*: gets "Your son arrived at seat 3" → Friday digest → taps "Top up wallet" → Instapay → done.
  - *Super-admin*: opens dashboard → sees live Egypt heatmap → taps "Kill Switch" → fraud stops. No phone calls.
  Every touchpoint is *designed*, not inherited.
- **Own the whole experience**: From the NFC sticker on the desk → to the thermal printer → to the Instapay deep link → to the Friday WhatsApp digest → to the center owner's bank statement. No seams. The *printer* is part of the product. The *NFC tag* is part of the product. The *WhatsApp template* is part of the product.
- **Taste in the invisible parts**: Immutable ledger (no one sees it, but it prevents theft). Offline sync (no one sees it, but it works in a basement center in Minya). Drift schema migrations (no one sees them, but teachers never lose data). The code *you don't see* is where the trust lives.
- **Simplicity**: "Kashkool runs your center while you sleep." One sentence. The product *is* that sentence.

## What would kill it (the top 3, most dangerous first)
1. **Feature creep from stakeholders**: Center owners *will* ask for "gradebook," "video library," "parent chat." Each "yes" breaks the one thing. The product must say no — or spin those out as *integrations*, not core.
2. **Onboarding complexity**: The experience *starts* at "install app, tap NFC, done." If reality is "configure 50 settings, import Excel, train 5 secretaries," the simplicity promise is broken. The first 5 minutes *must* deliver the core value.
3. **Platform fragmentation**: iOS, Android, Windows, Web Admin — four platforms. Space Glass UI must feel identical on all. A bug on Windows admin = "product is broken" for the super-admin. Consistency is the product.

## The questions I would ask the founder
1. **What is the one thing?** Say it in 8 words or fewer. (My guess: "Autonomous center operations for Egyptian tutoring.")
2. **What does the first 5 minutes feel like for a new center owner?** Walk me through it — no demo mode, real data.
3. **What would you cut?** If you had to ship in 2 weeks with 3 engineers, what stays? What goes?
4. **Where are the seams?** NFC tag → app → printer → cloud → wallet → parent WhatsApp. Which handoff breaks most often?
5. **The invisible quality**: Show me the ledger entry for a failed settlement retry. Show me the offline queue flush. That's where the product lives.

## If FUND IF: the conditions
- [ ] Onboarding flow documented: install → first check-in → first settlement in ≤ 10 minutes, zero config
- [ ] "No" list published: features explicitly *not* in core (gradebook, video, chat) — with integration strategy for each
- [ ] Cross-platform parity test: Space Glass UI pixel-perfect on iOS/Android/Windows/Web Admin
- [ ] Invisible quality demo: offline → online sync, ledger immutability, retry queue — all demonstrable in 2 minutes