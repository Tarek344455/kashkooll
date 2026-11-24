// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashkool_core/kashkool_core.dart'
    show formatPiasters, PaymentSubmissionStatus;

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../../billing/providers/payment_submission_provider.dart';

/// Student payment tracking: real-time status of receipt submissions with
/// Drift-cached fallback and full AR/EN RTL parity. Four UI states handled.
class StudentPaymentTrackingScreen extends ConsumerWidget {
  const StudentPaymentTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissions = ref.watch(paymentSubmissionsProvider);
    final locale = ref.watch(currentLocaleProvider);
    final rtl = locale == 'ar';

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: Text(AppStrings.translate('lblPaymentTracking', locale)),
          backgroundColor: const Color(0xFF1E293B),
        ),
        body: submissions.when(
          data: (list) {
            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt_outlined,
                        size: 64, color: Colors.white38),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.translate('errNoSubmissions', locale),
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.refresh(paymentSubmissionsProvider),
                      icon: const Icon(Icons.refresh),
                      label: Text(AppStrings.translate('btnRetry', locale)),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final s = list[index];
                final Color statusColor;
                final IconData statusIcon;
                final String statusText;
                switch (s.status) {
                  case PaymentSubmissionStatus.pending:
                    statusColor = Colors.amberAccent;
                    statusIcon = Icons.access_time;
                    statusText = AppStrings.translate('statusPending', locale);
                    break;
                  case PaymentSubmissionStatus.approved:
                    statusColor = const Color(0xFF10B981);
                    statusIcon = Icons.check_circle;
                    statusText = AppStrings.translate('statusApproved', locale);
                    break;
                  case PaymentSubmissionStatus.rejected:
                    statusColor = Colors.redAccent;
                    statusIcon = Icons.cancel;
                    statusText = AppStrings.translate('statusRejected', locale);
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FloatingGlassCard(
                    borderRadius: 14,
                    glowColor: statusColor,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor.withValues(alpha: 0.15),
                          ),
                          child: Icon(statusIcon, color: statusColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${AppStrings.translate('lblChannel', locale)}: ',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${AppStrings.translate('lblAmount', locale)}: ${formatPiasters(s.amountPiasters)}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${AppStrings.translate('lblReference', locale)}: ${s.senderReference}',
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 11),
                              ),
                              if (s.rejectionReason != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.redAccent, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${AppStrings.translate('lblReason', locale)}: ${s.rejectionReason}',
                                        style: const TextStyle(
                                            color: Colors.white60, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                s.createdAt.toLocal().toString().substring(0, 16),
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.white38, size: 64),
                const SizedBox(height: 16),
                Text(
                  AppStrings.translate('errLoadSubmissions', locale),
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(paymentSubmissionsProvider),
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
}

String formatPiasters2(int piasters) {
  final egp = piasters / 100.0;
  return egp.toStringAsFixed(2);
}
