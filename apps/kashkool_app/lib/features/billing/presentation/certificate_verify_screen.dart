import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashkool_core/kashkool_core.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../providers/certificate_provider.dart';

class CertificateVerifyScreen extends ConsumerStatefulWidget {
  const CertificateVerifyScreen({super.key});

  @override
  ConsumerState<CertificateVerifyScreen> createState() =>
      _CertificateVerifyScreenState();
}

class _CertificateVerifyScreenState
    extends ConsumerState<CertificateVerifyScreen> {
  final _idController = TextEditingController();
  final _numberController = TextEditingController();
  CertificateVerificationResult? _result;
  bool _isVerifying = false;

  @override
  void dispose() {
    _idController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final service = ref.read(certificateVerificationServiceProvider);
    setState(() {
      _isVerifying = true;
      _result = null;
    });

    try {
      _result = await service.verify(
        certificateId: _idController.text.trim().isEmpty
            ? null
            : _idController.text.trim(),
        certificateNumber: _numberController.text.trim().isEmpty
            ? null
            : _numberController.text.trim(),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _result = CertificateVerificationResult(
          valid: false,
          result: 'invalid',
          message: AppStrings.translate(
            'errVerificationFailed',
            ref.read(currentLocaleProvider),
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Widget _buildResultCard(CertificateVerificationResult result, String locale) {
    return Card(
      color: result.valid
          ? const Color(0xFF10B981).withValues(alpha: 0.15)
          : Colors.amberAccent.withValues(alpha: 0.15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  result.valid ? Icons.check_circle : Icons.error_outline,
                  color: result.valid
                      ? const Color(0xFF10B981)
                      : Colors.amberAccent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result.valid
                        ? AppStrings.translate('lblCertificateValid', locale)
                        : AppStrings.translate('lblCertificateInvalid', locale),
                    style: TextStyle(
                      color: result.valid
                          ? const Color(0xFF10B981)
                          : Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (result.certificateNumber != null) ...[
              _buildDetailRow(
                locale,
                Icons.label,
                '${AppStrings.translate('lblCertificateNumber', locale)}: ${result.certificateNumber}',
              ),
              const SizedBox(height: 8),
            ],
            if (result.title != null) ...[
              _buildDetailRow(
                locale,
                Icons.school,
                '${AppStrings.translate('lblCourseTitle', locale)}: ${result.title}',
              ),
              const SizedBox(height: 8),
            ],
            if (result.issuedAt != null) ...[
              _buildDetailRow(
                locale,
                Icons.calendar_today,
                '${AppStrings.translate('lblIssuedAt', locale)} ${_formatDate(result.issuedAt!)}',
              ),
              const SizedBox(height: 8),
            ],
            if (result.expiresAt != null) ...[
              _buildDetailRow(
                locale,
                Icons.schedule,
                '${AppStrings.translate('lblExpiresAt', locale)} ${_formatDate(result.expiresAt!)}',
              ),
              const SizedBox(height: 8),
            ],
            Text(
              result.message ?? '',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String locale, IconData icon, String text) {
    return Row(
      children: [
        const Icon(
          Icons.label,
          color: Colors.white54,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(currentLocaleProvider);
    final rtl = locale == 'ar';

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: Text(AppStrings.translate('lblVerifyCertificate', locale)),
          backgroundColor: const Color(0xFF1E293B),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.verified,
                size: 64,
                color: Colors.cyanAccent,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.translate('lblVerifyCertificate', locale),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'التحقق من صحة الشهادة الرقمية',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FloatingGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _idController,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'معرف الشهادة (اختياري)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'Cert-123456',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF00F5D4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _numberController,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'رقم الشهادة (اختياري)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          hintText: 'KSH-2026-001',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF00F5D4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00F5D4),
                            foregroundColor: Colors.black,
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'التحقق من الشهادة',
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
              if (_result != null) _buildResultCard(_result!, locale),
            ],
          ),
        ),
      ),
    );
  }
}
