# 🛡️ SKILL: Gate 2 — 4-State UI Resilience Enforcer
**ID:** `kashkool-gate2-four-state-v1`
**Activation:** AUTOMATIC — Triggers on any screen/widget creation in `kashkool_app`, `kashkool_admin`
**Enforcement Level:** MANDATORY — Every screen must handle all 4 states

---

## 🎯 PURPOSE
Enforce **Gate 2 of the Supreme Constitution**: Every screen must handle Loading (Space Glass shimmer), Empty (localized CTA), Error (human-friendly + Retry), Populated (responsive 360px–1920px+).

---

## 🔄 AUTO-ACTIVATION TRIGGERS
- Creating/editing any screen in `lib/screens/**`, `lib/features/**/presentation/**`
- Adding new `Consumer`/`ConsumerWidget`/`HookConsumerWidget`
- Using `AsyncValue` or `StreamBuilder`/`FutureBuilder`

---

## 📋 FOUR STATE SPECIFICATIONS

### 1. LOADING — Space Glass Shimmer
```dart
// Required pattern
SpaceGlassShimmer(
  child: ListView.builder(
    itemCount: 6, // skeleton count
    itemBuilder: (_, __) => _SkeletonTile(),
  ),
)

// Space Glass tokens (from design system)
class SpaceGlassShimmer extends StatelessWidget {
  final Widget child;
  const SpaceGlassShimmer({required this.child, super.key});
  
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      highlightColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.1),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}
```

### 2. EMPTY — Localized CTA
```dart
// Required pattern
EmptyState(
  icon: Icons.school_outlined,
  title: context.l10n.emptyNoLessonsTitle,
  message: context.l10n.emptyNoLessonsMessage,
  action: FilledButton.icon(
    icon: const Icon(Icons.add),
    label: Text(context.l10n.emptyCreateLessonCta),
    onPressed: () => context.push('/lessons/create'),
  ),
)
```

### 3. ERROR — Human-Friendly + Retry
```dart
// Required pattern
ErrorState(
  message: context.l10n.errorGenericMessage, // Never raw Supabase codes!
  onRetry: () => ref.invalidate(lessonsProvider),
  // Optional: specific error handling
  details: error is PostgrestException ? _mapSupabaseError(error) : null,
)

// Forbidden: Raw error codes
// ❌ Text('42501: $e')
// ✅ Text(context.l10n.errorPermissionDenied)
```

### 4. POPULATED — Responsive (360px–1920px+)
```dart
// Required: LayoutBuilder + responsive breakpoints
LayoutBuilder(
  builder: (context, constraints) {
    final isDesktop = constraints.maxWidth >= 800;
    final isWide = constraints.maxWidth >= 1200;
    
    return isWide
        ? _WideLayout(data: data)      // 3+ columns
        : isDesktop
            ? _DesktopLayout(data: data) // 2 columns
            : _MobileLayout(data: data); // 1 column
  },
)
```

---

## 🌐 RTL/ARABIC MANDATORY
- Every screen tested in **Arabic (RTL)** and **English (LTR)**
- Use `Directionality.of(context)` for conditional layouts
- `app_strings.dart` keys MUST have 100% parity `ar`/`en`

---

## 🔍 VERIFICATION CHECKLIST
```bash
# 1. Analyze
flutter analyze --fatal-infos

# 2. Visual regression (manual or golden tests)
# Test each screen in 4 states × 2 locales × 3 viewports

# 3. String parity
dart run scripts/verify_string_parity.dart
```

---

## 🛑 VIOLATION RESPONSE
Missing any state = **rejected**. Output includes:
1. Which state(s) missing
2. Exact widget tree location
3. Required code pattern
4. Blocks until all 4 states implemented

---

## 💡 INTEGRATION WITH SAVIOR CORE
- **OR & Context Pruning**: Filters layout options by active constraints (viewport, locale, data state)
- **Pulse-Triggered Routing**: Complex responsive logic escalates to cloud for optimal breakpoint calculation
- **360° Awareness**: Tracks UI state coverage across all screens in real-time