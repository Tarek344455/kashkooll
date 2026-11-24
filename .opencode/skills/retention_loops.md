# 🛡️ SKILL: Addictive Retention Loops
**ID:** `kashkool-retention-loops-v1`
**Activation:** AUTOMATIC — Triggers on any gamification, progress tracking, notification, or parent communication feature in `kashkool_app`, `kashkool_admin`, `packages/kashkool_core/`
**Enforcement Level:** MANDATORY — Part I Pillar 3 of Supreme Constitution

---

## 🎯 PURPOSE
Enforce **Addictive Retention** (Part I, Pillar 3): Leaderboards, streak badges, exam mastery rings, remedial practice, weekly parent digest.

---

## 🔄 AUTO-ACTIVATION TRIGGERS
- Creating progress/streak tracking
- Implementing leaderboards
- Adding badges/achievements
- Building parent communication
- Designing remedial practice flows

---

## 📋 RETENTION MECHANICS

### 1. Streak Badges (Daily/Weekly)
```dart
// kashkool_core/lib/models/gamification.dart
@freezed
class Streak with _$Streak {
  const factory Streak({
    required String studentId,
    required int currentStreakDays,
    required int longestStreakDays,
    required DateTime lastActiveDate,
    required List<StreakBadge> earnedBadges,
  }) = _Streak;
}

@freezed
class StreakBadge with _$StreakBadge {
  const factory StreakBadge({
    required String id,           // streak_7, streak_30, streak_100
    required String nameAr,       // "أسبوع من التميز"
    required String nameEn,       // "Week of Excellence"
    required int requiredDays,
    required String iconAsset,
    required DateTime earnedAt,
  }) = _StreakBadge;
}

// Auto-award on daily login/activity
@riverpod
class StreakService extends _$StreakService {
  Future<void> recordActivity(String studentId) async {
    final streak = await _getStreak(studentId);
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (streak.lastActiveDate.isSameDay(yesterday)) {
      // Continue streak
      streak.currentStreakDays++;
    } else if (!streak.lastActiveDate.isSameDay(today)) {
      // Reset streak
      streak.currentStreakDays = 1;
    }
    
    streak.lastActiveDate = today;
    streak.longestStreakDays = max(streak.longestStreakDays, streak.currentStreakDays);
    
    // Check for new badges
    _checkAndAwardBadges(streak);
    
    await _saveStreak(streak);
  }
}
```

### 2. Leaderboards (Class/Center/National)
```dart
// Real-time leaderboards backed by a Postgres view created in a migration.
@freezed
class LeaderboardEntry with _$LeaderboardEntry {
  const factory LeaderboardEntry({
    required String studentId,
    required String studentName,
    required int score,           // XP, mastery points, streak
    required int rank,
    required String avatarUrl,
    required String centerId,
  }) = _LeaderboardEntry;
}

class LeaderboardService {
  // Class leaderboard (top 10)
  Stream<List<LeaderboardEntry>> watchClassLeaderboard(String classId) {
    return Supabase.instance.client
        .from('leaderboard_entries')
        .stream(primaryKey: ['student_id'])
        .eq('group_id', classId)
        .map((rows) => rows
            .map(LeaderboardEntry.fromJson).toList()
          ..sort((a, b) => b.score.compareTo(a.score)));
    // Caller takes the top 10/50/100 for class/center/national views.
  }
  
  // Center leaderboard (top 50)
  // National leaderboard (top 100, anonymized)
}
```

### 3. Exam Mastery Rings
```dart
// Visual mastery progression: Novice → Apprentice → Expert → Master
enum MasteryLevel { novice, apprentice, expert, master }

@freezed
class ExamMastery with _$ExamMastery {
  const factory ExamMastery({
    required String studentId,
    required String examId,
    required MasteryLevel level,
    required double proficiency,  // 0.0 - 1.0
    required int attemptsCount,
    required DateTime lastAttempt,
    required List<WeakArea> weakAreas,
  }) = _ExamMastery;
}

// Ring visualization (Space Glass style)
class MasteryRing extends StatelessWidget {
  final MasteryLevel level;
  final double proficiency;
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MasteryRingPainter(
        level: level,
        progress: proficiency,
        colors: _levelColors(level),
      ),
      size: const Size(80, 80),
    );
  }
}
```

### 4. Remedial Practice (Adaptive)
```dart
// AI-driven remedial practice based on weak areas
class RemedialPracticeService {
  Future<List<PracticeQuestion>> generateRemedialSet({
    required String studentId,
    required String subjectId,
    required int questionCount,
  }) async {
    // 1. Get weak areas from mastery data
    final weakAreas = await _getWeakAreas(studentId, subjectId);
    
    // 2. Select questions targeting weak areas (70%) + reinforcement (30%)
    final questions = await _questionBank.selectAdaptive(
      weakAreas: weakAreas,
      count: questionCount,
      difficulty: _calculateOptimalDifficulty(studentId),
    );
    
    // 3. Track remedial session
    await _trackRemedialSession(studentId, questions);
    
    return questions;
  }
}
```

### 5. Weekly Parent Digest (Auto-Generated)
```dart
// Auto-generated every Sunday, sent via FCM/Email
@freezed
class ParentDigest with _$ParentDigest {
  const factory ParentDigest({
    required String studentId,
    required String parentId,
    required DateTime weekStart,
    required DateTime weekEnd,
    required int lessonsAttended,
    required int lessonsMissed,
    required int streakDays,
    required List<MasteryHighlight> highlights,
    required List<WeakAreaAlert> alerts,
    required String teacherNote,    // Optional from teacher
    required DigestStatus status,   // GENERATED, SENT, READ
  }) = _ParentDigest;
}

class ParentDigestService {
  Future<void> generateAndSendAll() async {
    final students = await _getActiveStudents();
    
    for (final student in students) {
      final digest = await _buildDigest(student.id);
      await _sendDigest(digest);
    }
  }
  
  Future<ParentDigest> _buildDigest(String studentId) async {
    // Aggregate weekly data
    // Generate Arabic/English content
    // Include actionable insights
  }
}
```

---

## 🔍 VERIFICATION CHECKLIST
```bash
# 1. Streak tracking implemented
grep -r "StreakService\|currentStreakDays" apps/ packages/

# 2. Leaderboards with real-time listeners
grep -r "LeaderboardService\|leaderboards/" apps/

# 3. Mastery rings visualization
grep -r "MasteryRing\|MasteryLevel" apps/

# 4. Remedial practice adaptive
grep -r "RemedialPracticeService\|generateRemedialSet" apps/

# 5. Parent digest weekly
grep -r "ParentDigestService\|generateAndSendAll" apps/ backend/

# 6. Arabic strings for all gamification
grep -r "streak_\|mastery_\|leaderboard_" apps/kashkool_app/l10n/app_ar.arb
```

---

## 🛑 VIOLATION RESPONSE
- No streak tracking = **rejected**
- Static leaderboards (not real-time) = **rejected**
- No mastery visualization = **rejected**
- Remedial not adaptive = **rejected**
- No parent digest = **rejected**
- Missing Arabic strings = **rejected**
- Output includes: exact violation, required pattern

---

## 💡 INTEGRATION WITH SAVIOR CORE
- **OR & Context Pruning**: Filters retention content by student level, weak areas, engagement history
- **Pulse-Triggered Routing**: Complex adaptive question selection escalates to cloud
- **360° Awareness**: Monitors engagement metrics, churn risk, parent open rates in real-time
- **Homeostasis**: Auto-adjusts difficulty, schedules digests, re-engages dormant students