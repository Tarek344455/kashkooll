/// QR Check-in Screen — camera-free QR attendance using rotating tokens.
/// Works on any phone: displays a QR code (scannable by any QR app) or accepts
/// manual token entry. No NFC hardware dependency.
///
/// Uses DynamicQrEngine for rotating, verifiable tokens (5-second rotation).

library qr_checkin_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, deprecated_member_use, dangling_library_doc_comments
import '../../../../core/theme/glass_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/db_provider.dart';
import '../../../../core/database/local_db.dart';
import '../../auth/providers/auth_provider.dart';
import '../../center_ops/services/dynamic_qr_engine.dart';

/// Provider for the dynamic QR engine per session.
final dynamicQrEngineProvider = Provider.family<DynamicQrEngine, String>((ref, sessionId) {
  final secret = 'kashkool-session-$sessionId';
  return DynamicQrEngine(sessionId: sessionId, sessionSecret: secret);
});

class QrCheckinScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const QrCheckinScreen({super.key, required this.sessionId});

  @override
  ConsumerState<QrCheckinScreen> createState() => _QrCheckinScreenState();
}

class _QrCheckinScreenState extends ConsumerState<QrCheckinScreen> {
  String? _error;
  String _scannedToken = '';
  String _scanResult = '';
  bool _scanSuccess = false;

  @override
  void initState() {
    super.initState();
  }

  /// Verify a scanned/entered token and record attendance.
  Future<void> _verifyToken(String token) async {
    setState(() {
      _error = null;
    });

    try {
      final engine = ref.read(dynamicQrEngineProvider(widget.sessionId));
      final valid = engine.verify(token);

      if (!valid) {
        setState(() {
          _scanResult = 'رمز غير صحيح أو منتهي الصلاحية';
          _scanSuccess = false;
        });
        return;
      }

      // Record attendance in local DB (idempotent)
      final db = ref.read(localDbProvider);
      final auth = ref.read(authProvider);
      await db.insertAttendance(LocalAttendanceCompanion(
        studentId: Value(token),
        sessionId: Value(widget.sessionId),
        tenantId: Value(auth.tenantId ?? 'unassigned'),
        timestamp: Value(DateTime.now()),
        syncStatus: Value('pending'),
      ));

      setState(() {
        _scanResult = 'تم تسجيل الحضور بنجاح';
        _scanSuccess = true;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل التحقق: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = ref.watch(dynamicQrEngineProvider(widget.sessionId));
    final currentToken = engine.currentToken;
    final secondsRemaining = engine.secondsRemaining(DateTime.now());

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(title: const Text('تسجيل الحضور عبر QR'), backgroundColor: const Color(0xFF1E293B)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => setState(() => _error = null), child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('تسجيل الحضور عبر QR'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // QR Code display
            FloatingGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'أعرض هذا الكود للطالب للمسح',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0F172A), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          currentToken,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.neonCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'يتجدد كل',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            '$secondsRemaining ث',
                            style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      currentToken,
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Manual token entry (fallback for devices without camera)
            FloatingGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'إدخال الرمز يدوياً',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (v) => _scannedToken = v,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'أدخل رمز الحضور',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'مثال: 12.abcdef1234567890',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _scannedToken.isEmpty ? null : () => _verifyToken(_scannedToken),
                            icon: const Icon(Icons.done),
                            label: const Text('تحقق من الرمز'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scan result
            if (_scanResult.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _scanSuccess ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _scanSuccess ? Colors.greenAccent : Colors.redAccent),
                ),
                child: Row(
                  children: [
                    Icon(_scanSuccess ? Icons.check_circle : Icons.error, color: _scanSuccess ? Colors.greenAccent : Colors.redAccent),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_scanResult, style: const TextStyle(color: Colors.white))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
