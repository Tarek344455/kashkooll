import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/spaceship_ai_client.dart';
import '../../../core/theme/glass_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import 'study_assistant_panel.dart';

/// Full-screen host for the study assistant.
///
/// Kept separate from the panel so the same conversation surface can also be
/// hosted inside a drawer without duplicating any state handling.
class StudyAssistantScreen extends ConsumerWidget {
  const StudyAssistantScreen({
    super.key,
    this.subject = 'المنهج الدراسي',
    this.lesson = 'الدرس الحالي',
    this.initialTeacherMode = false,
  });

  final String subject;
  final String lesson;

  /// Opens straight into the teacher voice (used by teacher dashboards).
  final bool initialTeacherMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final role = initialTeacherMode
        ? KashkoolAiRole.teacher
        : roleForAuth(auth.role);

    return CosmicScaffold(
      appBar: GlassAppBar(
        title: role == KashkoolAiRole.teacher ? 'مساعد المعلم' : 'المساعد الدراسي',
        leading: IconButton(
          tooltip: 'رجوع',
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: StudyAssistantPanel(
        subject: subject,
        lesson: lesson,
        role: role,
        allowModeSwitch: initialTeacherMode || canSwitchAssistantMode(auth.role),
        tenantId: auth.tenantId,
      ),
    );
  }
}

/// Maps the enrolled role to the academic voice the assistant answers in.
KashkoolAiRole roleForAuth(String? role) {
  switch (role) {
    case 'teacher':
      return KashkoolAiRole.teacher;
    case 'parent':
      return KashkoolAiRole.parent;
    case 'secretary':
      return KashkoolAiRole.secretary;
    case 'centerAdmin':
    case 'supervisor':
      return KashkoolAiRole.center;
    case 'superAdmin':
      return KashkoolAiRole.godMode;
    default:
      return KashkoolAiRole.student;
  }
}

/// Staff roles that may preview both voices.
bool canSwitchAssistantMode(String? role) {
  return role == 'teacher' ||
      role == 'centerAdmin' ||
      role == 'supervisor' ||
      role == 'superAdmin';
}
