# Operations Plan: Kashkool

**Objective**: Onboard 50 centers in 30 days (Launch Pack), then scale to 500 by month 6 with <3% monthly churn.

---

## 1. Onboarding Flow (10 Minutes Target)

| Step | Time | Who | Tool | Success Criteria |
|------|------|-----|------|------------------|
| 1. **Welcome Call** | 5 min | CS Agent | Phone/Zoom | Owner confirms: center name, branches, teacher count, printer model |
| 2. **Account Creation** | 1 min | CS Agent | Admin Dashboard | Owner + secretary + 1 teacher invited via WhatsApp deep link |
| 3. **NFC Tag Mapping** | 2 min | CS Agent + Secretary | Mobile App (Admin mode) | 50 tags mapped to seats/rooms, printed stickers applied |
| 4. **Printer Config** | 1 min | Secretary | Mobile App → Settings → Printer | Test receipt prints: "كشكول - اختبار طباعة" |
| 5. **First Check-in** | 1 min | Secretary + Student | Mobile App (Secretary mode) | Student taps → green light → receipt → parent notified |
| 6. **Settlement Dry-Run** | 1 min | Owner | Mobile App (Owner mode) | "تسوية تجريبية" runs, shows teacher amounts, no money moves |
| 7. **Go Live** | — | Owner | — | "تفعيل التسوية الحقيقية" toggle → next 11 PM is live |

**Total Target**: 10 minutes (measured from welcome call start to go-live toggle).

---

## 2. Onboarding Team (Month 1-3)

| Role | Count | Responsibility | Capacity |
|------|-------|----------------|----------|
| **Onboarding Lead** | 1 (Founder month 1, then hire) | Owns process, handles escalations, trains agents | 10 centers/week |
| **CS Agent** | 3 (Month 1) → 6 (Month 3) | Welcome calls, tag mapping, printer config, first-week support | 5 centers/week each |
| **Data Migration Engineer** | 1 (Part-time → Full-time) | Excel/WhatsApp → Kashkool migration script, validation | 3 centers/week |
| **Hardware Logistics** | 1 (Part-time) | NFC tag packing, printer shipping, tracking, returns | 20 centers/week |

**Hiring Trigger**: When weekly onboardings > 15 → hire next CS agent.

---

## 3. Hardware Logistics

| Item | Spec | Qty (Launch) | Supplier | Lead Time | Cost/Unit |
|------|------|--------------|----------|-----------|-----------|
| **NFC Tags (NTAG213)** | 30mm round, printed logo + "اضغط هنا" | 10,000 (200 centers × 50) | Local Cairo supplier | 2 weeks | EGP 7.50 |
| **Thermal Printers** | 58mm, Bluetooth, Arabic font support | 50 units | Distributor (signed) | 1 week | EGP 2,500 |
| **Welcome Box** | Matte black, neon tissue, config card, note | 200 boxes | Local packaging | 1 week | EGP 45 |

**Inventory Buffer**: 20% extra NFC tags (2,000), 5 extra printers.
**Shipping**: Same-day Cairo, next-day Alexandria/Delta, 2-day Upper Egypt (Aramex/Barq).

---

## 4. Data Migration (The #1 Switching Cost)

**Source Formats Supported**:
- Excel (.xlsx, .xls) — students, teachers, schedules, fees
- Google Sheets — live link import
- CSV — generic
- WhatsApp Export — chat history parsing (attendance messages)

**Migration Script** (Python, runs on engineer laptop):
```python
# 1. Parse source → validate schema
# 2. Map columns: student_name, phone, parent_phone, grade, teacher, schedule, fees
# 3. Deduplicate (phone = primary key)
# 4. Generate NFC tag assignments (seat/room)
# 5. Push to Supabase via Admin SDK (batched, idempotent)
# 6. Verify: count match, sample 10 records manual check
# 7. Export migration report (PDF) for owner
```

**SLA**: 4 hours from file receipt → live in app.
**Validation**: Owner signs off on student/teacher counts before go-live.

---

## 5. Support Model (Tiered)

| Tier | Channels | Response SLA | Hours | Covers |
|------|----------|--------------|-------|--------|
| **Launch Pack (Months 1-6)** | WhatsApp (dedicated group), Phone, In-app chat | 15 min (WhatsApp), 1 hr (Phone) | 7 AM - 11 PM | Everything: onboarding, bugs, settlement help, hardware |
| **Standard (Post-launch)** | In-app chat, Email | 2 hr (chat), 4 hr (email) | 9 AM - 9 PM | Product questions, billing, minor issues |
| **Best (Enterprise)** | Dedicated CSM, Phone, Slack, In-app | 5 min (phone), 15 min (chat) | 24/7 | Everything + custom integrations, SLA |

**Escalation Path**: CS Agent → Onboarding Lead → Engineering (P0: settlement/payment down) → Founder.

---

## 6. Settlement Operations (The 11 PM Moment)

**Automated Flow (Zero Human Touch)**:
1. **10:55 PM**: Engine wakes, pulls all unpaid sessions for the day
2. **10:56 PM**: Calculates per-teacher: sessions × rate + bonuses - penalties
3. **10:57 PM**: Generates immutable ledger entries (Drift + Supabase)
4. **10:58 PM**: Pushes "Settlement Ready" notification to owner + teachers
5. **11:00 PM**: Owner taps "تسوية" → triggers payout queue
6. **11:01 PM**: Family Wallet debits → Teacher Wallet credits (instant)
7. **11:02 PM**: Receipts generated (PDF + thermal), WhatsApp sent to teachers
8. **11:03 PM**: Ledger synced to Supabase, backup to Cloud Storage

**Fallback (Payment Rails Down)**:
- Settlement recorded in local Drift DB with `status: pending_rail`
- Retry queue: every 5 min for 1 hr, then every 30 min until success
- Teacher sees "قيد التحويل" in app, owner sees "في الانتظار"
- Zero data loss, zero manual intervention.

**Monitoring**: Edge Function logs → Grafana dashboard → PagerDuty for P0.

---

## 7. Quality Assurance (Pre-Launch Checklist)

| Area | Test | Pass Criteria | Owner |
|------|------|---------------|-------|
| **NFC Check-in** | 100 taps on 5 phone models (iOS/Android) | 100% success, <0.3s, receipt prints | QA Lead |
| **Offline Mode** | Airplane mode → 50 check-ins → reconnect | All 50 sync, no duplicates, ledger intact | QA Lead |
| **Settlement** | 10 centers × 30 days simulated data | Amounts match manual calc to the piastre | CFO + Eng |
| **Payment Rails** | Instapay/Fawry/Vodafone Cash sandbox | 100% success, auto-reconcile, retry works | Eng Lead |
| **Teacher App** | 5 real teachers × 1 week | Zero crashes, settlement confirm < 10s | CS Lead |
| **Parent Notify** | 100 check-ins → WhatsApp/SMS | 99%+ delivery, <5s latency | Eng Lead |
| **Heatmap** | 50 centers live data | Updates <30s, no PII exposed | Eng Lead |
| **Data Export** | 10 centers full export | Excel opens, all sheets complete, no corruption | Eng Lead |
| **Onboarding** | 3 real centers end-to-end | <15 min, zero engineer intervention | CS Lead |

---

## 8. Compliance & Legal (Egypt)

| Requirement | Status | Action |
|-------------|--------|--------|
| **Data Localization** | ✅ Supabase Cairo region | Confirmed |
| **Payment License** | 🔄 Instapay/Fawry merchant onboarding | In progress (2 weeks) |
| **Consumer Protection** | ✅ Terms/Privacy in Arabic, 14-day refund | Legal review done |
| **E-Invoicing (ETA)** | 🔄 Integration with ETA API | Planned Month 2 |
| **Labor Law (Teachers)** | ✅ Settlement = service fee, not salary | Legal opinion obtained |
| **Cybersecurity** | ✅ ISO 27001 controls mapped | Audit Month 3 |

---

## 9. Operational Metrics (Daily Dashboard)

| Metric | Green | Yellow | Red | Owner |
|--------|-------|--------|-----|-------|
| **Onboarding Time** | <15 min | 15-30 min | >30 min | Onboarding Lead |
| **First Settlement Success** | 100% | 95-99% | <95% | Eng Lead |
| **Support Response (WhatsApp)** | <10 min | 10-30 min | >30 min | CS Lead |
| **Hardware Delivery** | On-time | 1 day late | >1 day late | Logistics |
| **Data Migration Accuracy** | 100% | 99% | <99% | Migration Eng |
| **Churn (Monthly)** | <2% | 2-4% | >4% | Founder |
| **NPS (Weekly)** | >60 | 40-60 | <40 | CS Lead |

---

## 10. Scaling Plan (Months 4-12)

| Month | Centers | Team | Key Milestone |
|-------|---------|------|---------------|
| 4 | 100 | +2 CS, +1 Eng | Governorate partnership live (6th Oct + Sheikh Zayed) |
| 5 | 180 | +1 Sales | Referral program = 30% of new centers |
| 6 | 300 | +2 CS, +1 Eng | Teacher tier = 20% of revenue |
| 7 | 400 | +1 Sales, +1 BD | Classera integration (gradebook sync) |
| 8 | 500 | +2 CS | Upper Egypt expansion (Asyut, Sohag, Qena) |
| 9 | 650 | +1 Eng, +1 CS | White-label "Best" tier = 10 chains |
| 10 | 800 | +1 Sales | API marketplace (3rd party integrations) |
| 11 | 1,000 | +2 CS | Series A ready (metrics + team + moat) |
| 12 | 1,200 | — | **Market leader in Egyptian tutoring ops** |

**Hiring Rule**: Never hire ahead of revenue. Each CS agent must handle 20+ centers before next hire.