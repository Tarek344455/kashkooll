import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kashkool_core/kashkool_core.dart';
import '../../features/auth/presentation/home_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/not_linked_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/billing/presentation/payment_gateway_screen.dart';
import '../../features/billing/presentation/pdf_receipt_screen.dart';
import '../../features/billing/presentation/pricing_calculator.dart';
import '../../features/billing/presentation/certificate_verify_screen.dart';
import '../../features/billing/presentation/certificates_screen.dart';
import '../../features/billing/presentation/installment_plan_screen.dart';
import '../../features/billing/presentation/student_checkout_screen.dart';
import '../../features/billing/presentation/student_payment_tracking_screen.dart';
import '../../features/billing/presentation/usage_metering_screen.dart';
import '../../features/center_ops/presentation/auto_queue_desk_screen.dart';
import '../../features/center_ops/presentation/floating_settlement_screen.dart';
import '../../features/center_ops/presentation/group_management_screen.dart';
import '../../features/center_ops/presentation/qr_checkin_screen.dart';
import '../../features/center_ops/presentation/secretary_desk_screen.dart';
import '../../features/center_ops/presentation/teacher_dashboard_screen.dart';
import '../../features/courses_live/presentation/course_tree_screen.dart';
import '../../features/courses_live/presentation/drm_lecture_player.dart';
import '../../features/courses_live/presentation/live_classroom_screen.dart';
import '../../features/assessments/presentation/quiz_runner_screen.dart';
import '../../features/community/presentation/discussion_room_screen.dart';
import '../../features/parent_portal/presentation/parent_dashboard_screen.dart';
import '../../features/study_assistant/presentation/study_assistant_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey(debugLabel: 'root');

/// Application router. Kept as a plain provider (not generated) so the app
/// doesn't depend on build_runner output for navigation.
final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;
      final onLogin = path == '/';
      final onNotLinked = path == '/not-linked';

      switch (auth.status) {
        case AuthStatus.initial:
        case AuthStatus.sendingCode:
        case AuthStatus.codeSent:
        case AuthStatus.emailSent:
        case AuthStatus.verifying:
        case AuthStatus.verifyingEmail:
        case AuthStatus.qrActivated:
          return onLogin ? null : '/';
        case AuthStatus.notLinked:
          return onNotLinked ? null : '/not-linked';
        case AuthStatus.onboarded:
          return (onLogin || onNotLinked) ? '/home' : null;
      }
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/not-linked',
        builder: (context, state) => const NotLinkedScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/secretary-desk',
        builder: (context, state) => const SecretaryDeskScreen(),
      ),
      GoRoute(
        path: '/teacher-dashboard',
        builder: (context, state) => const TeacherDashboardScreen(),
      ),
      GoRoute(
        path: '/group-management',
        builder: (context, state) => const GroupManagementScreen(),
      ),
      GoRoute(
        path: '/floating-settlement',
        builder: (context, state) => const FloatingSettlementScreen(),
      ),
      GoRoute(
        path: '/auto-queue-desk',
        builder: (context, state) => const AutoQueueDeskScreen(),
      ),
      GoRoute(
        path: '/course-tree',
        builder: (context, state) => const CourseTreeScreen(),
      ),
      GoRoute(
        path: '/drm-player',
        builder: (context, state) => const DrmLecturePlayer(),
      ),
      GoRoute(
        path: '/live-classroom',
        builder: (context, state) => const LiveClassroomScreen(),
      ),
      GoRoute(
        path: '/quiz',
        builder: (context, state) => const QuizRunnerScreen(),
      ),
      GoRoute(
        path: '/discussion-room',
        builder: (context, state) => const DiscussionRoomScreen(),
      ),
      GoRoute(
        path: '/study-assistant',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return StudyAssistantScreen(
            subject: params['subject'] ?? 'المنهج الدراسي',
            lesson: params['lesson'] ?? 'الدرس الحالي',
            initialTeacherMode: params['mode'] == 'teacher',
          );
        },
      ),
      GoRoute(
        path: '/parent-portal',
        builder: (context, state) => const ParentDashboardScreen(),
      ),
      GoRoute(
        path: '/payment-gateway',
        builder: (context, state) => const PaymentGatewayScreen(
          moduleIds: [],
          amountEgp: 0,
        ),
      ),
      GoRoute(
        path: '/qr-checkin',
        builder: (context, state) => const QrCheckinScreen(sessionId: ''),
      ),
      GoRoute(
        path: '/pricing-calculator',
        builder: (context, state) => const PricingCalculator(
          accountType: AccountType.center,
        ),
      ),
      GoRoute(
        path: '/usage-metering',
        builder: (context, state) => const UsageMeteringScreen(accountId: ''),
      ),
      GoRoute(
        path: '/student-checkout',
        builder: (context, state) => const StudentCheckoutScreen(),
      ),
      GoRoute(
        path: '/student-payment-tracking',
        builder: (context, state) => const StudentPaymentTrackingScreen(),
      ),
      GoRoute(
        path: '/installment-plan',
        builder: (context, state) => const InstallmentPlanScreen(),
      ),
      GoRoute(
        path: '/certificates',
        builder: (context, state) => const CertificatesScreen(),
      ),
      GoRoute(
        path: '/certificate-verify',
        builder: (context, state) => const CertificateVerifyScreen(),
      ),
      GoRoute(
        path: '/pdf-receipt',
        builder: (context, state) => const PdfReceiptScreen(transactionId: ''),
      ),
    ],
  );
});
