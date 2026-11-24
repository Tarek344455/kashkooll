import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/admin_theme.dart';
import '../../../core/tenant_control_service.dart';

/// Every privileged action, newest first, read from the per-tenant
/// `audit_logs` sub-collections.
class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trail = ref.watch(auditTrailProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Trail'),
        backgroundColor: AdminTheme.surface,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(auditTrailProvider),
          ),
        ],
      ),
      body: trail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AdminTheme.crisisCrimson.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AdminTheme.crisisCrimson),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Audit history unavailable',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$error',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => ref.invalidate(auditTrailProvider),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                Card(
                  color: AdminTheme.surface,
                  child: ListTile(
                    leading: Icon(Icons.history, color: AdminTheme.commandGold),
                    title: Text('Nothing recorded yet', style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      'Creating, freezing or reactivating a centre writes an entry here.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _AuditTile(entry: entries[index]),
          );
        },
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AdminTheme.surface,
      child: ListTile(
        leading: Icon(_icon(entry.action), color: _color(entry.action)),
        title: Text(_label(entry.action), style: const TextStyle(color: Colors.white)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.details.isNotEmpty)
                Text(entry.details, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '${entry.tenantId} · ${_time(entry.createdAt)} · ${entry.actorUid}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
        isThreeLine: entry.details.isNotEmpty,
      ),
    );
  }

  static IconData _icon(String action) {
    if (action.endsWith('created')) return Icons.add_business;
    if (action.endsWith('frozen')) return Icons.ac_unit;
    if (action.endsWith('unfrozen')) return Icons.play_circle_outline;
    if (action.startsWith('subscription')) return Icons.payments;
    return Icons.history;
  }

  static Color _color(String action) {
    if (action.endsWith('frozen')) return AdminTheme.crisisCrimson;
    if (action.endsWith('unfrozen')) return Colors.greenAccent;
    return AdminTheme.commandGold;
  }

  static String _label(String action) {
    switch (action) {
      case 'tenant.created':
        return 'Centre created';
      case 'tenant.frozen':
        return 'Centre frozen';
      case 'tenant.unfrozen':
        return 'Centre reactivated';
      case 'subscription.updated':
        return 'Subscription changed';
      default:
        return action;
    }
  }

  static String _time(DateTime? value) {
    if (value == null) return 'pending timestamp';
    final d = value.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$day/$month/${d.year} $h:$m';
  }
}
