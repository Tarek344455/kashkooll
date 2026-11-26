import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/l10n/app_strings.dart';
import '../core/models/kashkool_models.dart';
import '../core/security/aegis_qr_engine.dart';
import '../core/security/role_access_guard.dart';
import '../data/seed_data.dart';
import '../state/kashkool_controller.dart';
import '../ui/space_glass.dart';

class WorkspaceShell extends StatelessWidget {
  final KashkoolController controller;

  const WorkspaceShell({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final allowed = RoleAccessGuard.destinationsForRole(c.activeRole);
    final current = c.destination;
    final currentIndex =
        allowed.contains(current) ? allowed.indexOf(current) : 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: KashkoolColors.deepVoid.withValues(alpha: 0.9),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.tr('app_title'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              c.userLabel,
              style: const TextStyle(
                fontSize: 11,
                color: KashkoolColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Language',
            onPressed: c.toggleLanguage,
            icon: const Icon(Icons.language),
          ),
          IconButton(
            tooltip: c.tr('sign_out'),
            onPressed: c.signOut,
            icon: const Icon(Icons.logout, color: KashkoolColors.crimsonBlocked),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: _buildBody(context, current),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: KashkoolColors.spaceSurface.withValues(alpha: 0.94),
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) {
          HapticFeedback.selectionClick();
          c.navigate(allowed[idx]);
        },
        destinations: allowed.map((dest) => _navItem(c, dest)).toList(),
      ),
    );
  }

  NavigationDestination _navItem(KashkoolController c, AppDestination dest) {
    switch (dest) {
      case AppDestination.home:
        return NavigationDestination(
            icon: const Icon(Icons.home_outlined), label: c.tr('nav_home'));
      case AppDestination.desk:
        return NavigationDestination(
            icon: const Icon(Icons.qr_code_scanner), label: c.tr('nav_desk'));
      case AppDestination.analytics:
        return NavigationDestination(
            icon: const Icon(Icons.bar_chart), label: c.tr('nav_analytics'));
      case AppDestination.teacher:
        return NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            label: c.tr('nav_teacher'));
      case AppDestination.courses:
        return NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            label: c.tr('nav_courses'));
      case AppDestination.wallet:
        return NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: c.tr('nav_wallet'));
      case AppDestination.assistant:
        return NavigationDestination(
            icon: const Icon(Icons.psychology_outlined),
            label: c.tr('nav_assistant'));
      case AppDestination.parent:
        return NavigationDestination(
            icon: const Icon(Icons.shield_outlined), label: c.tr('nav_parent'));
    }
  }

  Widget _buildBody(BuildContext context, AppDestination dest) {
    final c = controller;
    final isAr = c.language == AppLanguage.ar;
    final isStaff = RoleAccessGuard.isStaffRole(c.activeRole);
    final student = c.activeRole == UserRole.parent
        ? c.linkedParentStudent
        : c.activeStudent;

    switch (dest) {
      case AppDestination.home:
        return ListView(
          key: const ValueKey('home'),
          padding: const EdgeInsets.all(16),
          children: [
            ZeroGravityCard(
              freezeMotion: c.examModeActive,
              phaseOffset: 0.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.tr('zero_cost_badge'),
                    style: const TextStyle(
                      color: KashkoolColors.neonCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isStaff
                        ? c.tr('welcome')
                        : (isAr ? student.nameAr : student.nameEn),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!isStaff) ...[
              ZeroGravityCard(
                freezeMotion: c.examModeActive,
                phaseOffset: 1.2,
                borderColor: KashkoolColors.emeraldValid,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.tr('wallet_balance'),
                            style: const TextStyle(
                                color: KashkoolColors.textSecondary,
                                fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.formatPiasters(
                              student.walletBalancePiasters, c.language),
                          style: const TextStyle(
                            color: KashkoolColors.emeraldValid,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(c.tr('streak_days'),
                            style: const TextStyle(
                                color: KashkoolColors.textSecondary,
                                fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${student.streakDays} ${isAr ? 'يوم' : 'Days'}',
                          style: const TextStyle(
                            color: KashkoolColors.solarGold,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (c.activeRole == UserRole.student) ...[
                const SizedBox(height: 12),
                ZeroGravityCard(
                  freezeMotion: c.examModeActive,
                  phaseOffset: 2.1,
                  child: Column(
                    children: [
                      Text(c.tr('dynamic_qr_title'),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: QrImageView(
                          data: AegisQrEngine.studentTokenAt(
                              student.id, DateTime.now()),
                          size: 148,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              ZeroGravityCard(
                freezeMotion: c.examModeActive,
                phaseOffset: 1.1,
                borderColor: KashkoolColors.emeraldValid,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c.tr('attendance'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      '${c.attendance.length}',
                      style: const TextStyle(
                        color: KashkoolColors.emeraldValid,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );

      case AppDestination.assistant:
        return _AssistantView(controller: c);

      case AppDestination.wallet:
        final visibleLedger = RoleAccessGuard.canManageFinancialLedger(c.activeRole)
            ? c.ledger
            : c.ledger.where((e) => e.studentId == student.id).toList();
        return ListView(
          key: const ValueKey('wallet'),
          padding: const EdgeInsets.all(16),
          children: [
            Text(c.tr('immutable_ledger'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ...visibleLedger.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ZeroGravityCard(
                  freezeMotion: c.examModeActive,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isAr ? entry.studentNameAr : entry.studentNameEn,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            if (entry.note.isNotEmpty)
                              Text(entry.note,
                                  style: const TextStyle(
                                      color: KashkoolColors.textSecondary,
                                      fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        AppStrings.formatPiasters(
                            entry.amountPiasters, c.language),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: entry.amountPiasters < 0
                              ? KashkoolColors.crimsonBlocked
                              : KashkoolColors.emeraldValid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

      case AppDestination.courses:
        return ListView(
          key: const ValueKey('courses'),
          padding: const EdgeInsets.all(16),
          children: [
            Text(c.tr('courses_tab'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ...SeedData.courses.map(
              (crs) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ZeroGravityCard(
                  freezeMotion: c.examModeActive,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isAr ? crs.titleAr : crs.titleEn,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(isAr ? crs.summaryAr : crs.summaryEn,
                          style: const TextStyle(
                              color: KashkoolColors.textSecondary,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

      case AppDestination.desk:
      case AppDestination.teacher:
      case AppDestination.analytics:
      case AppDestination.parent:
        return ListView(
          key: ValueKey(dest.name),
          padding: const EdgeInsets.all(16),
          children: [
            ZeroGravityCard(
              freezeMotion: c.examModeActive,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? student.nameAr : student.nameEn,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${c.tr('student_mastery')}: ${student.masteryPercent}%',
                    style: const TextStyle(color: KashkoolColors.neonCyan),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}

class _AssistantView extends StatefulWidget {
  final KashkoolController controller;

  const _AssistantView({required this.controller});

  @override
  State<_AssistantView> createState() => _AssistantViewState();
}

class _AssistantViewState extends State<_AssistantView> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: c.assistantMessages.length,
            itemBuilder: (context, idx) {
              final msg = c.assistantMessages[idx];
              return Align(
                alignment: msg.fromUser
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: msg.fromUser
                        ? KashkoolColors.neonCyan.withValues(alpha: 0.16)
                        : KashkoolColors.spaceSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: msg.fromUser
                          ? KashkoolColors.neonCyan.withValues(alpha: 0.45)
                          : Colors.white12,
                    ),
                  ),
                  child: Text(msg.text),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: c.tr('assistant_hint'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SpaceButton(
                label: c.tr('send'),
                icon: Icons.send,
                onPressedAsync: c.assistantBusy
                    ? null
                    : () async {
                        final text = _ctrl.text;
                        _ctrl.clear();
                        await c.askAssistant(text);
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
