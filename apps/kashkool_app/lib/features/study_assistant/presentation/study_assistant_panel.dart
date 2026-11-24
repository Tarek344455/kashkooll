import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/spaceship_ai_client.dart';
import '../../../core/theme/glass_widgets.dart';
import '../data/study_assistant_repository.dart';
import '../providers/study_assistant_controller.dart';

const Color _studentAccent = Color(0xFF00F5D4);
const Color _teacherAccent = Color(0xFFF59E0B);

/// The study assistant surface.
///
/// Used by both the full screen and the drawer, so the four required states
/// live in exactly one place: loading (probe + answer), empty, error with
/// retry, and the populated conversation.
class StudyAssistantPanel extends ConsumerStatefulWidget {
  const StudyAssistantPanel({
    super.key,
    required this.subject,
    required this.lesson,
    this.role = KashkoolAiRole.student,
    this.allowModeSwitch = false,
    this.tenantId,
    this.onClose,
  });

  final String subject;
  final String lesson;

  /// Academic voice the panel opens in.
  final KashkoolAiRole role;

  /// Teacher accounts may preview the student voice, and vice versa.
  final bool allowModeSwitch;

  final String? tenantId;

  /// Null when hosted in a screen; closes the hosting drawer otherwise.
  final VoidCallback? onClose;

  @override
  ConsumerState<StudyAssistantPanel> createState() =>
      _StudyAssistantPanelState();
}

class _StudyAssistantPanelState extends ConsumerState<StudyAssistantPanel> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  late bool _teacherMode;
  int _renderedMessages = 0;

  KashkoolAiRole get _effectiveRole {
    if (!widget.allowModeSwitch) return widget.role;
    return _teacherMode ? KashkoolAiRole.teacher : KashkoolAiRole.student;
  }

  Color get _accent => _effectiveRole == KashkoolAiRole.teacher
      ? _teacherAccent
      : _studentAccent;

  @override
  void initState() {
    super.initState();
    _teacherMode = widget.role == KashkoolAiRole.teacher;
    // Provider writes are not allowed during the build phase, so bind after
    // the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindContext());
  }

  @override
  void didUpdateWidget(StudyAssistantPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subject != widget.subject ||
        oldWidget.lesson != widget.lesson ||
        oldWidget.role != widget.role) {
      _teacherMode = widget.role == KashkoolAiRole.teacher;
      WidgetsBinding.instance.addPostFrameCallback((_) => _bindContext());
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _bindContext() {
    if (!mounted) return;
    final notifier = ref.read(studyAssistantProvider.notifier);
    // configure() binds the lesson synchronously and then probes the gateway;
    // the role is applied right away so a toggle never waits for the probe.
    notifier.configure(
      StudyAssistantContext(
        subject: widget.subject,
        lesson: widget.lesson,
        role: _effectiveRole,
        tenantId: widget.tenantId,
      ),
    );
    notifier.setRole(_effectiveRole);
  }

  void _send([String? preset]) {
    final text = preset ?? _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    ref.read(studyAssistantProvider.notifier).send(text);
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyAssistantProvider);

    if (state.messages.length != _renderedMessages) {
      _renderedMessages = state.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(state),
              const SizedBox(height: 12),
              Expanded(child: _buildBody(state)),
              const SizedBox(height: 10),
              _InputBar(
                controller: _input,
                accent: _accent,
                hint: _effectiveRole == KashkoolAiRole.teacher
                    ? 'اطلب توليد أسئلة أو خطة درس...'
                    : 'اسأل في أي خطوة مش فاهمها...',
                enabled: !state.isSending && state.context != null,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(StudyAssistantState state) {
    final reachability = state.gatewayReachable;
    final (Color dotColor, String statusLabel) = switch (reachability) {
      null => (const Color(0xFF94A3B8), 'جارٍ الفحص'),
      true => (const Color(0xFF10B981), 'متصل'),
      false => (const Color(0xFFF43F5E), 'غير متصل'),
    };

    return FloatingGlassCard(
      glowColor: _accent,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accent.withValues(alpha: 0.18),
                  border: Border.all(color: _accent),
                ),
                child: Icon(Icons.auto_stories, color: _accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _effectiveRole == KashkoolAiRole.teacher
                          ? 'مساعد المعلم'
                          : 'المساعد الدراسي',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.lesson,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: statusLabel,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: [
                      BoxShadow(color: dotColor.withValues(alpha: 0.6), blurRadius: 8),
                    ],
                  ),
                ),
              ),
              if (state.messages.isNotEmpty)
                IconButton(
                  tooltip: 'محادثة جديدة',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh, color: Colors.white54, size: 19),
                  onPressed: () {
                    ref.read(studyAssistantProvider.notifier).clearConversation();
                    _input.clear();
                  },
                ),
              if (widget.onClose != null)
                IconButton(
                  tooltip: 'إغلاق',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                  onPressed: widget.onClose,
                ),
            ],
          ),
          if (widget.allowModeSwitch) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _teacherMode
                        ? 'وضع المعلم: توليد شيتات وأسئلة'
                        : 'وضع الطالب: شرح وتوجيه تفاعلي',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: _teacherMode,
                    activeThumbColor: _teacherAccent,
                    activeTrackColor: _teacherAccent.withValues(alpha: 0.3),
                    inactiveThumbColor: _studentAccent,
                    inactiveTrackColor: _studentAccent.withValues(alpha: 0.3),
                    onChanged: (value) {
                      setState(() => _teacherMode = value);
                      ref.read(studyAssistantProvider.notifier).setRole(_effectiveRole);
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(StudyAssistantState state) {
    final isInitialLoad = state.isProbing && state.messages.isEmpty;

    if (isInitialLoad) {
      return const _LoadingState();
    }

    if (state.messages.isEmpty) {
      if (state.errorMessage != null) {
        return _ErrorState(
          message: state.errorMessage!,
          retryLabel: 'إعادة المحاولة',
          onRetry: () => ref.read(studyAssistantProvider.notifier).probe(),
        );
      }
      return _EmptyState(
        accent: _accent,
        lesson: widget.lesson,
        isTeacher: _effectiveRole == KashkoolAiRole.teacher,
        onStart: _send,
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.only(bottom: 4),
      itemCount: state.messages.length +
          (state.isSending ? 1 : 0) +
          (state.errorMessage != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < state.messages.length) {
          final message = state.messages[index];
          final isLast = index == state.messages.length - 1;
          return _MessageBubble(
            message: message,
            accent: _accent,
            showSuggestions: isLast && !state.isSending,
            onSuggestionTap: _send,
          );
        }

        final extraIndex = index - state.messages.length;
        if (state.isSending && extraIndex == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _TypingBubble(),
          );
        }

        return _InlineError(
          message: state.errorMessage!,
          onRetry: () {
            final notifier = ref.read(studyAssistantProvider.notifier);
            if (state.failedPrompt != null) {
              notifier.retry();
            } else {
              notifier.probe();
            }
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        _SkeletonBubble(lines: 3, isAssistant: true),
        _SkeletonBubble(lines: 2, isAssistant: false),
        _SkeletonBubble(lines: 4, isAssistant: true),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.accent,
    required this.lesson,
    required this.isTeacher,
    required this.onStart,
  });

  final Color accent;
  final String lesson;
  final bool isTeacher;
  final void Function([String? prompt]) onStart;

  @override
  Widget build(BuildContext context) {
    final starters = isTeacher
        ? const [
            'ولّد لي 5 أسئلة MCQ على هذا الدرس بمستويات متدرجة.',
            'اقترح خطة درس 45 دقيقة لهذا الدرس.',
            'اكتب سؤال مقالي مع نموذج إجابة قصير.',
          ]
        : const [
            'ابدأ معايا الدرس بسؤال سهل يشوف مستواي.',
            'اشرح لي الفكرة الأساسية بمثال من الامتحانات.',
            'اديني مسألة متوسطة وأنا أحلها خطوة بخطوة.',
          ];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FloatingGlassCard(
            glowColor: accent,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_stories, color: accent, size: 30),
                const SizedBox(height: 12),
                Text(
                  isTeacher ? 'جاهز لتجهيز الشيت' : 'جاهز نبدأ الدرس',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isTeacher
                      ? 'اطلب أسئلة أو خطة لدرس «$lesson» وسأجهزها بمستوياتها ونموذج الإجابة.'
                      : 'هنمشي خطوة بخطوة على درس «$lesson» من غير ما أديك الحل جاهز، لحد ما تمسكه بنفسك.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                NeonButton(
                  glowColor: accent,
                  onPressed: () => onStart(
                    isTeacher
                        ? 'ابدأ بخطة سريعة لدرس «$lesson».'
                        : 'ابدأ معايا درس «$lesson» بسؤال واحد سهل.',
                  ),
                  child: Text(isTeacher ? 'ابدأ التجهيز' : 'ابدأ الشرح'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final starter in starters)
                  _SuggestionChip(
                    label: starter,
                    accent: accent,
                    onTap: () => onStart(starter),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: FloatingGlassCard(
          glowColor: const Color(0xFFF43F5E),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: Color(0xFFF43F5E), size: 30),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
              ),
              const SizedBox(height: 16),
              NeonButton(glowColor: const Color(0xFFF43F5E), onPressed: onRetry, child: Text(retryLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FloatingGlassCard(
        glowColor: const Color(0xFFF43F5E),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFF43F5E), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(color: Color(0xFFF43F5E), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conversation pieces
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.accent,
    required this.showSuggestions,
    required this.onSuggestionTap,
  });

  final StudyAssistantMessage message;
  final Color accent;
  final bool showSuggestions;
  final void Function([String? prompt]) onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final isAssistant = message.isAssistant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isAssistant ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          FloatingGlassCard(
            glowColor: isAssistant ? accent : Colors.white24,
            borderRadius: 14,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAssistant ? Icons.auto_stories : Icons.person,
                      size: 13,
                      color: isAssistant ? accent : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAssistant ? 'المساعد' : 'أنا',
                      style: TextStyle(
                        color: isAssistant ? accent : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ),
          if (showSuggestions && message.suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final suggestion in message.suggestions)
                    _SuggestionChip(
                      label: suggestion,
                      accent: accent,
                      onTap: () => onSuggestionTap(suggestion),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Animated skeleton shown while an answer is in flight.
class _SkeletonBubble extends StatefulWidget {
  const _SkeletonBubble({required this.lines, required this.isAssistant});

  final int lines;
  final bool isAssistant;

  @override
  State<_SkeletonBubble> createState() => _SkeletonBubbleState();
}

class _SkeletonBubbleState extends State<_SkeletonBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isAssistant ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FloatingGlassCard(
          borderRadius: 14,
          padding: const EdgeInsets.all(14),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final opacity = 0.10 + (_controller.value * 0.18);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < widget.lines; i++)
                    Container(
                      width: i.isEven ? 180 : 130,
                      height: 9,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Three-dot indicator while the answer streams in.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: FloatingGlassCard(
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: 0.25 + 0.5 * (((_controller.value + i / 3) % 1) * 2 - 1).abs(),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.accent,
    required this.hint,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final Color accent;
  final String hint;
  final bool enabled;
  final void Function([String? prompt]) onSend;

  @override
  Widget build(BuildContext context) {
    return FloatingGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      borderRadius: 24,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                border: InputBorder.none,
              ),
              onSubmitted: enabled ? (_) => onSend() : null,
            ),
          ),
          IconButton(
            tooltip: 'إرسال',
            icon: Icon(
              Icons.send_rounded,
              color: enabled ? accent : Colors.white24,
              size: 22,
            ),
            onPressed: enabled ? () => onSend() : null,
          ),
        ],
      ),
    );
  }
}
