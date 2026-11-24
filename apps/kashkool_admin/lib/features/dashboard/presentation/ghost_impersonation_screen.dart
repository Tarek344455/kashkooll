import 'dart:ui';
import 'package:material_ui/material_ui.dart';

/// شاشة الدخول الشبحي — God-Mode Ghost Impersonation
/// السوبر أدمن يدخل بهوية أي مستخدم (مدرس / سكرتيرة / ولي أمر) لمراقبة التجربة
/// واجهة كونية عائمة بالكامل

class GhostImpersonationScreen extends StatefulWidget {
  const GhostImpersonationScreen({super.key});

  @override
  State<GhostImpersonationScreen> createState() => _GhostImpersonationScreenState();
}

class _GhostImpersonationScreenState extends State<GhostImpersonationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glitchCtrl;
  late Animation<double> _glitchAnim;

  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedRole = 'الكل';
  String? _activeSession;

  final List<String> _roles = ['الكل', 'مدرس', 'سكرتيرة', 'ولي أمر', 'طالب', 'مدير سنتر'];

  final List<Map<String, dynamic>> _mockUsers = [
    {'id': 'usr-001', 'name': 'أ. محمد الشافعي', 'role': 'مدرس', 'center': 'سنتر النجوم — القاهرة', 'active': true},
    {'id': 'usr-002', 'name': 'سارة عبد الرحمن', 'role': 'سكرتيرة', 'center': 'سنتر الفتح — الإسكندرية', 'active': true},
    {'id': 'usr-003', 'name': 'ولي أمر: أحمد مجدي', 'role': 'ولي أمر', 'center': 'سنتر المستقبل — الجيزة', 'active': false},
    {'id': 'usr-004', 'name': 'مريم حسن', 'role': 'طالب', 'center': 'سنتر النجوم — القاهرة', 'active': true},
    {'id': 'usr-005', 'name': 'خالد إبراهيم', 'role': 'مدير سنتر', 'center': 'سنتر الأمل — أسيوط', 'active': true},
  ];

  @override
  void initState() {
    super.initState();
    _glitchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glitchAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glitchCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glitchCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _mockUsers.where((u) {
      final matchRole = _selectedRole == 'الكل' || u['role'] == _selectedRole;
      final matchSearch = q.isEmpty ||
          (u['name'] as String).toLowerCase().contains(q) ||
          (u['center'] as String).toLowerCase().contains(q);
      return matchRole && matchSearch;
    }).toList();
  }

  void _startImpersonation(Map<String, dynamic> user) {
    setState(() => _activeSession = user['id'] as String);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0D1B3E),
        content: Row(
          children: [
            const Icon(Icons.visibility_rounded, color: Color(0xFFFF6B35)),
            const SizedBox(width: 8),
            Text(
              '👻 جلسة شبحية نشطة — ${user['name']}',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'إنهاء',
          textColor: const Color(0xFF00F5D4),
          onPressed: () => setState(() => _activeSession = null),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // خلفية كونية
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D0D1A), Color(0xFF1A0D2E), Color(0xFF0D1A1A)],
              ),
            ),
          ),
          // تأثير الطيف الشبحي
          AnimatedBuilder(
            animation: _glitchAnim,
            builder: (_, __) => Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF6B35).withValues(alpha: 0.08 * _glitchAnim.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── AppBar ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _buildGlassAppBar(),
                ),
                const SizedBox(height: 12),
                // ── Search + Filter ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSearchBar(),
                ),
                const SizedBox(height: 10),
                // ── Role chips ────────────────────────────────────────────
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _roles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _roleChip(_roles[i]),
                  ),
                ),
                const SizedBox(height: 12),
                // ── User List ─────────────────────────────────────────────
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _UserGhostCard(
                      user: _filtered[i],
                      isActiveSession: _activeSession == _filtered[i]['id'],
                      onImpersonate: () => _startImpersonation(_filtered[i]),
                      onEnd: () => setState(() => _activeSession = null),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70, size: 20),
              ),
              const SizedBox(width: 12),
              AnimatedBuilder(
                animation: _glitchAnim,
                builder: (_, __) => Icon(
                  Icons.psychology_rounded,
                  color: Color.lerp(
                      const Color(0xFFFF6B35), const Color(0xFFFFD700), _glitchAnim.value),
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '👻 الدخول الشبحي',
                    style: TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text('انتحال هوية آمن للمراقبة',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'ابحث بالاسم أو السنتر...',
              hintStyle: TextStyle(color: Colors.white38),
              prefixIcon: Icon(Icons.search_rounded, color: Colors.white38),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleChip(String role) {
    final selected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFF6B35).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF6B35)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          role,
          style: TextStyle(
            color: selected ? const Color(0xFFFF6B35) : Colors.white60,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _UserGhostCard extends StatelessWidget {
  const _UserGhostCard({
    required this.user,
    required this.isActiveSession,
    required this.onImpersonate,
    required this.onEnd,
  });

  final Map<String, dynamic> user;
  final bool isActiveSession;
  final VoidCallback onImpersonate;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final isOnline = user['active'] as bool;
    final neonColor = isActiveSession ? const Color(0xFFFF6B35) : Colors.white.withValues(alpha: 0.15);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isActiveSession
                ? const Color(0xFFFF6B35).withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: neonColor, width: isActiveSession ? 1.5 : 1.0),
          ),
          child: Row(
            children: [
              // avatar
              Stack(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                      border: Border.all(
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (user['name'] as String)[0],
                        style: const TextStyle(
                          color: Color(0xFFFF6B35),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? const Color(0xFF00F5D4) : Colors.grey,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] as String,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${user['role']} — ${user['center']}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isActiveSession)
                      const Text(
                        '👁️ جلسة شبحية نشطة',
                        style: TextStyle(color: Color(0xFFFF6B35), fontSize: 11),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              isActiveSession
                  ? GestureDetector(
                      onTap: onEnd,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC143C).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDC143C).withValues(alpha: 0.5)),
                        ),
                        child: const Text(
                          'إنهاء',
                          style: TextStyle(color: Color(0xFFDC143C), fontSize: 11),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: onImpersonate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.4)),
                        ),
                        child: const Text(
                          '👻 ادخل',
                          style: TextStyle(color: Color(0xFFFF6B35), fontSize: 11),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
