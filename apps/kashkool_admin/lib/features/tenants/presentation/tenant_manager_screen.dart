import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/admin_theme.dart';
import '../../../core/tenant_control_service.dart';

/// Create centres, watch them live, and freeze or reactivate them.
class TenantManagerScreen extends ConsumerStatefulWidget {
  const TenantManagerScreen({super.key});

  @override
  ConsumerState<TenantManagerScreen> createState() => _TenantManagerScreenState();
}

class _TenantManagerScreenState extends ConsumerState<TenantManagerScreen> {
  static final RegExp _slug = RegExp(r'^[a-z0-9][a-z0-9-]{2,29}$');

  final _formKey = GlobalKey<FormState>();
  final _tenantIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _subdomainController = TextEditingController();

  bool _submitting = false;
  String? _formError;

  @override
  void dispose() {
    _tenantIdController.dispose();
    _nameController.dispose();
    _subdomainController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final tenantId = _tenantIdController.text.trim();
    final name = _nameController.text.trim();
    final typedSubdomain = _subdomainController.text.trim();
    final subdomain = typedSubdomain.isEmpty ? tenantId : typedSubdomain;

    setState(() {
      _submitting = true;
      _formError = null;
    });

    try {
      await ref.read(tenantControlServiceProvider).createTenant(
            tenantId: tenantId,
            name: name,
            subdomain: subdomain,
            accentColor: '#00F5D4',
            primaryColor: '#FFD700',
          );
      if (!mounted) return;
      _tenantIdController.clear();
      _nameController.clear();
      _subdomainController.clear();
      _formKey.currentState?.reset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Centre "$name" created.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = 'Could not create the centre. ($error)');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _setActive(TenantSummary tenant, bool active) async {
    final verb = active ? 'reactivate' : 'freeze';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(active ? 'Reactivate centre?' : 'Freeze centre?'),
        content: Text(
          active
              ? '"${tenant.name}" will regain access immediately.'
              : '"${tenant.name}" will be blocked from signing in until reactivated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(active ? 'Reactivate' : 'Freeze'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final service = ref.read(tenantControlServiceProvider);
      if (active) {
        await service.unfreezeTenant(tenant.tenantId);
      } else {
        await service.freezeTenant(tenant.tenantId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Centre "${tenant.name}" ${verb}d.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not $verb the centre. ($error)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenants = ref.watch(tenantsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Centres'),
        backgroundColor: AdminTheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AdminTheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create a centre',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tenantIdController,
                      decoration: const InputDecoration(
                        labelText: 'Centre ID',
                        helperText: 'Lowercase letters, digits and dashes (3-30).',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return 'Centre ID is required.';
                        if (!_slug.hasMatch(text)) {
                          return 'Use 3-30 lowercase letters, digits or dashes.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Centre name'),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.length < 3) return 'Enter at least 3 characters.';
                        if (text.length > 60) return 'Keep the name under 60 characters.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _subdomainController,
                      decoration: const InputDecoration(
                        labelText: 'Subdomain (optional)',
                        helperText: 'Defaults to the centre ID.',
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _create(),
                      validator: (value) {
                        final text = (value ?? '').trim();
                        if (text.isEmpty) return null;
                        if (!_slug.hasMatch(text)) {
                          return 'Use 3-30 lowercase letters, digits or dashes.';
                        }
                        return null;
                      },
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _formError!,
                        style: const TextStyle(color: AdminTheme.crisisCrimson, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submitting ? null : _create,
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create centre'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'All centres',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          tenants.when(
            loading: () => const Card(
              color: AdminTheme.surface,
              child: ListTile(
                leading: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                title: Text('Loading centres...', style: TextStyle(color: Colors.white70)),
              ),
            ),
            error: (error, _) => Card(
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
                      child: Text(
                        'Could not load centres. ($error)',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(tenantsStreamProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const Card(
                  color: AdminTheme.surface,
                  child: ListTile(
                    leading: Icon(Icons.apartment, color: AdminTheme.commandGold),
                    title: Text('No centres yet', style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      'Use the form above to onboard the first centre.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  for (final tenant in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _TenantTile(
                        tenant: tenant,
                        onToggle: () => _setActive(tenant, !tenant.isActive),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TenantTile extends StatelessWidget {
  const _TenantTile({required this.tenant, required this.onToggle});

  final TenantSummary tenant;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final expired = tenant.isExpired;
    final statusColor = !tenant.isActive
        ? AdminTheme.crisisCrimson
        : expired
            ? Colors.orangeAccent
            : Colors.greenAccent;
    final statusLabel = !tenant.isActive
        ? 'Frozen'
        : expired
            ? 'Expired'
            : 'Active';

    return Card(
      color: AdminTheme.surface,
      child: ListTile(
        leading: Icon(
          tenant.isActive ? Icons.school : Icons.block,
          color: statusColor,
        ),
        title: Text(tenant.name, style: const TextStyle(color: Colors.white)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${tenant.subdomain.isEmpty ? tenant.tenantId : tenant.subdomain} · ${tenant.tier} · $statusLabel',
            style: TextStyle(color: statusColor, fontSize: 12),
          ),
        ),
        trailing: IconButton(
          tooltip: tenant.isActive ? 'Freeze centre' : 'Reactivate centre',
          icon: Icon(
            tenant.isActive ? Icons.ac_unit : Icons.play_circle_outline,
            color: tenant.isActive ? AdminTheme.crisisCrimson : Colors.greenAccent,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
