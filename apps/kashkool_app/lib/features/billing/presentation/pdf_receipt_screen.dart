/// PDF Receipt Screen — generates and shares PDF receipts for transactions.
/// PDF-only: no thermal printer dependency. Works on Web + Mobile.
///
/// Uses the `pdf` package for document generation and `share_plus`/`path_provider`
/// for saving and sharing the generated receipt.

library pdf_receipt_screen;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, deprecated_member_use, dangling_library_doc_comments, unused_field
import '../../../../core/theme/glass_widgets.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/db_provider.dart';
import '../../../../core/database/local_db.dart';

/// Provider for PDF receipt generation.
final pdfReceiptServiceProvider = Provider<PdfReceiptService>((ref) {
  return PdfReceiptService(
    localDb: ref.read(localDbProvider),
  );
});

/// Generates PDF receipts from transaction data.
class PdfReceiptService {
  final LocalDb _localDb;

  PdfReceiptService({required LocalDb localDb}) : _localDb = localDb;

  /// Generate a PDF receipt document for a transaction.
  Future<pw.Document> generateReceipt({
    required String transactionId,
    required double amount,
    required String channel,
    required DateTime timestamp,
    required String userId,
    String? description,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a6,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor(0x00, 0xF5, 0xFF),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'إيصال دفع',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor(0x0F, 0x17, 0x2A),
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 16),

              // Receipt details
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _detailRow('معرف المعاملة', transactionId),
                    _detailRow('المبلغ', '${amount.toStringAsFixed(0)} ج.م'),
                    _detailRow('طريقة الدفع', _channelNameAr(channel)),
                    _detailRow('التاريخ', _formatDateTime(timestamp)),
                    _detailRow('المستخدم', userId),
                    if (description != null && description.isNotEmpty)
                      _detailRow('الوصف', description),
                    pw.SizedBox(height: 20),
                    pw.Divider(),
                    pw.SizedBox(height: 12),
                    pw.Center(
                      child: pw.Text(
                        'كاشكول - نظام إدارةセンتر خاص',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColor(0x00, 0xF5, 0xFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _detailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, color: PdfColor(0x80, 0x80, 0x80)),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _channelNameAr(String channel) {
    switch (channel) {
      case 'cashToWallet':
        return 'نقداً إلى المحفظة';
      case 'fawry':
        return 'فوري';
      case 'vodafoneCash':
        return 'فودافون كاش';
      case 'instaPay':
        return 'إنستاباي';
      case 'settlement':
        return 'تسوية يومية';
      default:
        return channel;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Save the PDF to the device and return the file path.
  Future<String> saveReceipt(pw.Document pdf, String transactionId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/receipt_$transactionId.pdf');
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Share the PDF receipt via system share sheet.
  Future<void> shareReceipt(pw.Document pdf, String transactionId) async {
    final path = await saveReceipt(pdf, transactionId);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        text: 'إيصال دفع كاشكول - $transactionId',
      ),
    );
  }
}

class PdfReceiptScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const PdfReceiptScreen({super.key, required this.transactionId});

  @override
  ConsumerState<PdfReceiptScreen> createState() => _PdfReceiptScreenState();
}

class _PdfReceiptScreenState extends ConsumerState<PdfReceiptScreen> {
  bool _loading = true;
  String? _error;
  LocalTransaction? _transaction;
  pw.Document? _pdf;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  Future<void> _loadTransaction() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final db = ref.read(localDbProvider);
      final allTransactions = await db.getAllTransactions();
      final tx = allTransactions.firstWhere(
        (t) => t.transactionId == widget.transactionId,
        orElse: () => throw Exception('Transaction not found'),
      );
      setState(() {
        _transaction = tx;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل تحميل المعاملة: $e';
        _loading = false;
      });
    }
  }

  Future<void> _generatePdf() async {
    if (_transaction == null) return;
    setState(() => _loading = true);

    try {
      final service = ref.read(pdfReceiptServiceProvider);
      final pdf = await service.generateReceipt(
        transactionId: _transaction!.transactionId,
        amount: _transaction!.amount,
        channel: _transaction!.channel,
        timestamp: _transaction!.timestamp,
        userId: _transaction!.userId,
        description: _transaction!.description,
      );
      setState(() {
        _pdf = pdf;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'فشل توليد الإيصال: $e';
        _loading = false;
      });
    }
  }

  Future<void> _sharePdf() async {
    if (_pdf == null || _transaction == null) return;
    try {
      final service = ref.read(pdfReceiptServiceProvider);
      await service.shareReceipt(_pdf!, _transaction!.transactionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم مشاركة الإيصال'), backgroundColor: Colors.greenAccent),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل المشاركة: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(title: const Text('إيصال الدفع'), backgroundColor: const Color(0xFF1E293B)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(title: const Text('إيصال الدفع'), backgroundColor: const Color(0xFF1E293B)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadTransaction, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
    }

    if (_transaction == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(title: const Text('إيصال الدفع'), backgroundColor: const Color(0xFF1E293B)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_outlined, color: Colors.white38, size: 48),
              SizedBox(height: 12),
              Text('لم يتم العثور على الإيصال', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('إيصال الدفع'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            tooltip: 'توليد PDF',
            onPressed: _generatePdf,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'مشاركة',
            onPressed: _pdf == null ? null : _sharePdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Receipt preview card
            FloatingGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.receipt, color: AppTheme.neonCyan, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'إيصال دفع كاشكول',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _receiptField('معرف المعاملة', _transaction!.transactionId),
                    _receiptField('المبلغ', '${_transaction!.amount.toStringAsFixed(0)} ج.م'),
                    _receiptField('طريقة الدفع', _channelNameAr(_transaction!.channel)),
                    _receiptField('التاريخ', _formatDateTime(_transaction!.timestamp)),
                    _receiptField('المستخدم', _transaction!.userId),
                    const SizedBox(height: 20),
                    if (_pdf == null)
                      const Text(
                        'اضغط على أيقونة PDF لتوليد الإيصال',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      )
                    else
                      const Text(
                        'تم توليد الإيصال بنجاح',
                        style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pdf == null ? _generatePdf : null,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('توليد PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pdf == null ? null : _sharePdf,
                    icon: const Icon(Icons.share),
                    label: const Text('مشاركة'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _channelNameAr(String channel) {
    switch (channel) {
      case 'cashToWallet':
        return 'نقداً إلى المحفظة';
      case 'fawry':
        return 'فوري';
      case 'vodafoneCash':
        return 'فودافون كاش';
      case 'instaPay':
        return 'إنستاباي';
      case 'settlement':
        return 'تسوية يومية';
      default:
        return channel;
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
