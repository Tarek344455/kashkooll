import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass_widgets.dart';
import '../providers/auth_provider.dart';

/// Signed-in landing screen. Shows the bound centre and the destinations the
/// current role is allowed to open.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final destinations = _destinationsFor(auth.role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kashkool'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FloatingGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auth.phone.isEmpty ? 'Signed in' : auth.phone,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Centre: ${auth.tenantId ?? '—'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Role: ${auth.role ?? 'student'}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (destinations.isEmpty)
            const FloatingGlassCard(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No areas are enabled for this role yet.',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            for (final destination in destinations) ...[
              _DestinationTile(destination: destination),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  static List<_Destination> _destinationsFor(String? role) {
    switch (role) {
      case 'secretary':
      case 'centerAdmin':
      case 'supervisor':
        return const [
          _Destination('Cash desk', Icons.point_of_sale, '/secretary-desk'),
          _Destination('Teachers', Icons.school, '/teacher-dashboard'),
          _Destination('Courses', Icons.video_library, '/course-tree'),
        ];
      case 'teacher':
        return const [
          _Destination('My dashboard', Icons.dashboard, '/teacher-dashboard'),
          _Destination('Courses', Icons.video_library, '/course-tree'),
          _Destination('Live classroom', Icons.live_tv, '/live-classroom'),
          _Destination('Quizzes', Icons.quiz, '/quiz'),
          _Destination(
            'Question generator',
            Icons.auto_stories,
            '/study-assistant?mode=teacher',
          ),
          _Destination('Community', Icons.forum, '/discussion-room'),
        ];
      case 'parent':
        return const [
          _Destination('Reports', Icons.insights, '/parent-portal'),
          _Destination('Community', Icons.forum, '/discussion-room'),
        ];
      case 'student':
      default:
        return const [
          _Destination('Courses', Icons.video_library, '/course-tree'),
          _Destination('Live classroom', Icons.live_tv, '/live-classroom'),
          _Destination('Quizzes', Icons.quiz, '/quiz'),
          _Destination('Study assistant', Icons.auto_stories, '/study-assistant'),
          _Destination('Community', Icons.forum, '/discussion-room'),
        ];
    }
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({required this.destination});

  final _Destination destination;

  @override
  Widget build(BuildContext context) {
    return FloatingGlassCard(
      child: ListTile(
        leading: Icon(destination.icon, color: Colors.cyanAccent),
        title: Text(destination.label, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: () => context.go(destination.route),
      ),
    );
  }
}
