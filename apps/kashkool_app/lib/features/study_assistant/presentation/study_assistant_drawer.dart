import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import 'study_assistant_panel.dart';
import 'study_assistant_screen.dart';

/// Drawer host for the study assistant.
///
/// Shares [StudyAssistantPanel] with [StudyAssistantScreen], so opening the
/// assistant as a drawer or as a full screen shows the same conversation with
/// the same four states.
class StudyAssistantDrawer extends ConsumerWidget {
  const StudyAssistantDrawer({
    super.key,
    this.subject = 'المنهج الدراسي',
    this.lesson = 'الدرس الحالي',
  });

  final String subject;
  final String lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final role = roleForAuth(auth.role);

    return Drawer(
      backgroundColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.4, -0.6),
                radius: 1.2,
                colors: [
                  Color(0xFF1E1B4B),
                  Color(0xFF0F172A),
                  Color(0xFF020617),
                ],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: StudyAssistantPanel(
              subject: subject,
              lesson: lesson,
              role: role,
              allowModeSwitch: canSwitchAssistantMode(auth.role),
              tenantId: auth.tenantId,
              onClose: () => Navigator.maybePop(context),
            ),
          ),
        ],
      ),
    );
  }
}
