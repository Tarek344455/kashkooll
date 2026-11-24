import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:kashkool_core/kashkool_core.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/config/supabase_bootstrap.dart';
import '../providers/payment_review_provider.dart';

/// Secretary screen to generate a QR activation code for a student/parent.
///
/// Zero-Cost onboarding: the secretary generates a one-time code locally,
/// saves it to `profiles.qr_activation_code`, and gives it to the student.
/// The student enters it in the app via `activateWithQrCode()` — no SMS,
/// no email, no paid gateway.
class QrActivationScreen extends ConsumerStatefulWidget {
  const QrActivationScreen({super.key});

  @override
  ConsumerState<QrActivationScreen> createState() => _QrActivationScreenState();
}

class _QrActivationScreenState extends ConsumerState<QrActivationScreen> {
  final _phoneController = TextEditingController();
  String? _generatedCode;
  bool _isGenerating = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _generateQrCode() async {
    final phone = _phoneController.text.trim();
    final normalized = EgyptValidators.normalizeEgyptianPhone(phone);
    if (normalized.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل رقم موبايل صحيح للطالب.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final code = _generateRandomCode();
      final tenant = await ref.read(adminTenantIdProvider.future);
      if (tenant == null) throw Exception('لم يتم تحديد مركز');

      final client = SupabaseBootstrap.client;

      // Find the profile by phone in this tenant.
      final row = await client
          .from('profiles')
          .select('id')
          .eq('phone', normalized)
          .eq('tenant_id', tenant)
          .maybeSingle();

      if (row == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'لم يتم العثور على طالب بهذا الرقم في هذا المركز.',
            ),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }

      // Save the QR activation code.
      await client
          .from('profiles')
          .update({
            'qr_activation_code': code,
            'qr_activated_at': null, // Reset activation status
          })
          .eq('id', row['id']);

      if (!mounted) return;
      setState(() {
        _generatedCode = code;
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء كود التفعيل بنجاح.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل في إنشاء الكود. حاول مرة أخرى.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text(
          'توليد كود تفعيل الطالب',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'تفعيل بدون رسائل SMS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'السكرتير يولد كود تفعيل للطالب، والطالب يدخله في التطبيق.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              color: const Color(0xFF121212),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'رقم موبايل الطالب',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: '01012345678',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF00F5D4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isGenerating ? null : _generateQrCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F5D4),
                          foregroundColor: Colors.black,
                        ),
                        child: _isGenerating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'إنشاء كود التفعيل',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_generatedCode != null) ...[
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: _generatedCode!,
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: false,
                  embeddedImageStyle: QrEmbeddedImageStyle(
                    size: Size.zero,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'الكود: $_generatedCode',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'أعطي هذا الكود للطالب لدخوله بالتطبيق.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _generatedCode = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                  ),
                  child: const Text(
                    'إنشاء كود جديد',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
