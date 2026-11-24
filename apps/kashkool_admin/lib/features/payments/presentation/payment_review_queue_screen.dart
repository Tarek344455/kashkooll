// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashkool_core/kashkool_core.dart';

import '../providers/payment_review_provider.dart';

/// Super-admin payment receipt review queue.
///
/// Shows every pending receipt submission for the admin's tenant, previews
/// the signed receipt image, and allows 1-tap approval or structured
/// rejection (mandatory reason). All actions go through the atomic Supabase
/// RPCs (`approve_payment_submission` / `reject_payment_submission`).
class PaymentReviewQueueScreen extends ConsumerStatefulWidget {
  const PaymentReviewQueueScreen({super.key});

  @override
  ConsumerState<PaymentReviewQueueScreen> createState() =>
      _PaymentReviewQueueScreenState();
}

class _PaymentReviewQueueScreenState
    extends ConsumerState<PaymentReviewQueueScreen> {
  Future<void> _refresh() async {
    ref.invalidate(pendingSubmissionsProvider);
  }

  Future<void> _approve(PaymentSubmissionModel submission) async {
    await ref.read(paymentOpsServiceProvider).approve(submission.id);
    if (!mounted) return;
    ref.invalidate(pendingSubmissionsProvider);
  }

  Future<void> _reject(PaymentSubmissionModel submission) async {
    final reason = await _showRejectDialog(submission);
    if (reason == null || reason.isEmpty) return;
    await ref.read(paymentOpsServiceProvider).reject(submission.id, reason);
    if (!mounted) return;
    ref.invalidate(pendingSubmissionsProvider);
  }

  Future<String?> _showRejectDialog(PaymentSubmissionModel submission) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final submitted = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'رفض الإيصال',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'سبب الرفض (مطلوب)',
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white10,
            ),
            validator: (value) =>
                (value == null || value.trim().isEmpty)
                    ? 'سبب الرفض مطلوب'
                    : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(controller.text.trim());
              }
            },
            child: const Text(
              'تأكيد الرفض',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    return submitted;
  }

  @override
  Widget build(BuildContext context) {
    final submissions = ref.watch(pendingSubmissionsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          'مراجعة إيصالات الدفع',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
      ),
      body: submissions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white38, size: 64),
              const SizedBox(height: 16),
              const Text(
                'تعذر تحميل الإرسالات المعلقة.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, color: Colors.white38, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد إرسالات دفع معلقة حالياً.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final s = list[index];
                return _SubmissionTile(
                  submission: s,
                  onApprove: () => _approve(s),
                  onReject: () => _reject(s),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({
    required this.submission,
    required this.onApprove,
    required this.onReject,
  });

  final PaymentSubmissionModel submission;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final amount = formatPiasters(submission.amountPiasters);
    return Card(
      color: const Color(0xFF121212),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: Color(0xFFFFD700), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    submission.studentId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'القناة: ${submission.channelName ?? submission.channelId}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text('المبلغ: $amount', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 4),
            Text(
              'مرجع المعاملة: ${submission.senderReference}',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                submission.receiptUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: Colors.white10,
                  child: const Icon(Icons.broken_image, color: Colors.white38),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.cancel, size: 16, color: Colors.redAccent),
                  label: const Text('رفض'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle, size: 16),
                  label: const Text('موافقة 1-tap'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
