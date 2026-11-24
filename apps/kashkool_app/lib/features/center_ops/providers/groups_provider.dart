import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_bootstrap.dart';

/// Tenant id of the signed-in profile, resolved once per session.
final currentTenantIdProvider = FutureProvider<String?>((ref) async {
  final client = SupabaseBootstrap.client;
  final user = client.auth.currentUser;
  if (user == null) return null;
  final data = await client
      .from('profiles')
      .select('tenant_id')
      .eq('id', user.id)
      .single();
  return data['tenant_id'] as String?;
});

/// Groups for the tenant of the signed-in user.
final groupsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final tenant = await ref.watch(currentTenantIdProvider.future);
  if (tenant == null) return const [];
  final client = SupabaseBootstrap.client;
  final data = await client
      .from('groups')
      .select('*')
      .eq('tenant_id', tenant)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(data);
});
