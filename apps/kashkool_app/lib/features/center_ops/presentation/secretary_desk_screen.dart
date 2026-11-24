import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/database/db_provider.dart';
import '../../../../core/database/local_db.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/dynamic_qr_engine.dart';
import '../services/thermal_printer_service.dart';

/// Offline cash desk: rotating attendance QR, roster scanning, cash-to-wallet
/// top-ups and a printable batch receipt — all written to the local database
/// first and synced later.
class SecretaryDeskScreen extends ConsumerStatefulWidget {
  const SecretaryDeskScreen({super.key});

  @override
  ConsumerState<SecretaryDeskScreen> createState() => _SecretaryDeskScreenState();
}

class _SecretaryDeskScreenState extends ConsumerState<SecretaryDeskScreen> {
  final ValueNotifier<DateTime> _clock = ValueNotifier<DateTime>(DateTime.now());
  final TextEditingController _amountController = TextEditingController();
  final Map<String, String> _batch = <String, String>{};

  Timer? _ticker;
  StreamSubscription<List<LocalStudent>>? _rosterSubscription;
  DynamicQrEngine? _engine;
  LocalSession? _session;
  LocalStudent? _topUpStudent;
  List<LocalStudent> _roster = const <LocalStudent>[];
  bool _rosterLoaded = false;
  bool _loadingSession = true;
  String? _bootError;
  double _collected = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _clock.value = DateTime.now();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _rosterSubscription?.cancel();
    _clock.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    final db = ref.read(localDbProvider);
    final tenantId = ref.read(authProvider).tenantId ?? 'unassigned';

    setState(() {
      _loadingSession = true;
      _bootError = null;
    });

    try {
      final session = await _ensureSession(db, tenantId);

      await _rosterSubscription?.cancel();
      _rosterSubscription = db.watchStudents().listen((rows) {
        if (!mounted) return;
        setState(() {
          _roster = rows;
          _rosterLoaded = true;
        });
      });

      if (!mounted) return;
      setState(() {
        _session = session;
        _engine = DynamicQrEngine(
          sessionId: session.sessionId,
          sessionSecret: session.qrSecret,
        );
        _loadingSession = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _bootError = 'Could not start the desk session. ($error)';
        _loadingSession = false;
      });
    }
  }

  Future<LocalSession> _ensureSession(LocalDb db, String tenantId) async {
    final now = DateTime.now();
    final sessions = await db.getAllSessions();
    final today = sessions
        .where((session) =>
            session.tenantId == tenantId &&
            session.startTime.year == now.year &&
            session.startTime.month == now.month &&
            session.startTime.day == now.day)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    if (today.isNotEmpty) return today.first;

    final sessionId = 'sess-${now.millisecondsSinceEpoch}';
    await db.upsertSession(
      LocalSessionsCompanion.insert(
        sessionId: sessionId,
        tenantId: tenantId,
        groupId: 'default',
        title: 'Cash desk session',
        type: 'offline',
        startTime: now,
        qrSecret: _randomSecret(),
      ),
    );

    final created = (await db.getAllSessions())
        .where((session) => session.sessionId == sessionId)
        .toList();
    if (created.isEmpty) {
      throw StateError('The session was not persisted.');
    }
    return created.first;
  }

  String _randomSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _toggleStudent(LocalStudent student) async {
    final session = _session;
    if (session == null) return;

    final db = ref.read(localDbProvider);

    if (_batch.containsKey(student.studentId)) {
      try {
        await db.deleteAttendance(student.studentId, session.sessionId);
        if (!mounted) return;
        setState(() => _batch.remove(student.studentId));
      } catch (error) {
        _notify('Could not undo the scan. ($error)');
      }
      return;
    }

    try {
      await db.insertAttendance(
        LocalAttendanceCompanion.insert(
          studentId: student.studentId,
          sessionId: session.sessionId,
          tenantId: session.tenantId,
          timestamp: DateTime.now(),
          syncStatus: 'pending',
        ),
      );
      if (!mounted) return;
      setState(() => _batch[student.studentId] = student.name);
    } catch (error) {
      _notify('Could not record attendance. ($error)');
    }
  }

  Future<void> _topUp() async {
    final student = _topUpStudent;
    final amount = double.tryParse(_amountController.text.trim());

    if (student == null) {
      _notify('Pick a student first.');
      return;
    }
    if (amount == null || amount <= 0) {
      _notify('Enter an amount greater than zero.');
      return;
    }

    final db = ref.read(localDbProvider);
    final now = DateTime.now();
    final transactionId = 'tx-${now.microsecondsSinceEpoch}';

    try {
      await db.insertTransaction(
        LocalTransactionsCompanion.insert(
          transactionId: transactionId,
          userId: student.studentId,
          amount: amount,
          channel: 'cashToWallet',
          timestamp: now,
          description: 'Cash top-up at desk',
          syncStatus: 'pending',
        ),
      );

      await db.upsertSyncQueueItem(
        SyncQueueTableCompanion.insert(
          collectionName: 'wallet_transactions',
          documentId: transactionId,
          operation: 'create',
          dataJson: jsonEncode(<String, dynamic>{
            'transactionId': transactionId,
            'userId': student.studentId,
            'amount': amount,
            'channel': 'cashToWallet',
            'createdAt': now.toIso8601String(),
          }),
          priority: 0,
          status: 'pending',
          createdAt: now,
        ),
      );

      if (!mounted) return;
      setState(() {
        _collected += amount;
        _amountController.clear();
      });
      _notify('${amount.toStringAsFixed(2)} EGP queued for ${student.name}.');
    } catch (error) {
      _notify('Top-up failed. ($error)');
    }
  }

  void _printBatch() {
    if (_batch.isEmpty) {
      _notify('Scan at least one student first.');
      return;
    }

    final receipt = ThermalPrinterService.printBatchReceipt(
      _batch.keys.toList(growable: false),
      _collected,
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batch receipt'),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: SelectableText(
              receipt,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: receipt));
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              _notify('Receipt copied to the clipboard.');
            },
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Desk'),
        actions: [
          if (_session != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  _session!.sessionId,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
      body: _loadingSession
          ? const Center(child: CircularProgressIndicator())
          : _bootError != null
              ? _ErrorState(message: _bootError!, onRetry: _boot)
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _QrCard(clock: _clock, engine: _engine!),
                    const SizedBox(height: 16),
                    _RosterCard(
                      roster: _roster,
                      loaded: _rosterLoaded,
                      batch: _batch,
                      onToggle: _toggleStudent,
                    ),
                    const SizedBox(height: 16),
                    _BatchCard(
                      count: _batch.length,
                      collected: _collected,
                      onPrint: _printBatch,
                      onClear: _batch.isEmpty
                          ? null
                          : () => setState(() {
                                _batch.clear();
                                _collected = 0;
                              }),
                    ),
                    const SizedBox(height: 16),
                    _TopUpCard(
                      roster: _roster,
                      selected: _topUpStudent,
                      amountController: _amountController,
                      onSelect: (student) => setState(() => _topUpStudent = student),
                      onSubmit: _topUp,
                    ),
                  ],
                ),
    );
  }
}

class _QrCard extends StatelessWidget {
  const _QrCard({required this.clock, required this.engine});

  final ValueNotifier<DateTime> clock;
  final DynamicQrEngine engine;

  @override
  Widget build(BuildContext context) {
    return FloatingGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ValueListenableBuilder<DateTime>(
          valueListenable: clock,
          builder: (context, now, _) {
            final token = engine.tokenAt(now);
            return Column(
              children: [
                const Text(
                  'Attendance QR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(data: token, size: 180),
                ),
                const SizedBox(height: 12),
                Text(
                  'Rotates in ${engine.secondsRemaining(now)}s',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RosterCard extends StatefulWidget {
  const _RosterCard({
    required this.roster,
    required this.loaded,
    required this.batch,
    required this.onToggle,
  });

  final List<LocalStudent> roster;
  final bool loaded;
  final Map<String, String> batch;
  final Future<void> Function(LocalStudent) onToggle;

  @override
  State<_RosterCard> createState() => _RosterCardState();
}

class _RosterCardState extends State<_RosterCard> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LocalStudent> _filtered() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.roster;
    return widget.roster
        .where((student) =>
            student.name.toLowerCase().contains(query) ||
            student.phone.contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.loaded) {
      return const Card(
        child: ListTile(
          leading: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('Loading roster...'),
        ),
      );
    }

    if (widget.roster.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.group_off),
          title: Text('No students on this device'),
          subtitle: Text('Sync the centre roster while online, then work offline.'),
        ),
      );
    }

    final filtered = _filtered();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Roster',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name or phone',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No student matches that search.',
                  style: TextStyle(fontSize: 12),
                ),
              )
            else
              for (final student in filtered)
                ListTile(
                  dense: true,
                  leading: Icon(
                    widget.batch.containsKey(student.studentId)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: widget.batch.containsKey(student.studentId)
                        ? Colors.greenAccent
                        : Colors.white54,
                  ),
                  title: Text(student.name),
                  subtitle: Text(student.phone),
                  onTap: () => widget.onToggle(student),
                ),
          ],
        ),
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({
    required this.count,
    required this.collected,
    required this.onPrint,
    required this.onClear,
  });

  final int count;
  final double collected;
  final VoidCallback onPrint;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '$count scanned · ${ThermalPrinterService.formatEgp(collected)} collected',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onPrint,
                    icon: const Icon(Icons.print),
                    label: const Text('Print batch receipt'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear batch',
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_all),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopUpCard extends StatelessWidget {
  const _TopUpCard({
    required this.roster,
    required this.selected,
    required this.amountController,
    required this.onSelect,
    required this.onSubmit,
  });

  final List<LocalStudent> roster;
  final LocalStudent? selected;
  final TextEditingController amountController;
  final ValueChanged<LocalStudent?> onSelect;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cash-to-wallet top-up',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LocalStudent>(
              initialValue: selected,
              decoration: const InputDecoration(
                labelText: 'Student',
                prefixIcon: Icon(Icons.person),
              ),
              items: roster
                  .map(
                    (student) => DropdownMenuItem<LocalStudent>(
                      value: student,
                      child: Text('${student.name} · ${student.phone}'),
                    ),
                  )
                  .toList(),
              onChanged: roster.isEmpty ? null : onSelect,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (EGP)',
                prefixIcon: Icon(Icons.payments),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: roster.isEmpty ? null : () => onSubmit(),
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Queue top-up'),
            ),
            const SizedBox(height: 6),
            const Text(
              'Saved on this device and synced when the connection returns.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => onRetry(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
