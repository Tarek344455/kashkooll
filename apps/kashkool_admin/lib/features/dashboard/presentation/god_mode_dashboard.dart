import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/kill_switch_service.dart';
import '../../../core/telemetry_service.dart';
import '../../audit/presentation/audit_logs_screen.dart';
import '../../tenants/presentation/tenant_manager_screen.dart';
import '../../payments/presentation/payment_channels_screen.dart';
import '../../payments/presentation/payment_review_queue_screen.dart';
import 'telemetry_screen.dart';
import 'ghost_impersonation_screen.dart';
import 'fraud_radar_screen.dart';

// ─── Cosmic God-Mode Dashboard ─────────────────────────────────────────────
// واجهة القيادة السيادية الكونية — CosmicScaffold + FloatingGlassCard
// بدون Scaffold عادي واحد — كل البطاقات عائمة تحت خلفية سديمية
// ─────────────────────────────────────────────────────────────────────────────

class GodModeDashboard extends ConsumerStatefulWidget {
  const GodModeDashboard({super.key});

  @override
  ConsumerState<GodModeDashboard> createState() => _GodModeDashboardState();
}

class _GodModeDashboardState extends ConsumerState<GodModeDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(killSwitchServiceProvider).load();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(killSwitchServiceProvider).load();
    ref.invalidate(systemMetricsProvider);
    ref.invalidate(governorateCountsProvider);
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final switches = ref.watch(killSwitchServiceProvider);
    final isKillActive = switches.isGlobalKillSwitchActive;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── خلفية سديمية كونية ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.3, -0.5),
                radius: 1.4,
                colors: [
                  Color(0xFF0D1B3E),
                  Color(0xFF06060F),
                  Color(0xFF000005),
                ],
              ),
            ),
          ),
          // نجوم متحركة
          ...List.generate(30, (i) {
            final x = (i * 37 % 100) / 100.0;
            final y = (i * 59 % 100) / 100.0;
            final size = (i % 3 + 1).toDouble();
            return Positioned(
              left: MediaQuery.of(context).size.width * x,
              top: MediaQuery.of(context).size.height * y,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Opacity(
                  opacity: ((i % 5) == 0 ? _pulseAnim.value : 0.4),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }),
          // نيون أحمر إذا Kill Switch نشط
          if (isKillActive)
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.0,
                    colors: [
                      const Color(0xFFDC143C).withValues(alpha: 0.15 * _pulseAnim.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          // ── المحتوى الرئيسي ──────────────────────────────────────────────
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFFFFD700),
              backgroundColor: const Color(0xFF0D1B3E),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── AppBar عائم ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _buildGlassAppBar(isKillActive),
                    ),
                  ),
                  // ── بطاقة Kill Switch ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _KillSwitchGlassCard(
                        switches: switches,
                        pulseAnim: _pulseAnim,
                        onRetry: () => ref.read(killSwitchServiceProvider).load(),
                      ),
                    ),
                  ),
                  // ── Error banner ─────────────────────────────────────────
                  if (switches.error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _GlassErrorBanner(
                          message: switches.error!,
                          onRetry: () => ref.read(killSwitchServiceProvider).load(),
                        ),
                      ),
                    ),
                  // ── Metrics ──────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: const _MetricsGlassSection(),
                    ),
                  ),
                  // ── Feature Flags ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _FeatureFlagsGlassCard(switches: switches),
                    ),
                  ),
                  // ── Navigation Grid ───────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                      ),
                      delegate: SliverChildListDelegate([
                        _CosmicNavCard(
                          icon: Icons.business_rounded,
                          title: 'مراكز مصر',
                          subtitle: 'إدارة السناتر',
                          neonColor: const Color(0xFF00F5D4),
                          onTap: () => _open(const TenantManagerScreen()),
                        ),
                        _CosmicNavCard(
                          icon: Icons.payment,
                          title: 'قنوات الدفع',
                          subtitle: 'إعداد قنوات المدفوعات',
                          neonColor: const Color(0xFF00F5D4),
                          onTap: () => _open(const PaymentChannelsScreen()),
                        ),
                        _CosmicNavCard(
                          icon: Icons.verified_user,
                          title: 'مراجعة الإيصالات',
                          subtitle: 'موافقة ومراجعة 1-tap',
                          neonColor: const Color(0xFFFFD700),
                          onTap: () => _open(const PaymentReviewQueueScreen()),
                        ),
                        _CosmicNavCard(
                          icon: Icons.map_rounded,
                          title: 'رادار مصر',
                          subtitle: 'خريطة حية',
                          neonColor: const Color(0xFF7B2FFF),
                          onTap: () => _open(const TelemetryScreen()),
                        ),
                        _CosmicNavCard(
                          icon: Icons.receipt_long_rounded,
                          title: 'سجل التدقيق',
                          subtitle: 'كل حركة موثقة',
                          neonColor: const Color(0xFFFFD700),
                          onTap: () => _open(const AuditLogsScreen()),
                        ),
                        _CosmicNavCard(
                          icon: Icons.psychology_rounded,
                          title: 'دخول شبحي',
                          subtitle: 'انتحال هوية',
                          neonColor: const Color(0xFFFF6B35),
                          onTap: () => _open(const GhostImpersonationScreen()),
                        ),
                        _CosmicNavCard(
                          icon: Icons.radar_rounded,
                          title: 'رادار الاحتيال',
                          subtitle: 'تحريات مالية',
                          neonColor: const Color(0xFFDC143C),
                          onTap: () => _open(const FraudRadarScreen()),
                        ),
                        _CosmicNavCard(
                          icon: Icons.settings_suggest_rounded,
                          title: 'ضبط النظام',
                          subtitle: 'إعدادات عميقة',
                          neonColor: const Color(0xFF00BFFF),
                          onTap: () {},
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar(bool isKillActive) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isKillActive
                  ? const Color(0xFFDC143C).withValues(alpha: 0.6)
                  : const Color(0xFFFFD700).withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Icon(
                  Icons.shield_rounded,
                  color: isKillActive
                      ? Color.lerp(const Color(0xFFDC143C), Colors.orange, _pulseAnim.value)
                      : const Color(0xFFFFD700),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Command Centre',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    isKillActive ? '⚠️ Kill Switch نشط' : '✅ النظام يعمل',
                    style: TextStyle(
                      color: isKillActive ? const Color(0xFFDC143C) : const Color(0xFF00F5D4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: _refresh,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Kill Switch Card ─────────────────────────────────────────────────────────
class _KillSwitchGlassCard extends ConsumerWidget {
  const _KillSwitchGlassCard({
    required this.switches,
    required this.pulseAnim,
    required this.onRetry,
  });

  final KillSwitchService switches;
  final Animation<double> pulseAnim;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = switches.isGlobalKillSwitchActive;
    final neonColor = active ? const Color(0xFFDC143C) : const Color(0xFF00F5D4);

    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFFDC143C).withValues(alpha: 0.1 * pulseAnim.value)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: neonColor.withValues(alpha: active ? 0.7 * pulseAnim.value : 0.4),
                width: active ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: neonColor.withValues(alpha: active ? 0.25 * pulseAnim.value : 0.1),
                  blurRadius: active ? 20 : 8,
                  spreadRadius: active ? 2 : 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      active ? Icons.power_off_rounded : Icons.power_rounded,
                      color: neonColor,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      active ? '🚨 صمام الأمان النووي — نشط' : '🔒 صمام الأمان — مغلق',
                      style: TextStyle(
                        color: neonColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: active,
                      activeThumbColor: const Color(0xFFDC143C),
                      inactiveThumbColor: const Color(0xFF00F5D4),
                      onChanged: (val) =>
                          ref.read(killSwitchServiceProvider).toggleKillSwitch(val),
                    ),
                  ],
                ),
                if (active) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC143C).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '⚠️ جميع العمليات موقوفة — الطلاب لا يمكنهم الدخول',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Metrics Section ──────────────────────────────────────────────────────────
class _MetricsGlassSection extends ConsumerWidget {
  const _MetricsGlassSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(systemMetricsProvider);

    return metrics.when(
      loading: () => SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFFFFD700).withValues(alpha: 0.7),
            strokeWidth: 2,
          ),
        ),
      ),
      error: (_, __) => _glassMetricCard(
        icon: Icons.error_outline,
        label: 'خطأ في التحميل',
        value: '—',
        neonColor: const Color(0xFFDC143C),
      ),
      data: (value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 مؤشرات النظام الحية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.8,
            children: [
              _glassMetricCard(
                icon: Icons.business_rounded,
                label: 'سناتر نشطة',
                value: '${value.activeTenants}',
                neonColor: const Color(0xFF00F5D4),
              ),
              _glassMetricCard(
                icon: Icons.people_rounded,
                label: 'طلاب متصلون',
                value: '${value.activeStudents}',
                neonColor: const Color(0xFF7B2FFF),
              ),
              _glassMetricCard(
                icon: Icons.video_call_rounded,
                label: 'حصص حية الآن',
                value: '${value.liveSessions}',
                neonColor: const Color(0xFFFFD700),
              ),
              _glassMetricCard(
                icon: Icons.warning_rounded,
                label: 'تنبيهات معلقة',
                value: '${value.pendingAlerts}',
                neonColor: value.pendingAlerts > 0
                    ? const Color(0xFFDC143C)
                    : const Color(0xFF00F5D4),
                isDanger: value.pendingAlerts > 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _glassMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color neonColor,
    bool isDanger = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: neonColor.withValues(alpha: 0.35), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: neonColor.withValues(alpha: isDanger ? 0.2 : 0.08),
                blurRadius: isDanger ? 12 : 6,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: neonColor, size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Feature Flags Glass Card ─────────────────────────────────────────────────
class _FeatureFlagsGlassCard extends ConsumerWidget {
  const _FeatureFlagsGlassCard({required this.switches});
  final KillSwitchService switches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.toggle_on_rounded, color: Color(0xFFFFD700), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'صمامات الميزات',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...switches.featureKeys
                  .where((k) => k != 'global_emergency')
                  .map((key) => _FeatureFlagTile(featureKey: key, switches: switches)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureFlagTile extends ConsumerWidget {
  const _FeatureFlagTile({required this.featureKey, required this.switches});
  final String featureKey;
  final KillSwitchService switches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = switches.isFeatureEnabled(featureKey);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? const Color(0xFF00F5D4) : Colors.white24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _humanize(featureKey),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          Switch(
            value: enabled,
            activeThumbColor: const Color(0xFF00F5D4),
            onChanged: (val) =>
                ref.read(killSwitchServiceProvider).setFeature(featureKey, val),
          ),
        ],
      ),
    );
  }

  static String _humanize(String key) {
    return key
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

// ─── Cosmic Nav Card ──────────────────────────────────────────────────────────
class _CosmicNavCard extends StatelessWidget {
  const _CosmicNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.neonColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color neonColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: neonColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: neonColor.withValues(alpha: 0.4), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: neonColor.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: neonColor, size: 28),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Error Banner ─────────────────────────────────────────────────────────────
class _GlassErrorBanner extends StatelessWidget {
  const _GlassErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFDC143C).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDC143C).withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFDC143C), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                child: const Text('إعادة', style: TextStyle(color: Color(0xFFFFD700))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
