import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashkool_core/kashkool_core.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../providers/certificate_provider.dart';

/// Student certificates screen.
///
/// Shows all certificates issued to the student with QR codes for public
/// verification and status (valid / expired).
class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certificates = ref.watch(certificatesProvider);
    final locale = ref.watch(currentLocaleProvider);
    final rtl = locale == 'ar';

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: Text(AppStrings.translate('lblCertificates', locale)),
          backgroundColor: const Color(0xFF1E293B),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(certificatesProvider),
            ),
          ],
        ),
        body: certificates.when(
          data: (certList) {
            if (certList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: Colors.white38,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.translate('errNoCertificates', locale),
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

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: certList.length,
              itemBuilder: (context, index) {
                final cert = certList[index];
                return _CertificateCard(
                  certificate: cert,
                  locale: locale,
                );
              },
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
                  AppStrings.translate('errLoadCertificates', locale),
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.refresh(certificatesProvider),
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

/// Single certificate card with QR code for verification.
class _CertificateCard extends ConsumerWidget {
  final CertificateModel certificate;
  final String locale;
  const _CertificateCard({
    required this.certificate,
    required this.locale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isValid = certificate.isValid;

    return Card(
      color: const Color(0xFF121212),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        certificate.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppStrings.translate('lblCertificateNumber', locale)}: ${certificate.certificateNumber}',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(isValid).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusLabel(isValid, locale),
                    style: TextStyle(
                      color: _statusColor(isValid),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // QR code for public verification
            if (certificate.qrCodePayload.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.qr_code,
                    color: Colors.cyanAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.translate('lblScanToVerify', locale),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(
                    Icons.qr_code,
                    size: 60,
                    color: Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Details
            Row(
              children: [
                const Icon(
                  Icons.school,
                  color: Colors.white54,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppStrings.translate('lblGroup', locale)}: ${certificate.groupId}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white54,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppStrings.translate('lblIssuedAt', locale)} ${_formatDate(certificate.issuedAt)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (certificate.expiresAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    color: Colors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${AppStrings.translate('lblExpiresAt', locale)} ${_formatDate(certificate.expiresAt!)}',
                      style: TextStyle(
                        color: certificate.expiresAt!.isBefore(DateTime.now())
                            ? Colors.amberAccent
                            : Colors.white70,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _statusColor(bool isValid) =>
      isValid ? const Color(0xFF10B981) : Colors.amberAccent;

  String _statusLabel(bool isValid, String locale) {
    if (locale == 'ar') {
      return isValid ? 'صالح' : 'غير صالح';
    } else {
      return isValid ? 'Valid' : 'Invalid';
    }
  }
}
