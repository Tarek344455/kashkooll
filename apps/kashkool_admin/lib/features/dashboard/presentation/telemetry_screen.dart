import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/admin_theme.dart';
import '../../../core/telemetry_service.dart';

/// Governorate activity plus backend health, with explicit load, empty,
/// error and success states.
class TelemetryScreen extends ConsumerWidget {
  const TelemetryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(governorateCountsProvider);
    final metrics = ref.watch(systemMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Egypt Map'),
        backgroundColor: AdminTheme.surface,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(governorateCountsProvider);
              ref.invalidate(systemMetricsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(governorateCountsProvider);
          ref.invalidate(systemMetricsProvider);
          await ref.read(governorateCountsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            metrics.when(
              loading: () => const _InlineLoader(label: 'Reading platform totals...'),
              error: (error, _) => _ErrorCard(
                message: 'Platform totals unavailable. ($error)',
                onRetry: () => ref.invalidate(systemMetricsProvider),
              ),
              data: (value) => Card(
                color: AdminTheme.surface,
                child: ListTile(
                  leading: Icon(
                    value.backendHealthy ? Icons.cloud_done : Icons.cloud_off,
                    color: value.backendHealthy ? Colors.greenAccent : AdminTheme.crisisCrimson,
                  ),
                  title: Text(
                    value.backendHealthy ? 'Backend responding' : 'Backend not responding',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${value.activeTenants} active centres · ${value.totalStudents} students',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Active sessions by governorate',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            counts.when(
              loading: () => const _InlineLoader(label: 'Counting live sessions...'),
              error: (error, _) => _ErrorCard(
                message: 'Session activity unavailable. ($error)',
                onRetry: () => ref.invalidate(governorateCountsProvider),
              ),
              data: (value) {
                if (value.isEmpty) {
                  return const Card(
                    color: AdminTheme.surface,
                    child: ListTile(
                      leading: Icon(Icons.nights_stay, color: AdminTheme.commandGold),
                      title: Text('No centre is live right now', style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                        'Governorates appear as soon as a session starts.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  );
                }

                final entries = value.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final peak = entries.first.value;

                return Column(
                  children: [
                    for (final entry in entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _GovernorateBar(
                          governorate: entry.key,
                          sessions: entry.value,
                          peak: peak,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GovernorateBar extends StatelessWidget {
  const _GovernorateBar({
    required this.governorate,
    required this.sessions,
    required this.peak,
  });

  final String governorate;
  final int sessions;
  final int peak;

  @override
  Widget build(BuildContext context) {
    final ratio = peak == 0 ? 0.0 : sessions / peak;

    return Card(
      color: AdminTheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _label(governorate),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '$sessions',
                  style: const TextStyle(
                    color: AdminTheme.commandGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(AdminTheme.commandGold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _label(String raw) {
    final words = raw.split(RegExp(r'[\s_-]+'));
    return words
        .map((word) => word.isEmpty
            ? word
            : '${word.substring(0, 1).toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class _InlineLoader extends StatelessWidget {
  const _InlineLoader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AdminTheme.surface,
      child: ListTile(
        leading: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text(label, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AdminTheme.crisisCrimson.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AdminTheme.crisisCrimson),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AdminTheme.crisisCrimson, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
