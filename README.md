# Kashkool (كشكول) — Autonomous EdTech OS

نظام التشغيل التعليمي والسلوكي المتكامل للسوق المصري، مبني بتقنيات Flutter و Supabase ومحرك Drift المحلي مع موجه الذكاء الاصطناعي الفضائي (Spaceship AI Router).

---

## 🗄️ الطبقة الخلفية (Supabase)

- **Postgres + RLS:** كل الجداول محمية بسياسات `supabase/migrations/20261123000003_rls.sql`، والدفع اليومي والايداع محفظة عبر RPCs ذرية/idempotent.
- **Auth:** OTP للهاتف بصيغة `+20...` من Supabase Auth؛ مفيش أكواد وهمية ولا محاكي.
- **Edge Functions:** Deno في `supabase/functions/` للفواتير والمحافظ والتقارير والموجه الدراسي.
- **Offline-first:** Drift هو مصدر الأوفلاين، وطابور المزامنة بيعمل RPCs مع retry/backoff.
- **التشغيل المحلي:** `powershell -ExecutionPolicy Bypass -File scripts\start-dev-backend.ps1` (محتاج Docker).
- **المتغيرات المطلوبة:** `SUPABASE_URL`, `SUPABASE_ANON_KEY` للـ Flutter (عبر `--dart-define`)؛ `SUPABASE_SERVICE_ROLE_KEY`, `WEBHOOK_SECRET`, `SAVIOR_GATEWAY_URL`, `SAVIOR_GATEWAY_KEY` للـ Edge Functions. وثائق التفاصيل في [DEV_AUTH.md](docs/DEV_AUTH.md).

---

## 🌌 الدستور البصري الفضائي (Cosmic Space Glass)
تعتمد واجهات المنظومة بالكامل على تصميم فضائي زجاجي عائم (Zero Gravity Canvas):
- **`CosmicScaffold`**: خلفيات سديمية فضائية ثلاثية الأبعاد.
- **`FloatingGlassCard`**: بطاقات زجاجية عائمة ببلور خلفي متقدم (`BackdropFilter` 24px) وحدود نيون رقيقة.
- **`NeonButton`**: أزرار نيون مشعة بتأثيرات ضوئية تفاعلية.

---

## 🏛️ منظومة الأطراف الخمسة وغرفة السيطرة (God-Mode HQ)
1. **👨‍🏫 المعلم / المحاضر:** White-Label كامل، حاسبة التسوية اليومية الآلية بنقرة واحدة (1-Tap Settlement)، ودرع حماية المحتوى DRM بعلامات مائية متحركة لمنع التسريب.
2. **🏢 إدارة السنتر والقاعات:** لوحة إشغال القاعات اللحظية، حجز الملازم المسبق، والدفتر المحاسبي غير القابل للتلاعب لحماية الكاش.
3. **⚡ السكرتارية ومكتب الدخول:** قاعدة الـ 0.3 ثانية بالمسح الفوري (NFC / Dynamic QR) وإصدار الإيصال الحراري لحظياً أوفلاين مع دعم "متبقي عليه".
4. **🎒 الطالب وصناعة الإدمان الإيجابي:** تحدي الـ 5 دقائق الخاطف، دوري المحافظات، فيديوهات موفرة لباقة الموبايل، وكشكول الإنقاذ الأكاديمي التلقائي لمعالجة أخطاء الكويزات فورياً.
5. **👨‍👩‍👦 ولي الأمر المطمئن:** إشعار الوصول اللحظي لمقعد الحصة، موجز الجمعة الأسبوعي الهادئ، ومحفظة الحصص العائلية للشحن الإلكتروني (إنستاباي / فودافون كاش / فوري).
6. **👑 السوبر أدمن (God-Mode HQ):** رادار مصر التفاعلي الحي (Live Egypt Heatmap)، صمامات الأمان المركزية (Master Kill-Switches)، والدخول الشبحي لحل المشكلات لحظياً.

---

## 🚀 الموجه الفضائي التعليمي (Spaceship AI Router)
- يعمل كخدمة موجهة مستقلة على **Port 4500** (`N:/spaceship-ai/projects/claude-omni-plugin/src/router/spaceship_educational_router.ts`).
- مربوط بـ Free Tiers فائقة السرعة مع Prompt Architecture مفصلة لكل طرف على حدة.
- مزود بعميل ربط Flutter ذكي (`SpaceshipAiClient`) ومحرك احتياط محلي أوفلاين يعمل دون إنترنت (Offline-First Fallback).

---

## 📚 وثائق وخطط المنظومة الكاملة
- **[ARCHITECTURE_AND_ROADMAP.md](docs/ARCHITECTURE_AND_ROADMAP.md)**: المرجع المعماري الشامل والخطط التفصيلية المكتملة.
- **[PROJECT_STATE.json](PROJECT_STATE.json)**: السجل البرمجي الحي لحالة الملفات والمحركات المنجزة.
- **[AGENTS.md](AGENTS.md)**: دستور الجودة الصارم ومعايير الـ Zero-Defect البرمجية.
- **[KASHKOOL_SOVEREIGN_PROMPT.md](file:///C:/Users/ALesraagroup/.gemini/antigravity/brain/c7646baa-6a51-410c-a06c-914e81473cb7/KASHKOOL_SOVEREIGN_PROMPT.md)**: الميثاق الحاكم لتسليم القيادة التأسيسية لأي ذكاء اصطناعي أو مطور جديد.
