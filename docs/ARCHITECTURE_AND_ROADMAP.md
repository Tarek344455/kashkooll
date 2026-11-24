# 🌌 KASHKOOL ECOSYSTEM OS — ARCHITECTURE & EXECUTION BIBLE
**Status:** ACTIVE_PRODUCTION_READY  
**Version:** 2.5.0 (Cosmic Edition)  
**Last Updated:** 2026-11-20  

---

## 🎯 ملخص الحالة المعمارية والخطط المكتملة

تم الانتقال بمنظومة «كشكول» من مجرد كود أولي إلى **نظام تشغيل تعليمي متكامل فائق الأوتوميشن (Autonomous EdTech OS)** مصمم خصيصاً لواقع السوق المصري، مع واجهات عائمة بالكامل مستوحاة من الفضاء الكوني.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        KASHKOOL CORE TOPOLOGY                          │
├────────────────────────────────────────────────────────────────────────┤
│ 1. apps/kashkool_app       -> تطبيق العميل الموحد (السنتر، المدرس،    │
│                                الطالب، السكرتير، ولي الأمر)            │
│ 2. apps/kashkool_admin     -> تطبيق السوبر أدمن السيادي (God-Mode HQ) │
│ 3. packages/kashkool_core  -> النماذج والمشتركات والـ Validators المصرية│
│ 4. backend/                -> Supabase Rules + Edge Functions        │
│ 5. spaceship-ai/           -> الموجه التعليمي الفضائي (Port 4500)      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🏛️ خريطة الخطط والمراحل البرمجية (Roadmap Status)

### ✅ المرحلة 1: الهوية البصرية الفضائية العائمة (Cosmic Space Glass Canvas)
- **`CosmicScaffold`**: خلفية كونية ثلاثية الأبعاد بتدرجات السديم النيون (`#1E1B4B` و `#00F5D4`).
- **`FloatingGlassCard`**: بطاقات زجاجية عائمة بتأثير بلور 24px وحدود نيون وظلال خفية.
- **`NeonButton`**: أزرار نيون مشعة تفاعلية.
- **`FloatingRoleDeckScreen`**: سلايدز عائمة ثلاثية الأبعاد تشرح أدوار الأطراف الستة بالتفصيل.

### ✅ المرحلة 2: محركات الأوتوميشن السريعة والميدانية
- **`AutoQueueDeskScreen`**: بوابة السلالم بقاعدة الـ 0.3 ثانية، مسح فوري بالـ NFC / QR، إشارة لونية لحظية، دعم "متبقي عليه"، وإصدار أمر الطباعة الحرارية دون لمس الشاشة.
- **`FloatingSettlementScreen`**: حاسبة التسوية اليومية الآلية بنقرة واحدة (1-Tap Settlement)، تصفية حسابات المدرس مع السناتر الساعة 11:00 م، وحسم النسب والملازم تلقائياً.
- **`FloatingRemedialScreen`**: كشكول الإنقاذ الأكاديمي التلقائي؛ تشخيص أخطاء الكويزات وتوليد شيت تدريب تعويضي فوري للطالب.
- **`FloatingFamilyWalletScreen`**: محفظة الحصص العائلية؛ شحن إلكتروني فوري (إنستاباي، فودافون كاش، فوري)، ودفتر حركات نقدية مشفر (Immutable Ledger).

### ✅ المرحلة 3: الموجه الفضائي التعليمي المجاني (Spaceship AI Router)
- **`spaceship_educational_router.ts`**: سيرفر مستقل في `N:/spaceship-ai` يعمل على Port 4500.
- **Prompt Architecture مخصصة لكل طرف**:
  - الطالب: أسلوب سقراطي توجيهي مع تعزيز الدوبامين.
  - المعلم: توليد أسئلة مستويات تفكير عليا وشيتات.
  - السنتر: لوجستيات القاعات وحركة الحشود.
  - السكرتارية: نصوص مالية سريعة ومختصرة.
  - ولي الأمر: تقارير طمأنينة واستشارات تربوية.
  - الأدمن: رادار السيولة وكشف التلاعب.
- **`SpaceshipAiClient`**: عميل الربط في Flutter مع محرك احتياط محلي أوفلاين (Offline-First Fallback).
- **`StudyAssistantDrawer`**: درج المساعد الأكاديمي في التطبيق مع زر التبديل الفوري بين وضع الطالب ووضع المعلم.

### ✅ المرحلة 4: معالجة بيئة البناء وتجهيز Android SDK
- تثبيت `Android SDK 36` و `platforms;android-34` وحزم `build-tools`.
- توجيه كاش الـ Gradle والـ Wrapper محلياً في `build-vault`.
- ترقية ملفات `build.gradle.kts` لفرض `compileSdkVersion 34` على كافة المكتبات القديمة.

---

## 🧭 الملفات المرجعية والوثائق الحاكمة في المشروع

1. **[PROJECT_STATE.json](file:///N:/opencode/projects/kashkool/PROJECT_STATE.json)**: السجل الحي لحالة المنظومة المعمارية والبرمجية.
2. **[KASHKOOL_SOVEREIGN_PROMPT.md](file:///C:/Users/ALesraagroup/.gemini/antigravity/brain/c7646baa-6a51-410c-a06c-914e81473cb7/KASHKOOL_SOVEREIGN_PROMPT.md)**: الميثاق التأسيسي الشامل لتسليم القيادة لأي مهندس أو ذكاء اصطناعي.
3. **[Kashkool_Deep_Matrix.md](file:///C:/Users/ALesraagroup/.gemini/antigravity/brain/c7646baa-6a51-410c-a06c-914e81473cb7/Kashkool_Deep_Matrix.md)**: دراسة الاختراعات السبعة والتشريح النفسي السلوكي للأطراف.
4. **[Kashkool_Automation_Engine.md](file:///C:/Users/ALesraagroup/.gemini/antigravity/brain/c7646baa-6a51-410c-a06c-914e81473cb7/Kashkool_Automation_Engine.md)**: محركات الأوتوميشن الستة العاملة في الخلفية 24/7.
