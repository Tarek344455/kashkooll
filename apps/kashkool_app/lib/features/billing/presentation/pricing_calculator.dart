/// Pricing Calculator Component - Real-time price calculation as modules selected
/// Works on Flutter Web (landing) and Mobile (app)

library pricing_calculator;

// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unnecessary_non_null_assertion, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashkool_core/kashkool_core.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../../core/theme/app_theme.dart';

/// Main pricing calculator widget
class PricingCalculator extends ConsumerStatefulWidget {
  final AccountType accountType;
  final Set<ModuleId> initiallySelectedModules;
  final BillingCycle initialBillingCycle;
  final String? initialPromoCode;
  final ValueChanged<PricingCalculatorResult>? onChanged;
  final bool showPromoField;
  final bool compact;

  const PricingCalculator({
    super.key,
    required this.accountType,
    this.initiallySelectedModules = const {},
    this.initialBillingCycle = BillingCycle.monthly,
    this.initialPromoCode,
    this.onChanged,
    this.showPromoField = true,
    this.compact = false,
  });

  @override
  ConsumerState<PricingCalculator> createState() => _PricingCalculatorState();
}

class _PricingCalculatorState extends ConsumerState<PricingCalculator> {
  late Set<ModuleId> _selectedModules;
  late BillingCycle _billingCycle;
  String? _promoCode;
  PromoCode? _validPromo;
  String? _promoError;

  @override
  void initState() {
    super.initState();
    _selectedModules = Set.from(widget.initiallySelectedModules);
    _billingCycle = widget.initialBillingCycle;
    _promoCode = widget.initialPromoCode;
    if (_promoCode != null) {
      _validatePromo();
    }
    _notifyChange();
  }

  void _validatePromo() {
    if (_promoCode == null || _promoCode!.isEmpty) {
      _validPromo = null;
      _promoError = null;
      return;
    }

    final promo = PromoCatalog.getPromo(_promoCode!);
    if (promo == null) {
      _validPromo = null;
      _promoError = 'كود غير صحيح';
      return;
    }

    if (!promo.isValid(accountType: widget.accountType)) {
      _validPromo = null;
      _promoError = 'الكود غير صالح لهذا النوع من الحساب';
      return;
    }

    // Check if applicable to selected modules
    if (promo.applicableModules != null && _selectedModules.isNotEmpty) {
      final hasApplicableModule = _selectedModules.any((m) => promo.applicableModules!.contains(m));
      if (!hasApplicableModule && promo.type != PromoType.freeMonths && promo.type != PromoType.percentOff) {
        _validPromo = null;
        _promoError = 'الكود يتطلب وحدات محددة';
        return;
      }
    }

    _validPromo = promo;
    _promoError = null;
  }

  void _toggleModule(ModuleId moduleId) {
    setState(() {
      if (_selectedModules.contains(moduleId)) {
        _selectedModules.remove(moduleId);
      } else {
        _selectedModules.add(moduleId);
      }
    });
    _validatePromo();
    _notifyChange();
  }

  void _setBillingCycle(BillingCycle cycle) {
    setState(() => _billingCycle = cycle);
    _notifyChange();
  }

  void _onPromoChanged(String value) {
    setState(() => _promoCode = value.isEmpty ? null : value);
    _validatePromo();
    _notifyChange();
  }

  void _notifyChange() {
    if (widget.onChanged != null) {
      widget.onChanged!(PricingCalculatorResult(
        selectedModules: Set.from(_selectedModules),
        billingCycle: _billingCycle,
        promoCode: _promoCode,
        validPromo: _validPromo,
        monthlyTotal: _calculateMonthlyTotal(),
        yearlyTotal: _calculateYearlyTotal(),
        effectiveMonthly: _calculateEffectiveMonthly(),
        savings: _calculateSavings(),
      ));
    }
  }

  double _calculateMonthlyTotal() {
    double total = 0;
    for (final moduleId in _selectedModules) {
      final module = PricingCatalog.getModule(moduleId);
      if (module != null) {
        total += module.priceMonthlyEgp.toDouble();
      }
    }
    return total;
  }

  double _calculateYearlyTotal() {
    double total = 0;
    for (final moduleId in _selectedModules) {
      final module = PricingCatalog.getModule(moduleId);
      if (module != null) {
        total += module.priceYearlyEgp.toDouble();
      }
    }
    return total;
  }

  double _calculateEffectiveMonthly() {
    double base = _billingCycle == BillingCycle.monthly ? _calculateMonthlyTotal() : _calculateYearlyTotal() / 12;

    if (_validPromo != null) {
      switch (_validPromo!.type) {
        case PromoType.freeMonths:
          // Handled in savings
          break;
        case PromoType.percentOff:
          base *= (1 - _validPromo!.value / 100);
          break;
        case PromoType.bundleDiscount:
          // Applied to 2nd+ module - handled in savings
          break;
        case PromoType.freeModule:
          // One module free - handled in savings
          break;
        case PromoType.referralCredit:
          // Handled in savings
          break;
      }
    }

    return base;
  }

  double _calculateSavings() {
    if (_validPromo == null) return 0;

    double baseMonthly = _calculateMonthlyTotal();
    double baseYearly = _calculateYearlyTotal();

    switch (_validPromo!.type) {
      case PromoType.freeMonths:
        return baseMonthly * _validPromo!.value;
      case PromoType.percentOff:
        return (_billingCycle == BillingCycle.monthly ? baseMonthly : baseYearly / 12) * (_validPromo!.value / 100);
      case PromoType.bundleDiscount:
        if (_selectedModules.length >= 2) {
          // 50% off the cheapest paid module (after the first)
          final paidModules = _selectedModules
              .map((m) => PricingCatalog.getModule(m))
              .where((m) => m != null && m!.priceMonthlyEgp > 0)
              .map((m) => m!.priceMonthlyEgp)
              .toList()
            ..sort();
          if (paidModules.length >= 2) {
            return paidModules[1] * 0.5; // 50% off 2nd cheapest
          }
        }
        return 0;
      case PromoType.freeModule:
        final freeModuleId = ModuleId.values.firstWhere(
          (m) => m.name == _validPromo!.value,
          orElse: () => ModuleId.teacherCore,
        );
        final freeModule = PricingCatalog.getModule(freeModuleId);
        return freeModule?.priceMonthlyEgp.toDouble() ?? 0;
      case PromoType.referralCredit:
        return baseMonthly * _validPromo!.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = PricingCatalog.getModulesForAccountType(widget.accountType);
    final paidModules = modules.where((m) => m.priceMonthlyEgp > 0).toList();
    final freeModules = modules.where((m) => m.priceMonthlyEgp == 0).toList();

    return FloatingGlassCard(
      padding: widget.compact ? const EdgeInsets.all(16) : const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                widget.accountType == AccountType.teacher ? Icons.person : Icons.business,
                color: AppTheme.neonCyan,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.accountType == AccountType.teacher ? 'حاسبة أسعار المعلم' : 'حاسبة أسعار المركز',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.accountType == AccountType.teacher
                          ? 'اختر الوحدات التي تحتاجها - ادفع فقط لما تستخدمه'
                          : 'اختر وحدات المركز - تسعير مرن لكل احتياج',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Billing Cycle Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                _BillingCycleButton(
                  label: 'شهري',
                  cycle: BillingCycle.monthly,
                  selected: _billingCycle == BillingCycle.monthly,
                  onTap: () => _setBillingCycle(BillingCycle.monthly),
                ),
                _BillingCycleButton(
                  label: 'سنوي (وفر 17%)',
                  cycle: BillingCycle.yearly,
                  selected: _billingCycle == BillingCycle.yearly,
                  onTap: () => _setBillingCycle(BillingCycle.yearly),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Free tier modules (always included)
          if (freeModules.isNotEmpty) ...[
            Text(
              'مجاني دائماً',
              style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: freeModules.map((m) => _ModuleChip(
                module: m,
                selected: true,
                enabled: false,
                onTap: () {},
                billingCycle: _billingCycle,
                compact: widget.compact,
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Paid modules
          Text(
            'وحدات مدفوعة',
            style: TextStyle(color: AppTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          if (widget.compact)
            ...paidModules.map((m) => _ModuleRow(
              module: m,
              selected: _selectedModules.contains(m.id),
              onTap: () => _toggleModule(m.id),
              billingCycle: _billingCycle,
            ))
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: paidModules.map((m) => _ModuleCard(
                module: m,
                selected: _selectedModules.contains(m.id),
                onTap: () => _toggleModule(m.id),
                billingCycle: _billingCycle,
              )).toList(),
            ),

          // Promo code field
          if (widget.showPromoField) ...[
            const SizedBox(height: 20),
            _PromoCodeField(
              value: _promoCode ?? '',
              onChanged: _onPromoChanged,
              error: _promoError,
              validPromo: _validPromo,
            ),
          ],

          // Price Summary
          const SizedBox(height: 20),
          _PriceSummary(
            monthlyTotal: _calculateMonthlyTotal(),
            yearlyTotal: _calculateYearlyTotal(),
            effectiveMonthly: _calculateEffectiveMonthly(),
            savings: _calculateSavings(),
            billingCycle: _billingCycle,
            validPromo: _validPromo,
            selectedCount: _selectedModules.where((m) {
              final mod = PricingCatalog.getModule(m);
              return mod != null && mod.priceMonthlyEgp > 0;
            }).length,
            compact: widget.compact,
          ),
        ],
      ),
    );
  }
}

/// Result of pricing calculator
class PricingCalculatorResult {
  final Set<ModuleId> selectedModules;
  final BillingCycle billingCycle;
  final String? promoCode;
  final PromoCode? validPromo;
  final double monthlyTotal;
  final double yearlyTotal;
  final double effectiveMonthly;
  final double savings;

  const PricingCalculatorResult({
    required this.selectedModules,
    required this.billingCycle,
    this.promoCode,
    this.validPromo,
    required this.monthlyTotal,
    required this.yearlyTotal,
    required this.effectiveMonthly,
    required this.savings,
  });
}

/// Billing cycle toggle button
class _BillingCycleButton extends StatelessWidget {
  final String label;
  final BillingCycle cycle;
  final bool selected;
  final VoidCallback onTap;

  const _BillingCycleButton({
    required this.label,
    required this.cycle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? AppTheme.neonCyan.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppTheme.neonCyan : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppTheme.neonCyan : Colors.white70,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// Module chip (compact)
class _ModuleChip extends StatelessWidget {
  final ModulePricing module;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final BillingCycle billingCycle;
  final bool compact;

  const _ModuleChip({
    required this.module,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.billingCycle,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final price = module.getPrice(billingCycle);
    final isFree = price == 0;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isFree ? Colors.greenAccent.withValues(alpha: 0.2) : AppTheme.neonCyan.withValues(alpha: 0.2))
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? (isFree ? Colors.greenAccent : AppTheme.neonCyan)
                : Colors.white.withValues(alpha: 0.1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (module.isPopular)
              Icon(Icons.star, size: 14, color: Colors.amber),
            if (module.isPopular) const SizedBox(width: 4),
            Text(
              module.nameAr,
              style: TextStyle(
                color: selected ? (isFree ? Colors.greenAccent : AppTheme.neonCyan) : Colors.white,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            if (!isFree) ...[
              const SizedBox(width: 6),
              Text(
                module.getFormattedPrice(billingCycle),
                style: TextStyle(
                  color: selected ? AppTheme.neonCyan : Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'مجاني',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Module card (expanded)
class _ModuleCard extends StatelessWidget {
  final ModulePricing module;
  final bool selected;
  final VoidCallback onTap;
  final BillingCycle billingCycle;

  const _ModuleCard({
    required this.module,
    required this.selected,
    required this.onTap,
    required this.billingCycle,
  });

  @override
  Widget build(BuildContext context) {
    final price = module.getPrice(billingCycle);
    final isFree = price == 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.neonCyan.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.neonCyan : Colors.white.withValues(alpha: 0.1),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppTheme.neonCyan.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2)]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            module.nameAr,
                            style: TextStyle(
                              color: selected ? AppTheme.neonCyan : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (module.isPopular) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.star, size: 16, color: Colors.amber),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        module.descriptionAr,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isFree)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        module.getFormattedPrice(billingCycle),
                        style: TextStyle(
                          color: selected ? AppTheme.neonCyan : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (billingCycle == BillingCycle.yearly)
                        Text(
                          '${(module.priceYearlyEgp / 12).toStringAsFixed(0)} ج.م/شهر',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'مجاني',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: module.features.take(4).map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _featureNameAr(f),
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              )).toList(),
            ),
            if (module.features.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${module.features.length - 4} ميزة أخرى',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _featureNameAr(String feature) {
    const names = {
      'qr_checkin': 'QR Check-in',
      'basic_reports': 'تقارير أساسية',
      'student_management': 'إدارة الطلاب',
      'auto_settlement': 'تسوية تلقائية',
      'monthly_statement': 'كشف شهري',
      'pdf_export': 'تصدير PDF',
      'wallet_receive': 'استلام مدفوعات',
      'bank_withdraw': 'سحب بنكي',
      'auto_reconcile': 'مصالحة تلقائية',
      'watermark': 'علامة مائية',
      'screenshot_block': 'منع سكرينشوت',
      'leak_trace': 'تتبع تسريب',
      'video_encryption': 'تشفير فيديو',
      'ai_reports': 'تقارير ذكية',
      'remedial_suggestions': 'اقتراحات علاجية',
      'decline_alerts': 'تنبيهات تراجع',
      'multi_center_schedule': 'جدول متعدد المراكز',
      'data_isolation': 'عزل البيانات',
      'white_label_app': 'تطبيق بعلامة تجارية',
      'custom_domain': 'دومين خاص',
      'branded_emails': 'إيميلات بعلامتك',
      'hall_management': 'إدارة القاعات',
      'teacher_management': 'إدارة المعلمين',
      'unlimited_halls': 'قاعات غير محدودة',
      'unlimited_teachers': 'معلمين غير محدود',
      'daily_reports': 'تقارير يومية',
      'absence_alerts': 'تنبيهات غياب',
      'attendance_export': 'تصدير حضور',
      'flexible_rules': 'قواعد مرنة',
      'immutable_ledger': 'سجل غير قابل للتغيير',
      'one_tap_settlement': 'تسوية بضغطة واحدة',
      'offline_fallback': 'وضع عدم الاتصال',
      'parent_topup': 'شحن ولي الأمر',
      'teacher_payout': 'صرف المعلم',
      'unified_statement': 'كشف موحد',
      'teacher_schedule': 'جدول المعلم',
      'teacher_dues': 'مستحقات المعلم',
      'teacher_students': 'طلاب المعلم',
      'content_upload': 'رفع محتوى',
      'quick_confirm': 'تأكيد سريع',
      'daily_challenges': 'تحديات يومية',
      'streaks': 'سلاسل حضور',
      'ai_remedial': 'تمارين علاجية ذكية',
      'whatsapp_reports': 'تقارير واتساب',
      'multi_branch': 'متعدد الفروع',
      'unified_inventory': 'مخزون موحد',
      'cross_branch_transfer': 'تحويلات بين الفروع',
      'unified_reports': 'تقارير موحدة',
      'live_heatmap': 'خريطة حرارية حية',
      'kill_switches': 'مفاتيح قتل',
      'ghost_impersonation': 'انتحال شبح',
      'competitor_intel': 'استخبارات منافسين',
      'api_access': 'وصول API',
      'webhooks': 'Webhooks',
      'erp_sync': 'مزامنة ERP',
      'scheduled_exports': 'تصدير مجدول',
      'sso': 'تسجيل دخول موحد',
      'full_customization': 'تخصيص كامل',
    };
    return names[feature] ?? feature;
  }
}

/// Module row (compact list)
class _ModuleRow extends StatelessWidget {
  final ModulePricing module;
  final bool selected;
  final VoidCallback onTap;
  final BillingCycle billingCycle;

  const _ModuleRow({
    required this.module,
    required this.selected,
    required this.onTap,
    required this.billingCycle,
  });

  @override
  Widget build(BuildContext context) {
    final price = module.getPrice(billingCycle);
    final isFree = price == 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.neonCyan.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.neonCyan : Colors.white.withValues(alpha: 0.1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? AppTheme.neonCyan : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected ? AppTheme.neonCyan : Colors.white38,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        module.nameAr,
                        style: TextStyle(
                          color: selected ? AppTheme.neonCyan : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (module.isPopular) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.star, size: 14, color: Colors.amber),
                      ],
                    ],
                  ),
                  Text(
                    module.descriptionAr,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!isFree)
              Text(
                module.getFormattedPrice(billingCycle),
                style: TextStyle(
                  color: selected ? AppTheme.neonCyan : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'مجاني',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Promo code input field
class _PromoCodeField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String? error;
  final PromoCode? validPromo;

  const _PromoCodeField({
    required this.value,
    required this.onChanged,
    this.error,
    this.validPromo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: TextEditingController(text: value),
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'كود ترويجي (اختياري)',
            labelStyle: const TextStyle(color: Colors.white70),
            hintText: 'مثال: TRIAL3, BUNDLE2, YEARLY',
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(Icons.local_offer, color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: error != null ? Colors.redAccent : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: validPromo != null ? Colors.greenAccent : AppTheme.neonCyan,
                width: 2,
              ),
            ),
            errorText: error,
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
            suffixIcon: validPromo != null
                ? Icon(Icons.check_circle, color: Colors.greenAccent)
                : null,
          ),
        ),
        if (validPromo != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        validPromo!.nameAr,
                        style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        validPromo!.descriptionAr,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Price summary card
class _PriceSummary extends StatelessWidget {
  final double monthlyTotal;
  final double yearlyTotal;
  final double effectiveMonthly;
  final double savings;
  final BillingCycle billingCycle;
  final PromoCode? validPromo;
  final int selectedCount;
  final bool compact;

  const _PriceSummary({
    required this.monthlyTotal,
    required this.yearlyTotal,
    required this.effectiveMonthly,
    required this.savings,
    required this.billingCycle,
    this.validPromo,
    required this.selectedCount,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final showYearly = billingCycle == BillingCycle.yearly;
    final basePrice = showYearly ? yearlyTotal : monthlyTotal;
    final hasPromo = validPromo != null && savings > 0;

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.15),
            AppTheme.neonPurple.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Selected modules count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, color: AppTheme.neonCyan, size: 20),
              const SizedBox(width: 8),
              Text(
                '$selectedCount وحدة مختارة',
                style: TextStyle(color: AppTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Base price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                showYearly ? 'السعر السنوي' : 'السعر الشهري',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '${basePrice.toStringAsFixed(0)} ج.م',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          // Promo discount
          if (hasPromo) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.discount, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'خصم ${validPromo!.nameAr}',
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  '-${savings.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.2)),

          // Effective price
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                showYearly ? 'المجموع السنوي الفعلي' : 'المجموع الشهري الفعلي',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              Text(
                '${(showYearly ? effectiveMonthly * 12 : effectiveMonthly).toStringAsFixed(0)} ج.م',
                style: TextStyle(
                  color: AppTheme.neonCyan,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          if (showYearly) ...[
            const SizedBox(height: 4),
            Text(
              '≈ ${effectiveMonthly.toStringAsFixed(0)} ج.م/شهر (توفير ${(monthlyTotal - effectiveMonthly).toStringAsFixed(0)} ج.م/شهر)',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],

          if (hasPromo && validPromo!.type == PromoType.freeMonths) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.card_giftcard, color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${validPromo!.value} أشهر مجانية! القيمة: ${(savings).toStringAsFixed(0)} ج.م',
                      style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Landing page pricing section (for Flutter Web)
class PricingLandingSection extends ConsumerWidget {
  final AccountType accountType;
  final ValueChanged<PricingCalculatorResult>? onSelectionChanged;

  const PricingLandingSection({
    super.key,
    required this.accountType,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Text(
                accountType == AccountType.teacher ? 'أسعار المعلمين' : 'أسعار المراكز',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Space Grotesk',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                accountType == AccountType.teacher
                    ? 'ادفع فقط لما تحتاجه. لا حزم إجبارية، لا رسوم خفية.'
                    : 'وحدات مستقلة. اختر ما يناسب مركزك. توسع متى شئت.',
                style: const TextStyle(color: Colors.white70, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              PricingCalculator(
                accountType: accountType,
                onChanged: onSelectionChanged,
                compact: false,
              ),
              const SizedBox(height: 32),
              _TrustBadges(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustBadges extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 24,
      runSpacing: 16,
      children: [
        _Badge(icon: Icons.credit_card_off, text: 'لا بطاقة ائتمان للبدء'),
        _Badge(icon: Icons.cancel_schedule_send, text: 'إلغاء في أي وقت'),
        _Badge(icon: Icons.download, text: 'تصدير بياناتك بضغطة واحدة'),
        _Badge(icon: Icons.lock, text: 'سجل مالي غير قابل للتغيير'),
        _Badge(icon: Icons.wifi_off, text: 'يعمل بدون إنترنت'),
        _Badge(icon: Icons.support_agent, text: 'دعم عربي مباشر'),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Badge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.neonCyan, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}