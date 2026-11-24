import 'package:file_picker/file_picker.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashkool_core/kashkool_core.dart'
    show compressImage, formatPiasters;

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../../billing/providers/payment_submission_provider.dart';

/// Student checkout: pick an active payment channel, enter the amount and
/// sender reference, attach a compressed receipt image, and submit for staff
/// approval. All money uses piasters (int minor units).
class StudentCheckoutScreen extends ConsumerStatefulWidget {
  const StudentCheckoutScreen({super.key});

  @override
  ConsumerState<StudentCheckoutScreen> createState() => _StudentCheckoutScreenState();
}

class _StudentCheckoutScreenState extends ConsumerState<StudentCheckoutScreen> {
  String? _selectedChannelId;
  int? _selectedChannelMax;
  int? _selectedChannelFee;
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  Uint8List? _receiptBytes;
  String? _receiptFileName;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result.isEmpty) return;

    final file = result.first;
    final bytes = await file.readAsBytes();
    final name = file.name;

    // Compress image to <= 150 KB to save student mobile data and protect
    // Supabase Free Tier storage/bandwidth (Zero-Cost deployment).
    final compressed = await compressImage(
      originalBytes: bytes,
      minQuality: 50,
      maxSizeBytes: 150 * 1024,
    );
    if (compressed.compressedSize > 150 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.translate('errImageTooLarge', _locale())),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    _receiptBytes = compressed.bytes;
    _receiptFileName = name;

    if (!mounted) return;
    setState(() {});
  }

  String _locale() => ref.watch(currentLocaleProvider);

  Future<void> _copyAccountRef(String ref) async {
    await Clipboard.setData(ClipboardData(text: ref));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${AppStrings.translate('msgCopied', _locale())}: $ref'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedChannelId == null ||
        _amountController.text.trim().isEmpty ||
        _referenceController.text.trim().isEmpty ||
        _receiptBytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.translate('errFillAllFields', _locale())),
          backgroundColor: Colors.amberAccent,
        ),
      );
      return;
    }
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.translate('errInvalidAmount', _locale())),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (_selectedChannelMax != null && amount > _selectedChannelMax!) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.translate('errAmountExceedsLimit', _locale())),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await ref.read(paymentSubmissionNotifierProvider.notifier).submit(
      channelId: _selectedChannelId!,
      amountPiasters: amount,
      senderReference: _referenceController.text.trim(),
      receiptBytes: _receiptBytes!,
      fileName: _receiptFileName!,
    );

    final state = ref.read(paymentSubmissionNotifierProvider);
    if (!mounted) return;
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.translate('errSubmitFailed', _locale())}: ${state.error}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.translate('msgReceiptSubmitted', _locale())),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      _amountController.clear();
      _referenceController.clear();
      setState(() {
        _receiptBytes = null;
        _receiptFileName = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(paymentChannelsProvider);
    final locale = ref.watch(currentLocaleProvider);
    final rtl = locale == 'ar';

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: Text(AppStrings.translate('btnCheckout', locale)),
          backgroundColor: const Color(0xFF1E293B),
        ),
        body: channels.when(
          data: (chs) {
            if (chs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment_outlined,
                        size: 64, color: Colors.white38),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.translate('errNoChannels', locale),
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.refresh(paymentChannelsProvider),
                      icon: const Icon(Icons.refresh),
                      label: Text(AppStrings.translate('btnRetry', locale)),
                    ),
                  ],
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Channel selection
                  FloatingGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.translate('lblSelectChannel', locale),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...chs.map((c) {
                            final selected = _selectedChannelId == c.id;
                            return ListTile(
                              leading: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedChannelId = c.id;
                                    _selectedChannelMax = c.maxAmountPiasters;
                                  });
                                },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selected
                                        ? const Color(0xFF00F5D4)
                                        : Colors.transparent,
                                    border: Border.all(color: Colors.white54),
                                  ),
                                  child: selected
                                      ? const Icon(Icons.check,
                                          size: 14, color: Colors.black)
                                      : null,
                                ),
                              ),
                              title: Text(c.name,
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                '${AppStrings.translate('lblAccountRef', locale)}: ${c.accountRef}',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                              trailing: selected
                                  ? const Icon(Icons.check_circle,
                                      color: Color(0xFF00F5D4))
                                  : IconButton(
                                      icon: const Icon(Icons.copy, size: 18, color: Colors.white54),
                                      onPressed: () => _copyAccountRef(c.accountRef),
                                    ),
                              onTap: () {
                                setState(() {
                                  _selectedChannelId = c.id;
                                  _selectedChannelMax = c.maxAmountPiasters;
                                  _selectedChannelFee = c.feePiasters;
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Amount input
                  FloatingGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.translate('lblAmount', locale),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedChannelMax != null)
                                Text(
                                  '${AppStrings.translate('lblMax', locale)} ${formatPiasters(_selectedChannelMax!)}',
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_selectedChannelFee != null)
                            Text(
                              '${AppStrings.translate('lblFee', locale)}: ${formatPiasters(_selectedChannelFee!)}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: AppStrings.translate('hintAmountEgp', locale),
                              hintStyle: const TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF00F5D4)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Sender reference
                  FloatingGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.translate('lblSenderRef', locale),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _referenceController,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              hintText: AppStrings.translate('hintSenderRef', locale),
                              hintStyle: const TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF00F5D4)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Receipt attachment
                  FloatingGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.translate('lblReceipt', locale),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_receiptBytes != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${_receiptBytes!.length ~/ 1024} كيلو',
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          NeonButton(
                            glowColor: const Color(0xFF00F5D4),
                            onPressed: _pickReceipt,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_receiptBytes == null
                                    ? Icons.attach_file
                                    : Icons.check_circle,
                                    color: const Color(0xFF0F172A),
                                    size: 18),
                                const SizedBox(width: 8),
                                Text(_receiptBytes == null
                                    ? AppStrings.translate('btnAttachReceipt', locale)
                                    : AppStrings.translate('lblReceiptAttached', locale)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Submit
                  NeonButton(
                    glowColor: const Color(0xFF00F5D4),
                    onPressed: _submit,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send, color: Color(0xFF0F172A), size: 18),
                        const SizedBox(width: 8),
                        Text(AppStrings.translate('btnSubmitPayment', locale)),
                      ],
                    ),
                  ),
                ],
              ),
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
                  AppStrings.translate('errLoadChannels', locale),
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(paymentChannelsProvider),
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


