import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:kashkool_core/kashkool_core.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../providers/installment_plan_provider.dart';

/// Student installment plan tracking screen.
///
/// Shows the active installment plan, remaining balance, payment percentage,
/// and list of individual installments with due dates and status.
class InstallmentPlanScreen extends ConsumerWidget {
  const InstallmentPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(installmentPlansProvider);
    final locale = ref.watch(currentLocaleProvider);
    final rtl = locale == 'ar';

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: Text(AppStrings.translate('lblInstallmentPlan', locale)),
          backgroundColor: const Color(0xFF1E293B),
        ),
        body: plans.when(
          data: (plansList) {
            if (plansList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.payment_outlined,
                      size: 64,
                      color: Colors.white38,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.translate('errNoInstallmentPlan', locale),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: Text(AppStrings.translate('btnContactCenter', locale)),
                    ),
                  ],
                ),
              );
            }

            final plan = plansList.first;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Plan summary card
                  FloatingGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.translate('lblTotalAmount', locale),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                formatPiasters(plan.totalAmountPiasters),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.translate('lblPaidAmount', locale),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                formatPiasters(plan.paidAmountPiasters),
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.translate('lblRemainingAmount', locale),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                formatPiasters(plan.remainingPiasters),
                                style: TextStyle(
                                  color: plan.remainingPiasters == 0
                                      ? const Color(0xFF10B981)
                                      : Colors.amberAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Progress bar
                          LinearProgressIndicator(
                            value: plan.paidPercentage / 100,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${plan.paidPercentage.toStringAsFixed(0)}% ${AppStrings.translate('lblPaidPercentage', locale)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.repeat,
                                color: Colors.cyanAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${plan.numberOfInstallments} ${AppStrings.translate('lblInstallments', locale)}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                formatPiasters(plan.installmentAmountPiasters),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${AppStrings.translate('lblFrom', locale)} ${_formatDate(plan.startDate)} ${AppStrings.translate('lblTo', locale)} ${_formatDate(plan.endDate)}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(plan.status)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _statusLabel(plan.status, locale),
                                  style: TextStyle(
                                    color: _statusColor(plan.status),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Installments list header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.translate('lblInstallmentsList', locale),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (plan.status == InstallmentPlanStatus.active)
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(
                            AppStrings.translate('lblAddInstallment', locale),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Installments list (load per plan)
                  if (plan.id.isNotEmpty)
                    InstallmentPaymentsList(planId: plan.id),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF00F5D4)),
          ),
          error: (_, __) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white38,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.translate('errLoadInstallments', locale),
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(installmentPlansProvider),
                  icon: const Icon(Icons.refresh),
                  label: Text(AppStrings.translate('btnRetry', locale)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _statusColor(InstallmentPlanStatus status) {
    switch (status) {
      case InstallmentPlanStatus.completed:
        return const Color(0xFF10B981);
      case InstallmentPlanStatus.active:
        return const Color(0xFF00F5D4);
      case InstallmentPlanStatus.overdue:
        return Colors.amberAccent;
      case InstallmentPlanStatus.cancelled:
        return Colors.redAccent;
    }
  }

  String _statusLabel(InstallmentPlanStatus status, String locale) {
    if (locale == 'ar') {
      switch (status) {
        case InstallmentPlanStatus.completed:
          return 'مكتمل';
        case InstallmentPlanStatus.active:
          return 'نشط';
        case InstallmentPlanStatus.overdue:
          return 'متأخر';
        case InstallmentPlanStatus.cancelled:
          return 'ملغي';
      }
    } else {
      switch (status) {
        case InstallmentPlanStatus.completed:
          return 'Completed';
        case InstallmentPlanStatus.active:
          return 'Active';
        case InstallmentPlanStatus.overdue:
          return 'Overdue';
        case InstallmentPlanStatus.cancelled:
          return 'Cancelled';
      }
    }
    return status.toString().split('.').last;
  }
}

/// Individual installment payments list for a specific plan.
class InstallmentPaymentsList extends ConsumerWidget {
  final String planId;
  const InstallmentPaymentsList({super.key, required this.planId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(installmentPaymentsProvider(planId));
    final locale = ref.watch(currentLocaleProvider);
    final rtl = locale == 'ar';

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: payments.when(
        data: (list) {
          if (list.isEmpty) {
            return const SizedBox.shrink();
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final p = list[index];
              return _InstallmentTile(payment: p, locale: locale);
            },
          );
        },
        loading: () => const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

/// Single installment row.
class _InstallmentTile extends ConsumerWidget {
  final InstallmentPaymentModel payment;
  final String locale;
  const _InstallmentTile({required this.payment, required this.locale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaid = payment.status == InstallmentPaymentStatus.paid;
    final isOverdue = payment.isOverdue;

    return Card(
      color: const Color(0xFF121212),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPaid
                ? const Color(0xFF10B981).withValues(alpha: 0.2)
                : isOverdue
                    ? Colors.amberAccent.withValues(alpha: 0.2)
                    : Colors.cyanAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isPaid ? Icons.check : Icons.schedule,
            color: isPaid
                ? const Color(0xFF10B981)
                : isOverdue
                    ? Colors.amberAccent
                    : const Color(0xFF00F5D4),
            size: 20,
          ),
        ),
        title: Text(
          '${AppStrings.translate('lblInstallment', locale)} ${payment.dueDate.day.toString().padLeft(2, '0')}/${payment.dueDate.month.toString().padLeft(2, '0')}/${payment.dueDate.year}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${AppStrings.translate('lblAmount', locale)}: ${formatPiasters(payment.amountPiasters)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            if (payment.paidDate != null)
              Text(
                '${AppStrings.translate('lblPaidOn', locale)} ${_formatDate(payment.paidDate!)}',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11,
                ),
              )
            else if (isOverdue)
              Text(
                AppStrings.translate('lblOverdue', locale),
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                AppStrings.translate('lblPending', locale),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(payment.status).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _statusLabel(payment.status, locale),
            style: TextStyle(
              color: _statusColor(payment.status),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _statusColor(InstallmentPaymentStatus status) {
    switch (status) {
      case InstallmentPaymentStatus.paid:
        return const Color(0xFF10B981);
      case InstallmentPaymentStatus.pending:
        return const Color(0xFF00F5D4);
      case InstallmentPaymentStatus.overdue:
        return Colors.amberAccent;
      case InstallmentPaymentStatus.cancelled:
        return Colors.redAccent;
    }
  }

  String _statusLabel(InstallmentPaymentStatus status, String locale) {
    if (locale == 'ar') {
      switch (status) {
        case InstallmentPaymentStatus.paid:
          return 'مدفوع';
        case InstallmentPaymentStatus.pending:
          return 'قيد الانتظار';
        case InstallmentPaymentStatus.overdue:
          return 'متأخر';
        case InstallmentPaymentStatus.cancelled:
          return 'ملغي';
      }
    } else {
      switch (status) {
        case InstallmentPaymentStatus.paid:
          return 'Paid';
        case InstallmentPaymentStatus.pending:
          return 'Pending';
        case InstallmentPaymentStatus.overdue:
          return 'Overdue';
        case InstallmentPaymentStatus.cancelled:
          return 'Cancelled';
      }
    }
    return status.toString().split('.').last;
  }
}
