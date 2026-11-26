import 'package:flutter/material.dart';
import '../core/l10n/app_strings.dart';
import '../core/models/kashkool_models.dart';
import '../core/security/role_access_guard.dart';
import '../data/launch_accounts.dart';
import '../data/seed_data.dart';
import '../services/kashkool_ai_client.dart';

class KashkoolController extends ChangeNotifier {
  AppLanguage _language = AppLanguage.ar;
  bool _signedIn = false;
  UserRole _activeRole = UserRole.student;
  String _userLabel = '';
  String _activeStudentId = 'stu-1';
  String _linkedParentStudentId = 'stu-1';
  AppDestination _destination = AppDestination.home;
  bool _examModeActive = false;
  bool _assistantBusy = false;

  final List<GroupEntity> _groups = List.of(SeedData.groups);
  final List<StudentEntity> _students = List.of(SeedData.students);
  final List<AttendanceEntity> _attendance = List.of(SeedData.attendance);
  final List<LedgerEntryEntity> _ledger = List.of(SeedData.ledger);
  final List<PaymentSubmissionEntity> _submissions =
      List.of(SeedData.submissions);
  final List<AssistantMessage> _assistantMessages = [];

  AppLanguage get language => _language;
  bool get signedIn => _signedIn;
  UserRole get activeRole => _activeRole;
  String get userLabel => _userLabel;
  AppDestination get destination =>
      RoleAccessGuard.resolveSafeDestination(_activeRole, _destination);
  bool get examModeActive => _examModeActive;
  bool get assistantBusy => _assistantBusy;

  List<GroupEntity> get groups => List.unmodifiable(_groups);
  List<StudentEntity> get students => List.unmodifiable(_students);
  List<AttendanceEntity> get attendance => List.unmodifiable(_attendance);
  List<LedgerEntryEntity> get ledger => List.unmodifiable(_ledger);
  List<PaymentSubmissionEntity> get submissions =>
      List.unmodifiable(_submissions);
  List<AssistantMessage> get assistantMessages =>
      List.unmodifiable(_assistantMessages);

  StudentEntity get activeStudent {
    return _students.firstWhere(
      (s) => s.id == _activeStudentId,
      orElse: () => _students.first,
    );
  }

  StudentEntity get linkedParentStudent {
    return _students.firstWhere(
      (s) => s.id == _linkedParentStudentId,
      orElse: () => _students.first,
    );
  }

  String tr(String key) => AppStrings.tr(_language, key);

  void toggleLanguage() {
    _language =
        _language == AppLanguage.ar ? AppLanguage.en : AppLanguage.ar;
    notifyListeners();
  }

  void setExamMode(bool active) {
    if (_examModeActive == active) return;
    _examModeActive = active;
    notifyListeners();
  }

  bool signInWithPassword(String email, String password) {
    final acc = authenticateLaunchAccount(email, password);
    if (acc == null) return false;
    _applyAccount(acc);
    return true;
  }

  bool signInWithCode(String code) {
    final acc = authenticateByActivationCode(code);
    if (acc == null) return false;
    _applyAccount(acc);
    return true;
  }

  void _applyAccount(LaunchAccount acc) {
    _signedIn = true;
    _activeRole = acc.role;
    _userLabel = _language == AppLanguage.ar ? acc.nameAr : acc.nameEn;
    if (acc.studentId != null) _activeStudentId = acc.studentId!;
    if (acc.linkedStudentId != null) {
      _linkedParentStudentId = acc.linkedStudentId!;
    }
    _destination = AppDestination.home;
    notifyListeners();
  }

  void signOut() {
    _signedIn = false;
    _userLabel = '';
    _destination = AppDestination.home;
    _examModeActive = false;
    notifyListeners();
  }

  void navigate(AppDestination dest) {
    _destination = RoleAccessGuard.resolveSafeDestination(_activeRole, dest);
    notifyListeners();
  }

  void checkInStudent(StudentEntity student) {
    final status = student.isBlocked
        ? 'blocked'
        : student.dueBalancePiasters > 0
            ? 'due'
            : 'valid';
    _attendance.insert(
      0,
      AttendanceEntity(
        id: 'att-${DateTime.now().millisecondsSinceEpoch}',
        studentId: student.id,
        groupId: student.groupId,
        feedbackStatus: status,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void voidLedgerEntry(String entryId, String reason) {
    if (!RoleAccessGuard.canManageFinancialLedger(_activeRole)) return;
    final idx = _ledger.indexWhere((e) => e.id == entryId);
    if (idx == -1) return;
    final target = _ledger[idx];
    _ledger.insert(
      0,
      LedgerEntryEntity(
        id: 'led-void-${DateTime.now().millisecondsSinceEpoch}',
        studentId: target.studentId,
        studentNameAr: target.studentNameAr,
        studentNameEn: target.studentNameEn,
        kind: LedgerKind.voidEntry,
        amountPiasters: -target.amountPiasters,
        note: reason,
        voidedEntryId: target.id,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> askAssistant(String prompt, {String subject = 'الرياضيات'}) async {
    final clean = prompt.trim();
    if (clean.isEmpty || !RoleAccessGuard.canAccessStudyAssistant(_activeRole)) {
      return;
    }
    _assistantMessages.add(
      AssistantMessage(
        id: 'u-${DateTime.now().millisecondsSinceEpoch}',
        fromUser: true,
        text: clean,
      ),
    );
    _assistantBusy = true;
    notifyListeners();

    try {
      final res = await KashkoolAiClient.chat(
        prompt: clean,
        subject: subject,
        language: _language,
      );
      _assistantMessages.add(
        AssistantMessage(
          id: 'b-${DateTime.now().millisecondsSinceEpoch}',
          fromUser: false,
          text: res.text,
          cognitiveMeta: res.meta,
        ),
      );
    } finally {
      _assistantBusy = false;
      notifyListeners();
    }
  }
}
