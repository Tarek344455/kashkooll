# 🛡️ SKILL: Egypt Market — 3-Second Queue Rule
**ID:** `kashkool-egypt-3sec-queue-v1`
**Activation:** AUTOMATIC — Triggers on any secretary-facing action, QR scan, attendance marking, or quick-action in `kashkool_app`, `kashkool_admin`
**Enforcement Level:** MANDATORY — Part I Pillar 1 of Supreme Constitution

---

## 🎯 PURPOSE
Enforce **3-Second Queue Rule** (Part I, Pillar 1): Secretary actions complete in **1 tap/scan (<1 sec)** with Green/Amber/Red color feedback. Audio/Haptic confirmation.

---

## 🔄 AUTO-ACTIVATION TRIGGERS
- Creating secretary screens (attendance, registration, payments)
- Implementing QR code scanning
- Adding quick-action buttons
- Designing secretary workflows

---

## 📋 3-SECOND QUEUE SPECIFICATION

### 1. One Tap/Scan — <1 Second Completion
```dart
// Secretary QR Scan → Attendance Marked in <1s
class SecretaryAttendanceScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return QRScannerOverlay(
      onScan: (qrData) async {
        // IMMEDIATE visual feedback (<100ms)
        ref.read(feedbackProvider.notifier).showScanning();
        
        // Optimistic UI update
        final studentId = _parseStudentId(qrData);
        ref.read(attendanceProvider(studentId).notifier).markPresentOptimistic();
        
        // Background sync (non-blocking)
        unawaited(_syncAttendance(studentId));
      },
    );
  }
  
  Future<void> _syncAttendance(String studentId) async {
    try {
      await ref.read(attendanceRepositoryProvider).markAttendance(studentId);
      ref.read(feedbackProvider.notifier).showSuccess(); // Green
    } catch (e) {
      ref.read(attendanceProvider(studentId).notifier).revertOptimistic();
      ref.read(feedbackProvider.notifier).showError(e); // Red
    }
  }
}
```

### 2. Color Feedback System (Green/Amber/Red)
```dart
// Required feedback component
class SecretaryFeedback extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(feedbackProvider);
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: switch (state) {
        FeedbackState.success => _FeedbackBadge(
            key: const ValueKey('success'),
            color: Colors.green,
            icon: Icons.check_circle,
            label: context.l10n.feedbackSuccess,
            haptic: HapticFeedbackType.success,
          ),
        FeedbackState.warning => _FeedbackBadge(
            key: const ValueKey('warning'),
            color: Colors.amber,
            icon: Icons.warning,
            label: context.l10n.feedbackPending,
            haptic: HapticFeedbackType.warning,
          ),
        FeedbackState.error => _FeedbackBadge(
            key: const ValueKey('error'),
            color: Colors.red,
            icon: Icons.error,
            label: context.l10n.feedbackFailed,
            haptic: HapticFeedbackType.error,
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

// Semantic colors (Space Glass design system)
class SecretaryColors {
  static const Color success = Color(0xFF00C853);  // Green - confirmed
  static const Color warning = Color(0xFFFFD600);  // Amber - pending/syncing
  static const Color error = Color(0xFFFF1744);    // Red - failed
}
```

### 3. Audio/Haptic Confirmation
```dart
// Required on every secretary action
enum HapticFeedbackType { success, warning, error, selection }

class HapticService {
  static void trigger(HapticFeedbackType type) {
    switch (type) {
      case HapticFeedbackType.success:
        HapticFeedback.heavyImpact(); // Strong confirmation
        _playSound('success.wav');
      case HapticFeedbackType.warning:
        HapticFeedback.mediumImpact();
        _playSound('warning.wav');
      case HapticFeedbackType.error:
        HapticFeedback.vibrate(); // Long vibration
        _playSound('error.wav');
      case HapticFeedbackType.selection:
        HapticFeedback.selectionClick();
    }
  }
}
```

### 4. Queue Management (Multiple Students)
```dart
// Batch processing with visual queue
class SecretaryQueueView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(secretaryQueueProvider);
    
    return ListView.builder(
      itemCount: queue.length,
      itemBuilder: (_, index) {
        final item = queue[index];
        return _QueueTile(
          studentName: item.studentName,
          status: item.status, // pending, processing, success, failed
          onRetry: item.status == QueueStatus.failed 
              ? () => ref.read(secretaryQueueProvider.notifier).retry(item.id)
              : null,
        );
      },
    );
  }
}
```

---

## 🔍 VERIFICATION CHECKLIST
```bash
# 1. Secretary screens have QR scanner
grep -r "QRScanner\|qr_scan" apps/kashkool_admin/lib/features/secretary/

# 2. Optimistic updates for all quick actions
grep -r "optimistic\|Optimistic" apps/kashkool_admin/lib/features/secretary/

# 3. Color feedback (Green/Amber/Red)
grep -r "FeedbackState\|SecretaryColors" apps/kashkool_admin/lib/

# 4. Haptic/audio feedback
grep -r "HapticFeedback\|HapticService" apps/kashkool_admin/lib/

# 5. Performance test: scan → UI update < 1000ms
# Automated in CI with integration tests
```

---

## 🛑 VIOLATION RESPONSE
- Secretary action > 1 tap = **rejected**
- No immediate visual feedback (<100ms) = **rejected**
- Missing Green/Amber/Red states = **rejected**
- No haptic/audio confirmation = **rejected**
- Blocking sync (UI freezes) = **rejected**
- Output includes: exact flow, timing measurements, required pattern

---

## 💡 INTEGRATION WITH SAVIOR CORE
- **OR & Context Pruning**: Filters queue actions by priority, student status, network condition
- **Pulse-Triggered Routing**: Complex batch operations escalate to cloud for optimal ordering
- **360° Awareness**: Monitors queue health, latency, failure rates in real-time
- **Homeostasis**: Auto-retries failed items, reorders queue by priority