// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashkool_core/kashkool_core.dart';

import '../providers/payment_review_provider.dart';

/// Teacher / center payment channel management (super-admin setup).
///
/// Lists the active channels of the admin's tenant and allows activating /
/// deactivating them plus creating new ones. Every write goes through the
/// service layer that updates the `payment_channels` table.
class PaymentChannelsScreen extends ConsumerStatefulWidget {
  const PaymentChannelsScreen({super.key});

  @override
  ConsumerState<PaymentChannelsScreen> createState() =>
      _PaymentChannelsScreenState();
}

class _PaymentChannelsScreenState
    extends ConsumerState<PaymentChannelsScreen> {
  Future<void> _refresh() async {
    ref.invalidate(paymentChannelsProvider);
  }

  Future<void> _toggle(PaymentChannelModel channel) async {
    await ref.read(paymentOpsServiceProvider).setChannelActive(
          channel.id,
          !channel.active,
        );
    if (!mounted) return;
    ref.invalidate(paymentChannelsProvider);
  }

  Future<void> _addChannel() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final accountRefController = TextEditingController();
    final feeController = TextEditingController(text: '0');
    final minController = TextEditingController(text: '0');
    final maxController = TextEditingController();
    String? channelType;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text(
          'إضافة قناة دفع',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'اسم القناة',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: channelType,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'نوع القناة',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'vodafone_cash', child: Text('فودافون كاش')),
                    DropdownMenuItem(value: 'etisalat_cash', child: Text('اتصالات كاش')),
                    DropdownMenuItem(value: 'orange_cash', child: Text('أورنج كاش')),
                    DropdownMenuItem(value: 'we_pay', child: Text('We Pay')),
                    DropdownMenuItem(value: 'insta_pay', child: Text('إنستاباي')),
                    DropdownMenuItem(value: 'fawry', child: Text('فوري')),
                    DropdownMenuItem(value: 'cash', child: Text('كاش')),
                    DropdownMenuItem(value: 'cash_desk', child: Text('خزينة السنتر')),
                  ],
                  onChanged: (String? v) => setState(() => channelType = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: accountRefController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'مرجع الحساب',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: feeController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الرسوم (piasters)',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: minController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الحد الأدنى (piasters)',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: maxController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الحد الأقصى (piasters)',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'الحد الأقصى مطلوب';
                    final parsed = int.tryParse(v.trim());
                    if (parsed == null || parsed <= 0) return 'الحد الأقصى غير صحيح';
                    return null;
                  },
                ),
              ],
            ),
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
                final max = int.tryParse(maxController.text.trim()) ?? 0;
                final fee = int.tryParse(feeController.text.trim()) ?? 0;
                final min = int.tryParse(minController.text.trim()) ?? 0;
                await ref.read(paymentOpsServiceProvider).addChannel(
                      tenantId: await ref.read(adminTenantIdProvider.future) ?? '',
                      name: nameController.text.trim(),
                      channelType: channelType ?? 'cash',
                      accountRef: accountRefController.text.trim(),
                      feePiasters: fee,
                      minAmountPiasters: min,
                      maxAmountPiasters: max,
                    );
                if (mounted) {
                  Navigator.of(dialogContext).pop();
                  ref.invalidate(paymentChannelsProvider);
                }
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(paymentChannelsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          'قنوات الدفع',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
      ),
      body: channels.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white38, size: 64),
              const SizedBox(height: 16),
              const Text('تعذر تحميل قنوات الدفع.'),
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
                  const Icon(Icons.payment_outlined, color: Colors.white38, size: 64),
                  const SizedBox(height: 16),
                  const Text('لا توجد قنوات دفع مفعلة بعد.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addChannel,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة قناة'),
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
                final c = list[index];
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
                            const Icon(Icons.payment, color: Color(0xFFFFD700), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                c.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Switch(
                              value: c.active,
                              onChanged: (val) => _toggle(c),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'النوع: ${_channelTypeLabel(c.channelType)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'مرجع الحساب: ${c.accountRef}',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'الرسوم: ${formatPiasters(c.feePiasters)} | الحد: ${formatPiasters(c.minAmountPiasters)} - ${formatPiasters(c.maxAmountPiasters)}',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _channelTypeLabel(String type) {
    switch (type) {
      case 'vodafone_cash':
        return 'فودافون كاش';
      case 'etisalat_cash':
        return 'اتصالات كاش';
      case 'orange_cash':
        return 'أورنج كاش';
      case 'we_pay':
        return 'We Pay';
      case 'insta_pay':
        return 'إنستاباي';
      case 'fawry':
        return 'فوري';
      case 'cash_desk':
        return 'خزينة السنتر';
      default:
        return 'كاش';
    }
  }
}
