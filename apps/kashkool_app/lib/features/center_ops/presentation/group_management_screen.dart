import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/supabase_bootstrap.dart';
import '../../../../core/theme/glass_widgets.dart';
import '../providers/groups_provider.dart';

/// Group management: real groups from the Supabase `groups` table (tenant-scoped,
/// RLS-protected). Staff can add groups; each row shows live enrolment fill.
class GroupManagementScreen extends ConsumerStatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  ConsumerState<GroupManagementScreen> createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends ConsumerState<GroupManagementScreen> {
  static const _staffRoles = <String>{'centerAdmin', 'teacher', 'assistant'};

  final _nameController = TextEditingController();
  final _scheduleController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  Future<void> _addGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final scaffold = ScaffoldMessenger.maybeOf(context);
    final client = SupabaseBootstrap.client;
    final user = client.auth.currentUser;
    if (user == null) {
      if (scaffold != null) {
        scaffold.showSnackBar(
          const SnackBar(content: Text('سجّل الدخول أولاً لإضافة مجموعات')),
        );
      }
      return;
    }

    try {
      final profile = await client
          .from('profiles')
          .select('tenant_id, role')
          .eq('id', user.id)
          .single();
      final tenantId = profile['tenant_id'] as String?;
      if (tenantId == null) {
        if (scaffold != null) {
          scaffold.showSnackBar(
            const SnackBar(content: Text('لا يوجد سنتر مرتبط بهذا الحساب')),
          );
        }
        return;
      }
      final role = profile['role'] as String?;
      if (role == null || !_staffRoles.contains(role)) {
        if (scaffold != null) {
          scaffold.showSnackBar(
            const SnackBar(content: Text('الموظفون فقط يستطيعون إضافة مجموعات')),
          );
        }
        return;
      }

      final schedule = _scheduleController.text.trim();
      final now = DateTime.now().toUtc().toIso8601String();
      await client.from('groups').insert({
        'id': 'grp-${DateTime.now().millisecondsSinceEpoch}',
        'tenant_id': tenantId,
        'name': name,
        'subject': 'الثانوية العامة',
        'schedule': schedule.isEmpty ? 'غير محدد' : schedule,
        'created_at': now,
        'updated_at': now,
      });

      _nameController.clear();
      _scheduleController.clear();
      ref.invalidate(groupsProvider);
      if (scaffold != null) {
        scaffold.showSnackBar(
          const SnackBar(content: Text('تم إنشاء المجموعة وحفظها في السحابة')),
        );
      }
    } catch (_) {
      if (scaffold != null) {
        scaffold.showSnackBar(
          const SnackBar(content: Text('تعذر حفظ المجموعة، حاول مرة أخرى')),
        );
      }
    }
  }

  void _showAddGroupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'إضافة مجموعة دراسية جديدة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'اسم المجموعة / السنتر',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _scheduleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'المواعيد (مثال: السبت والثلاثاء 4:00 م)',
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await _addGroup();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text(
                'حفظ المجموعة',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('إدارة المجموعات والحصص'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'إضافة مجموعة جديدة',
            onPressed: () => _showAddGroupSheet(context),
          ),
        ],
      ),
      body: groups.when(
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups_outlined, size: 64, color: Colors.white38),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد مجموعات حالياً',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddGroupSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('إنشاء أول مجموعة'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final grp = rows[index];
              final enrolled = (grp['enrolled'] as num?)?.toInt() ?? 0;
              final capacity = (grp['capacity'] as num?)?.toInt() ?? 0;
              final price = (grp['price_per_session'] as num?)?.toDouble() ?? 0.0;
              final fillPercent = capacity > 0 ? enrolled / capacity : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FloatingGlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                grp['name'] ?? 'مجموعة',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${price.toInt()} ج.م / حصة',
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, color: Colors.white60, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              grp['schedule'] ?? 'غير محدد',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'الطلاب المسجلون: $enrolled / $capacity',
                              style: const TextStyle(color: Colors.white60, fontSize: 13),
                            ),
                            Text(
                              '${(fillPercent * 100).toInt()}% مكتمل',
                              style: TextStyle(
                                color: fillPercent > 0.9 ? Colors.orangeAccent : Colors.greenAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fillPercent.clamp(0.0, 1.0),
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              fillPercent > 0.9 ? Colors.orangeAccent : Colors.cyanAccent,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white38, size: 64),
              const SizedBox(height: 16),
              const Text(
                'تعذر تحميل المجموعات',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(groupsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
