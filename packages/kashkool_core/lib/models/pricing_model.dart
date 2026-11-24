/// Modular pricing configuration for Kashkool.
/// Teacher ≠ Center accounts, granular modules, zero-budget friendly.

/// Settlement decision made by the intelligence fabric.
class SettlementDecision {
  final bool shouldSettle;
  final double suggestedAmount;
  final List<String> reasons;
  final double confidence;

  const SettlementDecision({
    required this.shouldSettle,
    required this.suggestedAmount,
    required this.reasons,
    required this.confidence,
  });

  Map<String, dynamic> toJson() => {
    'shouldSettle': shouldSettle,
    'suggestedAmount': suggestedAmount,
    'reasons': reasons,
    'confidence': confidence,
  };

  factory SettlementDecision.fromJson(Map<String, dynamic> json) => SettlementDecision(
    shouldSettle: json['shouldSettle'] as bool,
    suggestedAmount: (json['suggestedAmount'] as num).toDouble(),
    reasons: List<String>.from(json['reasons'] as List),
    confidence: (json['confidence'] as num).toDouble(),
  );
}

/// Pricing recommendation from the intelligence fabric.
class PricingRecommendation {
  final List<String> recommendedModules;
  final double estimatedMonthlyCost;
  final double savingsVsBundled;
  final String reasoning;

  const PricingRecommendation({
    required this.recommendedModules,
    required this.estimatedMonthlyCost,
    required this.savingsVsBundled,
    required this.reasoning,
  });

  Map<String, dynamic> toJson() => {
    'recommendedModules': recommendedModules,
    'estimatedMonthlyCost': estimatedMonthlyCost,
    'savingsVsBundled': savingsVsBundled,
    'reasoning': reasoning,
  };

  factory PricingRecommendation.fromJson(Map<String, dynamic> json) => PricingRecommendation(
    recommendedModules: List<String>.from(json['recommendedModules'] as List),
    estimatedMonthlyCost: (json['estimatedMonthlyCost'] as num).toDouble(),
    savingsVsBundled: (json['savingsVsBundled'] as num).toDouble(),
    reasoning: json['reasoning'] as String,
  );
}

enum AccountType {
  teacher,
  center,
}

enum ModuleId {
  // Teacher modules
  teacherCore,
  teacherSettlementAuto,
  teacherWalletPayout,
  teacherContentDrm,
  teacherStudentInsights,
  teacherMultiCenter,
  teacherWhiteLabelParentApp,

  // Center modules
  centerCore,
  centerAttendancePro,
  centerSettlementEngine,
  centerFamilyWallet,
  centerTeacherPortal,
  centerStudentEngagement,
  centerMultiBranch,
  centerGodModeRadar,
  centerCustomIntegrations,
  centerWhiteLabelEverything,
}

enum BillingCycle {
  monthly,
  yearly,
}

class ModulePricing {
  final ModuleId id;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final int priceMonthlyEgp; // in EGP
  final int priceYearlyEgp; // in EGP (10 months = 12 months)
  final AccountType accountType;
  final Map<String, dynamic> freeTierLimits; // e.g., {'students': 50, 'sessionsPerWeek': 10}
  final List<String> features; // feature flags this module unlocks
  final bool isPopular;
  final int sortOrder;

  const ModulePricing({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.priceMonthlyEgp,
    required this.priceYearlyEgp,
    required this.accountType,
    required this.freeTierLimits,
    required this.features,
    this.isPopular = false,
    required this.sortOrder,
  });

  int getPrice(BillingCycle cycle) => cycle == BillingCycle.monthly ? priceMonthlyEgp : priceYearlyEgp;

  String getFormattedPrice(BillingCycle cycle) {
    final price = getPrice(cycle);
    if (price == 0) return 'مجاني';
    return '${price.toString()} ج.م/${cycle == BillingCycle.monthly ? 'شهر' : 'سنة'}';
  }

  Map<String, dynamic> toJson() => {
    'id': id.name,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'descriptionAr': descriptionAr,
    'descriptionEn': descriptionEn,
    'priceMonthlyEgp': priceMonthlyEgp,
    'priceYearlyEgp': priceYearlyEgp,
    'accountType': accountType.name,
    'freeTierLimits': freeTierLimits,
    'features': features,
    'isPopular': isPopular,
    'sortOrder': sortOrder,
  };

  factory ModulePricing.fromJson(Map<String, dynamic> json) => ModulePricing(
    id: ModuleId.values.firstWhere((e) => e.name == json['id']),
    nameAr: json['nameAr'] as String,
    nameEn: json['nameEn'] as String,
    descriptionAr: json['descriptionAr'] as String,
    descriptionEn: json['descriptionEn'] as String,
    priceMonthlyEgp: json['priceMonthlyEgp'] as int,
    priceYearlyEgp: json['priceYearlyEgp'] as int,
    accountType: AccountType.values.firstWhere((e) => e.name == json['accountType']),
    freeTierLimits: Map<String, dynamic>.from(json['freeTierLimits'] as Map),
    features: List<String>.from(json['features'] as List),
    isPopular: json['isPopular'] as bool? ?? false,
    sortOrder: json['sortOrder'] as int,
  );
}

/// Complete pricing catalog - single source of truth
class PricingCatalog {
  static final List<ModulePricing> allModules = [
    // ============ TEACHER MODULES ============
    ModulePricing(
      id: ModuleId.teacherCore,
      nameAr: 'أساسيات المعلم',
      nameEn: 'Teacher Core',
      descriptionAr: '50 طالب، 10 حصص/أسبوع، QR check-in، تقارير أساسية',
      descriptionEn: '50 students, 10 sessions/week, QR check-in, basic reports',
      priceMonthlyEgp: 0,
      priceYearlyEgp: 0,
      accountType: AccountType.teacher,
      freeTierLimits: {'students': 50, 'sessionsPerWeek': 10, 'qrCheckin': true},
      features: ['qr_checkin', 'basic_reports', 'student_management'],
      isPopular: true,
      sortOrder: 1,
    ),
    ModulePricing(
      id: ModuleId.teacherSettlementAuto,
      nameAr: 'تسوية تلقائية',
      nameEn: 'Settlement Auto',
      descriptionAr: 'حساب مستحقات تلقائي، كشف شهري، تصدير PDF/Excel',
      descriptionEn: 'Auto-calc dues, monthly statement, PDF/Excel export',
      priceMonthlyEgp: 50,
      priceYearlyEgp: 500,
      accountType: AccountType.teacher,
      freeTierLimits: {},
      features: ['auto_settlement', 'monthly_statement', 'pdf_export'],
      sortOrder: 2,
    ),
    ModulePricing(
      id: ModuleId.teacherWalletPayout,
      nameAr: 'محفظة وسحب',
      nameEn: 'Wallet & Payout',
      descriptionAr: 'استلام Instapay/Fawry، سحب بنكي، مصالحة تلقائية',
      descriptionEn: 'Receive Instapay/Fawry, bank withdraw, auto-reconcile',
      priceMonthlyEgp: 30,
      priceYearlyEgp: 300,
      accountType: AccountType.teacher,
      freeTierLimits: {},
      features: ['wallet_receive', 'bank_withdraw', 'auto_reconcile'],
      sortOrder: 3,
    ),
    ModulePricing(
      id: ModuleId.teacherContentDrm,
      nameAr: 'حماية المحتوى (DRM)',
      nameEn: 'Content DRM',
      descriptionAr: 'علامة مائية، منع سكرينشوت، تتبع تسريب، تشفير فيديو',
      descriptionEn: 'Watermark, screenshot block, leak trace, video encryption',
      priceMonthlyEgp: 40,
      priceYearlyEgp: 400,
      accountType: AccountType.teacher,
      freeTierLimits: {},
      features: ['watermark', 'screenshot_block', 'leak_trace', 'video_encryption'],
      sortOrder: 4,
    ),
    ModulePricing(
      id: ModuleId.teacherStudentInsights,
      nameAr: 'تقارير ذكية للطلاب',
      nameEn: 'Student Insights',
      descriptionAr: 'تقارير أداء بالذكاء الاصطناعي، اقتراحات علاجية، تنبيهات تراجع',
      descriptionEn: 'AI performance reports, remedial suggestions, decline alerts',
      priceMonthlyEgp: 30,
      priceYearlyEgp: 300,
      accountType: AccountType.teacher,
      freeTierLimits: {},
      features: ['ai_reports', 'remedial_suggestions', 'decline_alerts'],
      sortOrder: 5,
    ),
    ModulePricing(
      id: ModuleId.teacherMultiCenter,
      nameAr: 'متعدد المراكز',
      nameEn: 'Multi-Center',
      descriptionAr: 'تدريس في عدة مراكز، جدول موحد، فصل البيانات',
      descriptionEn: 'Teach at multiple centers, unified schedule, data isolation',
      priceMonthlyEgp: 20,
      priceYearlyEgp: 200,
      accountType: AccountType.teacher,
      freeTierLimits: {},
      features: ['multi_center_schedule', 'data_isolation'],
      sortOrder: 6,
    ),
    ModulePricing(
      id: ModuleId.teacherWhiteLabelParentApp,
      nameAr: 'تطبيق أولياء أمور بعلامتك',
      nameEn: 'White-Label Parent App',
      descriptionAr: 'تطبيق مخصص لطلابك، علامتك التجارية، دومين خاص',
      descriptionEn: 'Branded app for your students, your brand, custom domain',
      priceMonthlyEgp: 100,
      priceYearlyEgp: 1000,
      accountType: AccountType.teacher,
      freeTierLimits: {},
      features: ['white_label_app', 'custom_domain', 'branded_emails'],
      sortOrder: 7,
    ),

    // ============ CENTER MODULES ============
    ModulePricing(
      id: ModuleId.centerCore,
      nameAr: 'أساسيات المركز',
      nameEn: 'Center Core',
      descriptionAr: 'قاعتين، 5 معلمين، 100 طالب، QR check-in، تقارير أساسية',
      descriptionEn: '2 halls, 5 teachers, 100 students, QR check-in, basic reports',
      priceMonthlyEgp: 0,
      priceYearlyEgp: 0,
      accountType: AccountType.center,
      freeTierLimits: {'halls': 2, 'teachers': 5, 'students': 100, 'qrCheckin': true},
      features: ['qr_checkin', 'basic_reports', 'hall_management', 'teacher_management'],
      isPopular: true,
      sortOrder: 1,
    ),
    ModulePricing(
      id: ModuleId.centerAttendancePro,
      nameAr: 'حضور متقدم',
      nameEn: 'Attendance Pro',
      descriptionAr: 'قاعات/معلمين غير محدود، تقارير يومية، تنبيهات غياب، تصدير',
      descriptionEn: 'Unlimited halls/teachers, daily reports, absence alerts, export',
      priceMonthlyEgp: 200,
      priceYearlyEgp: 2000,
      accountType: AccountType.center,
      freeTierLimits: {},
      features: ['unlimited_halls', 'unlimited_teachers', 'daily_reports', 'absence_alerts', 'attendance_export'],
      sortOrder: 2,
    ),
    ModulePricing(
      id: ModuleId.centerSettlementEngine,
      nameAr: 'محرك التسوية',
      nameEn: 'Settlement Engine',
      descriptionAr: 'قواعد مرنة، سجل غير قابل للتغيير، تسوية بضغطة واحدة 11 مساءً',
      descriptionEn: 'Flexible rules, immutable ledger, 1-tap 11 PM settlement',
      priceMonthlyEgp: 300,
      priceYearlyEgp: 3000,
      accountType: AccountType.center,
      freeTierLimits: {},
      features: ['flexible_rules', 'immutable_ledger', 'one_tap_settlement', 'offline_fallback'],
      isPopular: true,
      sortOrder: 3,
    ),
    ModulePricing(
      id: ModuleId.centerFamilyWallet,
      nameAr: 'محفظة العائلة',
      nameEn: 'Family Wallet',
      descriptionAr: 'شحن ولي الأمر، صرف المعلم، مصالحة تلقائية، كشف موحد',
      descriptionEn: 'Parent top-up, teacher payout, auto-reconcile, unified statement',
      priceMonthlyEgp: 150,
      priceYearlyEgp: 1500,
      accountType: AccountType.center,
      freeTierLimits: {},
      features: ['parent_topup', 'teacher_payout', 'auto_reconcile', 'unified_statement'],
      sortOrder: 4,
    ),
    ModulePricing(
      id: ModuleId.centerTeacherPortal,
      nameAr: 'بوابة المعلمين',
      nameEn: 'Teacher Portal',
      descriptionAr: 'المعلم يرى جدوله، مستحقاته، طلابه، يرفع محتوى - تأكيد < 10 ث',
      descriptionEn: 'Teacher sees schedule, dues, students, uploads content - confirm < 10s',
      priceMonthlyEgp: 100,
      priceYearlyEgp: 1000,
      accountType: AccountType.center,
      freeTierLimits: {},
      features: ['teacher_schedule', 'teacher_dues', 'teacher_students', 'content_upload', 'quick_confirm'],
      sortOrder: 5,
    ),
    ModulePricing(
      id: ModuleId.centerStudentEngagement,
      nameAr: 'تفاعل الطلاب',
      nameEn: 'Student Engagement',
      descriptionAr: 'تحديات يومية، سلاسل، تمارين علاجية بالذكاء الاصطناعي، تقارير واتساب للأهل',
      descriptionEn: 'Daily challenges, streaks, AI remedial, parent WhatsApp reports',
      priceMonthlyEgp: 120,
      priceYearlyEgp: 1200,
      accountType: AccountType.center,
      freeTierLimits: {},
      features: ['daily_challenges', 'streaks', 'ai_remedial', 'whatsapp_reports'],
      sortOrder: 6,
    ),
    ModulePricing(
      id: ModuleId.centerMultiBranch,
      nameAr: 'متعدد الفروع',
      nameEn: 'Multi-Branch',
      descriptionAr: 'فروع متعددة، مخزون موحد، تحويلات بين الفروع، تقارير موحدة',
      descriptionEn: 'Multiple branches, unified inventory, cross-branch transfers, unified reports',
      priceMonthlyEgp: 200,
      priceYearlyEgp: 2000,
      accountType: AccountType.center,
      freeTierLimits: {},
      features: ['multi_branch', 'unified_inventory', 'cross_branch_transfer', 'unified_reports'],
      sortOrder: 7,
    ),
    ModulePricing(
      id: ModuleId.centerGodModeRadar,
      nameAr: 'رادار الوضع الإلهي',
      nameEn: 'God-Mode Radar',
      descriptionAr: 'خريطة حرارية حية، مفاتيح قتل، انتحال شبح، استخبارات منافسين',
      descriptionEn: 'Live heatmap, kill-switches, ghost impersonation, competitor intel',
      priceMonthlyEgp: 500,
      priceYearlyEgp: 5000,
      accountType: AccountType.center,
      freeTierLimits: {},
      features: ['live_heatmap', 'kill_switches', 'ghost_impersonation', 'competitor_intel'],
      sortOrder: 8,
    ),
    ModulePricing(
      id: ModuleId.centerCustomIntegrations,
      nameAr: 'تكاملات مخصصة',
      nameEn: 'Custom Integrations',
      descriptionAr: 'API، Webhooks، مزامنة ERP، تصدير مجدول، SSO',
      descriptionEn: 'API, webhooks, ERP sync, scheduled exports, SSO',
      priceMonthlyEgp: 300,
      priceYearlyEgp: 3000,
      accountType: AccountType.center,
      freeTierLimits: {},
      features: ['api_access', 'webhooks', 'erp_sync', 'scheduled_exports', 'sso'],
      sortOrder: 9,
    ),
    ModulePricing(
      id: ModuleId.centerWhiteLabelEverything,
      nameAr: 'علامة تجارية كاملة',
      nameEn: 'White-Label Everything',
      descriptionAr: 'تطبيق بعلامتك، دومين خاص، إيميلات @center.com، تخصيص كامل',
      descriptionEn: 'Branded app, custom domain, @center.com emails, full customization',
      priceMonthlyEgp: 800,
      priceYearlyEgp: 8000,
      accountType: AccountType.center,
      freeTierLimits: {},
      features: ['white_label_app', 'custom_domain', 'branded_emails', 'full_customization'],
      sortOrder: 10,
    ),
  ];

  static List<ModulePricing> getModulesForAccountType(AccountType type) {
    return allModules.where((m) => m.accountType == type).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  static ModulePricing? getModule(ModuleId id) {
    try {
      return allModules.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  static Map<ModuleId, ModulePricing> getModuleMap() {
    return {for (var m in allModules) m.id: m};
  }
}

/// Promo codes - code only, no cash cost
class PromoCode {
  final String code;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final PromoType type;
  final dynamic value; // depends on type
  final int? maxUses;
  final int? maxUsesPerAccount;
  final DateTime? expiresAt;
  final List<AccountType> applicableAccountTypes;
  final List<ModuleId>? applicableModules; // null = all

  const PromoCode({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.type,
    required this.value,
    this.maxUses,
    this.maxUsesPerAccount,
    this.expiresAt,
    required this.applicableAccountTypes,
    this.applicableModules,
  });

  bool isValid({AccountType? accountType, ModuleId? moduleId, int? currentUses, int? accountUses}) {
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    if (maxUses != null && currentUses != null && currentUses >= maxUses!) return false;
    if (maxUsesPerAccount != null && accountUses != null && accountUses >= maxUsesPerAccount!) return false;
    if (accountType != null && !applicableAccountTypes.contains(accountType)) return false;
    if (moduleId != null && applicableModules != null && !applicableModules!.contains(moduleId)) return false;
    return true;
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'descriptionAr': descriptionAr,
    'descriptionEn': descriptionEn,
    'type': type.name,
    'value': value,
    'maxUses': maxUses,
    'maxUsesPerAccount': maxUsesPerAccount,
    'expiresAt': expiresAt?.toIso8601String(),
    'applicableAccountTypes': applicableAccountTypes.map((e) => e.name).toList(),
    'applicableModules': applicableModules?.map((e) => e.name).toList(),
  };

  factory PromoCode.fromJson(Map<String, dynamic> json) => PromoCode(
    code: json['code'] as String,
    nameAr: json['nameAr'] as String,
    nameEn: json['nameEn'] as String,
    descriptionAr: json['descriptionAr'] as String,
    descriptionEn: json['descriptionEn'] as String,
    type: PromoType.values.firstWhere((e) => e.name == json['type']),
    value: json['value'],
    maxUses: json['maxUses'] as int?,
    maxUsesPerAccount: json['maxUsesPerAccount'] as int?,
    expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
    applicableAccountTypes: (json['applicableAccountTypes'] as List).map((e) => AccountType.values.firstWhere((a) => a.name == e)).toList(),
    applicableModules: (json['applicableModules'] as List?)?.map((e) => ModuleId.values.firstWhere((m) => m.name == e)).toList(),
  );
}

enum PromoType {
  freeMonths,      // value: int (number of free months)
  percentOff,      // value: int (percentage)
  bundleDiscount,  // value: int (percentage off 2nd module)
  freeModule,      // value: ModuleId (free module with purchase)
  referralCredit,  // value: int (free months for both parties)
}

class PromoCatalog {
  static final List<PromoCode> allPromos = [
    PromoCode(
      code: 'TRIAL3',
      nameAr: 'تجربة 3 أشهر',
      nameEn: '3-Month Trial',
      descriptionAr: '3 أشهر مجانية على أي وحدة مدفوعة (أول 50 حساب)',
      descriptionEn: '3 months free on any paid module (first 50 accounts)',
      type: PromoType.freeMonths,
      value: 3,
      maxUses: 50,
      maxUsesPerAccount: 1,
      applicableAccountTypes: [AccountType.teacher, AccountType.center],
    ),
    PromoCode(
      code: 'BUNDLE2',
      nameAr: 'خصم الحزمة',
      nameEn: 'Bundle Discount',
      descriptionAr: '50% خصم على الوحدة الثانية عند اختيار وحدتين أو أكثر',
      descriptionEn: '50% off 2nd module when 2+ selected',
      type: PromoType.bundleDiscount,
      value: 50,
      maxUsesPerAccount: 1,
      applicableAccountTypes: [AccountType.teacher, AccountType.center],
    ),
    PromoCode(
      code: 'YEARLY',
      nameAr: 'دفع سنوي',
      nameEn: 'Yearly Payment',
      descriptionAr: 'ادفع 10 أشهر واحصل على 12 شهر',
      descriptionEn: 'Pay 10 months, get 12',
      type: PromoType.percentOff,
      value: 17, // ~17% off (2 months free out of 12)
      applicableAccountTypes: [AccountType.teacher, AccountType.center],
    ),
    PromoCode(
      code: 'TEACHERFREE',
      nameAr: 'معلم مجاني',
      nameEn: 'Free Teacher',
      descriptionAr: 'حساب معلم مجاني مع اشتراك تسوية المركز',
      descriptionEn: '1 free teacher account with Center Settlement subscription',
      type: PromoType.freeModule,
      value: 'teacherCore',
      applicableAccountTypes: [AccountType.center],
      applicableModules: [ModuleId.centerSettlementEngine],
    ),
    PromoCode(
      code: 'REFERRAL',
      nameAr: 'إحالة',
      nameEn: 'Referral',
      descriptionAr: 'كلا الطرفين يحصلان على شهر مجاني على الوحدة المشتركة',
      descriptionEn: 'Both parties get 1 free month on shared module',
      type: PromoType.referralCredit,
      value: 1,
      applicableAccountTypes: [AccountType.teacher, AccountType.center],
    ),
  ];

  static PromoCode? getPromo(String code) {
    try {
      return allPromos.firstWhere((p) => p.code == code);
    } catch (_) {
      return null;
    }
  }

  static List<PromoCode> getValidPromos({AccountType? accountType, ModuleId? moduleId}) {
    return allPromos.where((p) => p.isValid(accountType: accountType, moduleId: moduleId)).toList();
  }
}

/// Usage-based metering (metered billing)
class UsageMetering {
  static final Map<String, UsagePrice> prices = {
    'sms': UsagePrice(
      unit: 'sms',
      unitNameAr: 'رسالة SMS',
      unitNameEn: 'SMS message',
      pricePerUnitEgp: 0.025, // EGP 25 per 1K
      bundleSize: 1000,
      bundlePriceEgp: 25,
    ),
    'whatsapp': UsagePrice(
      unit: 'whatsapp',
      unitNameAr: 'رسالة واتساب',
      unitNameEn: 'WhatsApp message',
      pricePerUnitEgp: 0.025,
      bundleSize: 1000,
      bundlePriceEgp: 25,
    ),
    'ai_remedial': UsagePrice(
      unit: 'exercise',
      unitNameAr: 'تمرين علاجي',
      unitNameEn: 'Remedial exercise',
      pricePerUnitEgp: 0.10, // EGP 10 per 100
      bundleSize: 100,
      bundlePriceEgp: 10,
    ),
    'storage': UsagePrice(
      unit: 'gb',
      unitNameAr: 'جيجابايت',
      unitNameEn: 'GB',
      pricePerUnitEgp: 5, // EGP 5/GB/mo
      bundleSize: 1,
      bundlePriceEgp: 5,
    ),
    'api_calls': UsagePrice(
      unit: 'call',
      unitNameAr: 'استدعاء API',
      unitNameEn: 'API call',
      pricePerUnitEgp: 0.0015, // EGP 15 per 10K
      bundleSize: 10000,
      bundlePriceEgp: 15,
    ),
  };

  static UsagePrice? getPrice(String meterKey) => prices[meterKey];
}

class UsagePrice {
  final String unit;
  final String unitNameAr;
  final String unitNameEn;
  final double pricePerUnitEgp;
  final int bundleSize;
  final int bundlePriceEgp;

  const UsagePrice({
    required this.unit,
    required this.unitNameAr,
    required this.unitNameEn,
    required this.pricePerUnitEgp,
    required this.bundleSize,
    required this.bundlePriceEgp,
  });

  double calculateCost(int quantity) {
    final bundles = (quantity / bundleSize).ceil();
    return bundles * bundlePriceEgp.toDouble();
  }

  Map<String, dynamic> toJson() => {
    'unit': unit,
    'unitNameAr': unitNameAr,
    'unitNameEn': unitNameEn,
    'pricePerUnitEgp': pricePerUnitEgp,
    'bundleSize': bundleSize,
    'bundlePriceEgp': bundlePriceEgp,
  };
}

/// Feature flags - each module = flag
class FeatureFlags {
  static final Map<String, FeatureFlag> allFlags = {
    // Teacher flags
    'qr_checkin': FeatureFlag(
      key: 'qr_checkin',
      nameAr: 'QR Check-in',
      nameEn: 'QR Check-in',
      descriptionAr: 'فحص الحضور بكود QR',
      descriptionEn: 'QR code attendance check-in',
      moduleId: ModuleId.teacherCore,
      defaultEnabled: true,
    ),
    'basic_reports': FeatureFlag(
      key: 'basic_reports',
      nameAr: 'تقارير أساسية',
      nameEn: 'Basic Reports',
      descriptionAr: 'تقارير حضور وأداء أساسية',
      descriptionEn: 'Basic attendance and performance reports',
      moduleId: ModuleId.teacherCore,
      defaultEnabled: true,
    ),
    'student_management': FeatureFlag(
      key: 'student_management',
      nameAr: 'إدارة الطلاب',
      nameEn: 'Student Management',
      descriptionAr: 'إضافة/تعديل/حذف طلاب',
      descriptionEn: 'Add/edit/delete students',
      moduleId: ModuleId.teacherCore,
      defaultEnabled: true,
    ),
    'auto_settlement': FeatureFlag(
      key: 'auto_settlement',
      nameAr: 'تسوية تلقائية',
      nameEn: 'Auto Settlement',
      descriptionAr: 'حساب مستحقات تلقائي',
      descriptionEn: 'Automatic dues calculation',
      moduleId: ModuleId.teacherSettlementAuto,
      defaultEnabled: false,
    ),
    'monthly_statement': FeatureFlag(
      key: 'monthly_statement',
      nameAr: 'كشف شهري',
      nameEn: 'Monthly Statement',
      descriptionAr: 'كشف حساب شهري PDF/Excel',
      descriptionEn: 'Monthly PDF/Excel statement',
      moduleId: ModuleId.teacherSettlementAuto,
      defaultEnabled: false,
    ),
    'pdf_export': FeatureFlag(
      key: 'pdf_export',
      nameAr: 'تصدير PDF',
      nameEn: 'PDF Export',
      descriptionAr: 'تصدير التقارير كملف PDF',
      descriptionEn: 'Export reports as PDF',
      moduleId: ModuleId.teacherSettlementAuto,
      defaultEnabled: false,
    ),
    'wallet_receive': FeatureFlag(
      key: 'wallet_receive',
      nameAr: 'استلام مدفوعات',
      nameEn: 'Receive Payments',
      descriptionAr: 'استلام Instapay/Fawry/Vodafone Cash',
      descriptionEn: 'Receive Instapay/Fawry/Vodafone Cash',
      moduleId: ModuleId.teacherWalletPayout,
      defaultEnabled: false,
    ),
    'bank_withdraw': FeatureFlag(
      key: 'bank_withdraw',
      nameAr: 'سحب بنكي',
      nameEn: 'Bank Withdraw',
      descriptionAr: 'سحب الرصيد للحساب البنكي',
      descriptionEn: 'Withdraw balance to bank account',
      moduleId: ModuleId.teacherWalletPayout,
      defaultEnabled: false,
    ),
    'auto_reconcile': FeatureFlag(
      key: 'auto_reconcile',
      nameAr: 'مصالحة تلقائية',
      nameEn: 'Auto Reconcile',
      descriptionAr: 'مصالحة المدفوعات تلقائياً',
      descriptionEn: 'Automatic payment reconciliation',
      moduleId: ModuleId.teacherWalletPayout,
      defaultEnabled: false,
    ),
    'watermark': FeatureFlag(
      key: 'watermark',
      nameAr: 'علامة مائية',
      nameEn: 'Watermark',
      descriptionAr: 'إضافة علامة مائية للمحتوى',
      descriptionEn: 'Add watermark to content',
      moduleId: ModuleId.teacherContentDrm,
      defaultEnabled: false,
    ),
    'screenshot_block': FeatureFlag(
      key: 'screenshot_block',
      nameAr: 'منع سكرينشوت',
      nameEn: 'Screenshot Block',
      descriptionAr: 'منع التقاط الشاشة للمحتوى المحمي',
      descriptionEn: 'Block screenshots of protected content',
      moduleId: ModuleId.teacherContentDrm,
      defaultEnabled: false,
    ),
    'leak_trace': FeatureFlag(
      key: 'leak_trace',
      nameAr: 'تتبع التسريب',
      nameEn: 'Leak Trace',
      descriptionAr: 'تتبع مصدر تسريب المحتوى',
      descriptionEn: 'Trace source of content leaks',
      moduleId: ModuleId.teacherContentDrm,
      defaultEnabled: false,
    ),
    'video_encryption': FeatureFlag(
      key: 'video_encryption',
      nameAr: 'تشفير الفيديو',
      nameEn: 'Video Encryption',
      descriptionAr: 'تشفير محتوى الفيديو',
      descriptionEn: 'Encrypt video content',
      moduleId: ModuleId.teacherContentDrm,
      defaultEnabled: false,
    ),
    'ai_reports': FeatureFlag(
      key: 'ai_reports',
      nameAr: 'تقارير ذكية',
      nameEn: 'AI Reports',
      descriptionAr: 'تقارير أداء بالذكاء الاصطناعي',
      descriptionEn: 'AI-powered performance reports',
      moduleId: ModuleId.teacherStudentInsights,
      defaultEnabled: false,
    ),
    'remedial_suggestions': FeatureFlag(
      key: 'remedial_suggestions',
      nameAr: 'اقتراحات علاجية',
      nameEn: 'Remedial Suggestions',
      descriptionAr: 'اقتراحات تمارين علاجية بالذكاء الاصطناعي',
      descriptionEn: 'AI remedial exercise suggestions',
      moduleId: ModuleId.teacherStudentInsights,
      defaultEnabled: false,
    ),
    'decline_alerts': FeatureFlag(
      key: 'decline_alerts',
      nameAr: 'ت��بيهات تراجع',
      nameEn: 'Decline Alerts',
      descriptionAr: 'تنبيهات عند تراجع أداء الطالب',
      descriptionEn: 'Alerts on student performance decline',
      moduleId: ModuleId.teacherStudentInsights,
      defaultEnabled: false,
    ),
    'multi_center_schedule': FeatureFlag(
      key: 'multi_center_schedule',
      nameAr: 'جدول متعدد المراكز',
      nameEn: 'Multi-Center Schedule',
      descriptionAr: 'جدول موحد لعدة مراكز',
      descriptionEn: 'Unified schedule for multiple centers',
      moduleId: ModuleId.teacherMultiCenter,
      defaultEnabled: false,
    ),
    'data_isolation': FeatureFlag(
      key: 'data_isolation',
      nameAr: 'عزل البيانات',
      nameEn: 'Data Isolation',
      descriptionAr: 'فصل بيانات كل مركز',
      descriptionEn: 'Isolate data per center',
      moduleId: ModuleId.teacherMultiCenter,
      defaultEnabled: false,
    ),
    'white_label_app': FeatureFlag(
      key: 'white_label_app',
      nameAr: 'تطبيق بعلامة تجارية',
      nameEn: 'White-Label App',
      descriptionAr: 'تطبيق مخصص بعلامتك التجارية',
      descriptionEn: 'Custom branded app',
      moduleId: ModuleId.teacherWhiteLabelParentApp,
      defaultEnabled: false,
    ),
    'custom_domain': FeatureFlag(
      key: 'custom_domain',
      nameAr: 'دومين خاص',
      nameEn: 'Custom Domain',
      descriptionAr: 'دومين مخصص للتطبيق',
      descriptionEn: 'Custom domain for app',
      moduleId: ModuleId.teacherWhiteLabelParentApp,
      defaultEnabled: false,
    ),
    'branded_emails': FeatureFlag(
      key: 'branded_emails',
      nameAr: 'إيميلات بعلامتك',
      nameEn: 'Branded Emails',
      descriptionAr: 'إيميلات @yourbrand.com',
      descriptionEn: '@yourbrand.com emails',
      moduleId: ModuleId.teacherWhiteLabelParentApp,
      defaultEnabled: false,
    ),

    // Center flags
    'hall_management': FeatureFlag(
      key: 'hall_management',
      nameAr: 'إدارة القاعات',
      nameEn: 'Hall Management',
      descriptionAr: 'إضافة/إدارة القاعات',
      descriptionEn: 'Add/manage halls',
      moduleId: ModuleId.centerCore,
      defaultEnabled: true,
    ),
    'teacher_management': FeatureFlag(
      key: 'teacher_management',
      nameAr: 'إدارة المعلمين',
      nameEn: 'Teacher Management',
      descriptionAr: 'إضافة/إدارة المعلمين',
      descriptionEn: 'Add/manage teachers',
      moduleId: ModuleId.centerCore,
      defaultEnabled: true,
    ),
    'unlimited_halls': FeatureFlag(
      key: 'unlimited_halls',
      nameAr: 'قاعات غير محدودة',
      nameEn: 'Unlimited Halls',
      descriptionAr: 'عدد غير محدود من القاعات',
      descriptionEn: 'Unlimited number of halls',
      moduleId: ModuleId.centerAttendancePro,
      defaultEnabled: false,
    ),
    'unlimited_teachers': FeatureFlag(
      key: 'unlimited_teachers',
      nameAr: 'معلمين غير محدود',
      nameEn: 'Unlimited Teachers',
      descriptionAr: 'عدد غير محدود من المعلمين',
      descriptionEn: 'Unlimited number of teachers',
      moduleId: ModuleId.centerAttendancePro,
      defaultEnabled: false,
    ),
    'daily_reports': FeatureFlag(
      key: 'daily_reports',
      nameAr: 'تقارير يومية',
      nameEn: 'Daily Reports',
      descriptionAr: 'تقارير حضور يومية مفصلة',
      descriptionEn: 'Detailed daily attendance reports',
      moduleId: ModuleId.centerAttendancePro,
      defaultEnabled: false,
    ),
    'absence_alerts': FeatureFlag(
      key: 'absence_alerts',
      nameAr: 'تنبيهات الغياب',
      nameEn: 'Absence Alerts',
      descriptionAr: 'تنبيهات فورية للغياب',
      descriptionEn: 'Instant absence alerts',
      moduleId: ModuleId.centerAttendancePro,
      defaultEnabled: false,
    ),
    'attendance_export': FeatureFlag(
      key: 'attendance_export',
      nameAr: 'تصدير الحضور',
      nameEn: 'Attendance Export',
      descriptionAr: 'تصدير بيانات الحضور',
      descriptionEn: 'Export attendance data',
      moduleId: ModuleId.centerAttendancePro,
      defaultEnabled: false,
    ),
    'flexible_rules': FeatureFlag(
      key: 'flexible_rules',
      nameAr: 'قواعد مرنة',
      nameEn: 'Flexible Rules',
      descriptionAr: 'قواعد تسوية قابلة للتخصيص',
      descriptionEn: 'Customizable settlement rules',
      moduleId: ModuleId.centerSettlementEngine,
      defaultEnabled: false,
    ),
    'immutable_ledger': FeatureFlag(
      key: 'immutable_ledger',
      nameAr: 'سجل غير قابل للتغيير',
      nameEn: 'Immutable Ledger',
      descriptionAr: 'سجل مالي لا يمكن تعديله',
      descriptionEn: 'Tamper-proof financial ledger',
      moduleId: ModuleId.centerSettlementEngine,
      defaultEnabled: false,
    ),
    'one_tap_settlement': FeatureFlag(
      key: 'one_tap_settlement',
      nameAr: 'تسوية بضغطة واحدة',
      nameEn: 'One-Tap Settlement',
      descriptionAr: 'تسوية يومية في 11 مساءً بضغطة واحدة',
      descriptionEn: 'Daily 11 PM settlement with one tap',
      moduleId: ModuleId.centerSettlementEngine,
      defaultEnabled: false,
    ),
    'offline_fallback': FeatureFlag(
      key: 'offline_fallback',
      nameAr: 'وضع عدم الاتصال',
      nameEn: 'Offline Fallback',
      descriptionAr: 'التسوية تعمل بدون إنترنت',
      descriptionEn: 'Settlement works offline',
      moduleId: ModuleId.centerSettlementEngine,
      defaultEnabled: false,
    ),
    'parent_topup': FeatureFlag(
      key: 'parent_topup',
      nameAr: 'شحن ولي الأمر',
      nameEn: 'Parent Top-up',
      descriptionAr: 'ولي الأمر يشحن المحفظة',
      descriptionEn: 'Parent tops up wallet',
      moduleId: ModuleId.centerFamilyWallet,
      defaultEnabled: false,
    ),
    'teacher_payout': FeatureFlag(
      key: 'teacher_payout',
      nameAr: 'صرف المعلم',
      nameEn: 'Teacher Payout',
      descriptionAr: 'صرف مستحقات المعلم من المحفظة',
      descriptionEn: 'Pay teacher dues from wallet',
      moduleId: ModuleId.centerFamilyWallet,
      defaultEnabled: false,
    ),
    'unified_statement': FeatureFlag(
      key: 'unified_statement',
      nameAr: 'كشف موحد',
      nameEn: 'Unified Statement',
      descriptionAr: 'كشف حساب موحد للعائلة',
      descriptionEn: 'Unified family statement',
      moduleId: ModuleId.centerFamilyWallet,
      defaultEnabled: false,
    ),
    'teacher_schedule': FeatureFlag(
      key: 'teacher_schedule',
      nameAr: 'جدول المعلم',
      nameEn: 'Teacher Schedule',
      descriptionAr: 'المعلم يرى جدوله في البوابة',
      descriptionEn: 'Teacher sees schedule in portal',
      moduleId: ModuleId.centerTeacherPortal,
      defaultEnabled: false,
    ),
    'teacher_dues': FeatureFlag(
      key: 'teacher_dues',
      nameAr: 'مستحقات المعلم',
      nameEn: 'Teacher Dues',
      descriptionAr: 'المعلم يرى مستحقاته',
      descriptionEn: 'Teacher sees their dues',
      moduleId: ModuleId.centerTeacherPortal,
      defaultEnabled: false,
    ),
    'teacher_students': FeatureFlag(
      key: 'teacher_students',
      nameAr: 'طلاب المعلم',
      nameEn: 'Teacher Students',
      descriptionAr: 'المعلم يرى طلابه',
      descriptionEn: 'Teacher sees their students',
      moduleId: ModuleId.centerTeacherPortal,
      defaultEnabled: false,
    ),
    'content_upload': FeatureFlag(
      key: 'content_upload',
      nameAr: 'رفع المحتوى',
      nameEn: 'Content Upload',
      descriptionAr: 'المعلم يرفع محتوى تعليمي',
      descriptionEn: 'Teacher uploads educational content',
      moduleId: ModuleId.centerTeacherPortal,
      defaultEnabled: false,
    ),
    'quick_confirm': FeatureFlag(
      key: 'quick_confirm',
      nameAr: 'تأكيد سريع',
      nameEn: 'Quick Confirm',
      descriptionAr: 'تأكيد الحضور/المستحقات < 10 ثواني',
      descriptionEn: 'Confirm attendance/dues < 10 seconds',
      moduleId: ModuleId.centerTeacherPortal,
      defaultEnabled: false,
    ),
    'daily_challenges': FeatureFlag(
      key: 'daily_challenges',
      nameAr: 'تحديات يومية',
      nameEn: 'Daily Challenges',
      descriptionAr: 'تحديات يومية للطلاب',
      descriptionEn: 'Daily challenges for students',
      moduleId: ModuleId.centerStudentEngagement,
      defaultEnabled: false,
    ),
    'streaks': FeatureFlag(
      key: 'streaks',
      nameAr: 'سلاسل الحضور',
      nameEn: 'Streaks',
      descriptionAr: 'تتبع سلاسل الحضور المتتالية',
      descriptionEn: 'Track consecutive attendance streaks',
      moduleId: ModuleId.centerStudentEngagement,
      defaultEnabled: false,
    ),
    'ai_remedial': FeatureFlag(
      key: 'ai_remedial',
      nameAr: 'تمارين علاجية ذكية',
      nameEn: 'AI Remedial',
      descriptionAr: 'تمارين علاجية بالذكاء الاصطناعي',
      descriptionEn: 'AI-generated remedial exercises',
      moduleId: ModuleId.centerStudentEngagement,
      defaultEnabled: false,
    ),
    'whatsapp_reports': FeatureFlag(
      key: 'whatsapp_reports',
      nameAr: 'تقارير واتساب',
      nameEn: 'WhatsApp Reports',
      descriptionAr: 'تقارير أداء ترسل على واتساب للأهل',
      descriptionEn: 'Performance reports sent via WhatsApp to parents',
      moduleId: ModuleId.centerStudentEngagement,
      defaultEnabled: false,
    ),
    'multi_branch': FeatureFlag(
      key: 'multi_branch',
      nameAr: 'متعدد الفروع',
      nameEn: 'Multi-Branch',
      descriptionAr: 'إدارة فروع متعددة',
      descriptionEn: 'Manage multiple branches',
      moduleId: ModuleId.centerMultiBranch,
      defaultEnabled: false,
    ),
    'unified_inventory': FeatureFlag(
      key: 'unified_inventory',
      nameAr: 'مخزون موحد',
      nameEn: 'Unified Inventory',
      descriptionAr: 'مخزون مشترك بين الفروع',
      descriptionEn: 'Shared inventory across branches',
      moduleId: ModuleId.centerMultiBranch,
      defaultEnabled: false,
    ),
    'cross_branch_transfer': FeatureFlag(
      key: 'cross_branch_transfer',
      nameAr: 'تحويلات بين الفروع',
      nameEn: 'Cross-Branch Transfer',
      descriptionAr: 'نقل طلاب/معلمين بين الفروع',
      descriptionEn: 'Transfer students/teachers between branches',
      moduleId: ModuleId.centerMultiBranch,
      defaultEnabled: false,
    ),
    'unified_reports': FeatureFlag(
      key: 'unified_reports',
      nameAr: 'تقارير موحدة',
      nameEn: 'Unified Reports',
      descriptionAr: 'تقارير موحدة لجميع الفروع',
      descriptionEn: 'Unified reports for all branches',
      moduleId: ModuleId.centerMultiBranch,
      defaultEnabled: false,
    ),
    'live_heatmap': FeatureFlag(
      key: 'live_heatmap',
      nameAr: 'خريطة حرارية حية',
      nameEn: 'Live Heatmap',
      descriptionAr: 'خريطة حرارية مباشرة للنشاط',
      descriptionEn: 'Real-time activity heatmap',
      moduleId: ModuleId.centerGodModeRadar,
      defaultEnabled: false,
    ),
    'kill_switches': FeatureFlag(
      key: 'kill_switches',
      nameAr: 'مفاتيح قتل',
      nameEn: 'Kill Switches',
      descriptionAr: 'إيقاف فوري لأي عملية',
      descriptionEn: 'Instant stop of any operation',
      moduleId: ModuleId.centerGodModeRadar,
      defaultEnabled: false,
    ),
    'ghost_impersonation': FeatureFlag(
      key: 'ghost_impersonation',
      nameAr: 'انتحال شبح',
      nameEn: 'Ghost Impersonation',
      descriptionAr: 'دخول كأي مستخدم للتصحيح',
      descriptionEn: 'Login as any user for debugging',
      moduleId: ModuleId.centerGodModeRadar,
      defaultEnabled: false,
    ),
    'competitor_intel': FeatureFlag(
      key: 'competitor_intel',
      nameAr: 'استخبارات منافسين',
      nameEn: 'Competitor Intel',
      descriptionAr: 'معلومات عن المنافسين في المنطقة',
      descriptionEn: 'Competitor information in area',
      moduleId: ModuleId.centerGodModeRadar,
      defaultEnabled: false,
    ),
    'api_access': FeatureFlag(
      key: 'api_access',
      nameAr: 'وصول API',
      nameEn: 'API Access',
      descriptionAr: 'API للتكامل مع أنظمة خارجية',
      descriptionEn: 'API for external system integration',
      moduleId: ModuleId.centerCustomIntegrations,
      defaultEnabled: false,
    ),
    'webhooks': FeatureFlag(
      key: 'webhooks',
      nameAr: 'Webhooks',
      nameEn: 'Webhooks',
      descriptionAr: 'إشعارات فورية للأحداث',
      descriptionEn: 'Real-time event notifications',
      moduleId: ModuleId.centerCustomIntegrations,
      defaultEnabled: false,
    ),
    'erp_sync': FeatureFlag(
      key: 'erp_sync',
      nameAr: 'مزامنة ERP',
      nameEn: 'ERP Sync',
      descriptionAr: 'مزامنة مع أنظمة ERP',
      descriptionEn: 'Sync with ERP systems',
      moduleId: ModuleId.centerCustomIntegrations,
      defaultEnabled: false,
    ),
    'scheduled_exports': FeatureFlag(
      key: 'scheduled_exports',
      nameAr: 'تصدير مجدول',
      nameEn: 'Scheduled Exports',
      descriptionAr: 'تصدير بيانات تلقائي مجدول',
      descriptionEn: 'Automated scheduled data exports',
      moduleId: ModuleId.centerCustomIntegrations,
      defaultEnabled: false,
    ),
    'sso': FeatureFlag(
      key: 'sso',
      nameAr: 'تسجيل دخول موحد',
      nameEn: 'SSO',
      descriptionAr: 'Single Sign-On',
      descriptionEn: 'Single Sign-On',
      moduleId: ModuleId.centerCustomIntegrations,
      defaultEnabled: false,
    ),
    'full_customization': FeatureFlag(
      key: 'full_customization',
      nameAr: 'تخصيص كامل',
      nameEn: 'Full Customization',
      descriptionAr: 'تخصيص كامل للعلامة التجارية',
      descriptionEn: 'Full brand customization',
      moduleId: ModuleId.centerWhiteLabelEverything,
      defaultEnabled: false,
    ),
  };

  static FeatureFlag? getFlag(String key) => allFlags[key];

  static List<FeatureFlag> getFlagsForModule(ModuleId moduleId) {
    return allFlags.values.where((f) => f.moduleId == moduleId).toList();
  }

  static Map<String, FeatureFlag> getAllFlags() => allFlags;
}

class FeatureFlag {
  final String key;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final ModuleId moduleId;
  final bool defaultEnabled;

  const FeatureFlag({
    required this.key,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.moduleId,
    required this.defaultEnabled,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'nameAr': nameAr,
    'nameEn': nameEn,
    'descriptionAr': descriptionAr,
    'descriptionEn': descriptionEn,
    'moduleId': moduleId.name,
    'defaultEnabled': defaultEnabled,
  };
}

/// Account subscription state
class AccountSubscription {
  final String accountId;
  final AccountType accountType;
  final Set<ModuleId> activeModules;
  final BillingCycle billingCycle;
  final DateTime? expiresAt;
  final String? promoCode;
  final Map<String, int> usageCounters; // meterKey -> count
  final Map<String, bool> featureOverrides; // flagKey -> bool (manual override)
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountSubscription({
    required this.accountId,
    required this.accountType,
    required this.activeModules,
    required this.billingCycle,
    this.expiresAt,
    this.promoCode,
    required this.usageCounters,
    required this.featureOverrides,
    required this.createdAt,
    required this.updatedAt,
  });

  bool hasModule(ModuleId module) => activeModules.contains(module);

  bool isFeatureEnabled(String flagKey) {
    // Check override first
    if (featureOverrides.containsKey(flagKey)) {
      return featureOverrides[flagKey]!;
    }
    // Check if any active module enables this flag
    final flag = FeatureFlags.getFlag(flagKey);
    if (flag == null) return false;
    return activeModules.contains(flag.moduleId);
  }

  int getUsage(String meterKey) => usageCounters[meterKey] ?? 0;

  double calculateMonthlyCost() {
    double total = 0;
    for (final moduleId in activeModules) {
      final module = PricingCatalog.getModule(moduleId);
      if (module != null && module.priceMonthlyEgp > 0) {
        total += module.getPrice(billingCycle).toDouble();
      }
    }
    // Add usage-based costs
    for (final entry in usageCounters.entries) {
      final price = UsageMetering.getPrice(entry.key);
      if (price != null) {
        total += price.calculateCost(entry.value);
      }
    }
    return total;
  }

  Map<String, dynamic> toJson() => {
    'accountId': accountId,
    'accountType': accountType.name,
    'activeModules': activeModules.map((e) => e.name).toList(),
    'billingCycle': billingCycle.name,
    'expiresAt': expiresAt?.toIso8601String(),
    'promoCode': promoCode,
    'usageCounters': usageCounters,
    'featureOverrides': featureOverrides,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AccountSubscription.fromJson(Map<String, dynamic> json) => AccountSubscription(
    accountId: json['accountId'] as String,
    accountType: AccountType.values.firstWhere((e) => e.name == json['accountType']),
    activeModules: (json['activeModules'] as List).map((e) => ModuleId.values.firstWhere((m) => m.name == e)).toSet(),
    billingCycle: BillingCycle.values.firstWhere((e) => e.name == json['billingCycle']),
    expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
    promoCode: json['promoCode'] as String?,
    usageCounters: Map<String, int>.from(json['usageCounters'] as Map),
    featureOverrides: Map<String, bool>.from(json['featureOverrides'] as Map),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  AccountSubscription copyWith({
    String? accountId,
    AccountType? accountType,
    Set<ModuleId>? activeModules,
    BillingCycle? billingCycle,
    DateTime? expiresAt,
    String? promoCode,
    Map<String, int>? usageCounters,
    Map<String, bool>? featureOverrides,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AccountSubscription(
    accountId: accountId ?? this.accountId,
    accountType: accountType ?? this.accountType,
    activeModules: activeModules ?? this.activeModules,
    billingCycle: billingCycle ?? this.billingCycle,
    expiresAt: expiresAt ?? this.expiresAt,
    promoCode: promoCode ?? this.promoCode,
    usageCounters: usageCounters ?? this.usageCounters,
    featureOverrides: featureOverrides ?? this.featureOverrides,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
  );
}