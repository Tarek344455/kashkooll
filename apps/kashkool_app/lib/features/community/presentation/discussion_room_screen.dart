import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/glass_widgets.dart';

/// Lesson discussion room. Links to the real study assistant instead of a dead
/// snackbar, so the conversation surface is reachable from the lesson context.
class DiscussionRoomScreen extends ConsumerWidget {
  const DiscussionRoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson Discussion Room')),
      body: FloatingGlassCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat, color: Colors.cyanAccent, size: 60),
            const SizedBox(height: 20),
            const Text('Room: Mathematics - Unit 1', style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 10),
            const Text('Moderated by Teacher', style: TextStyle(color: Colors.white70)),
            const Spacer(),
            NeonButton(
              onPressed: () {
                context.go(
                  Uri(
                    path: '/study-assistant',
                    queryParameters: {
                      'subject': 'Mathematics - Unit 1',
                      'lesson': 'Room discussion',
                      'mode': 'student',
                    },
                  ).toString(),
                );
              },
              child: const Text('Open Study Assistant'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
