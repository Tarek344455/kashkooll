import 'package:test/test.dart';

import 'package:kashkool_core/kashkool_core.dart';

void main() {
  group('EgyptValidators.isValidEgyptianPhone', () {
    test('accepts local mobile numbers for every valid prefix', () {
      expect(EgyptValidators.isValidEgyptianPhone('01012345678'), isTrue);
      expect(EgyptValidators.isValidEgyptianPhone('01112345678'), isTrue);
      expect(EgyptValidators.isValidEgyptianPhone('01212345678'), isTrue);
      expect(EgyptValidators.isValidEgyptianPhone('01512345678'), isTrue);
    });

    test('accepts +20, 20 and 0020 international formats', () {
      expect(EgyptValidators.isValidEgyptianPhone('+201012345678'), isTrue);
      expect(EgyptValidators.isValidEgyptianPhone('201012345678'), isTrue);
      expect(EgyptValidators.isValidEgyptianPhone('00201012345678'), isTrue);
    });

    test('accepts numbers without the leading zero', () {
      expect(EgyptValidators.isValidEgyptianPhone('1012345678'), isTrue);
    });

    test('ignores spaces and hyphens', () {
      expect(EgyptValidators.isValidEgyptianPhone(' 010 1234 5678 '), isTrue);
      expect(EgyptValidators.isValidEgyptianPhone('010-1234-5678'), isTrue);
    });

    test('rejects prefixes that are not mobile operators', () {
      expect(EgyptValidators.isValidEgyptianPhone('01312345678'), isFalse);
      expect(EgyptValidators.isValidEgyptianPhone('01412345678'), isFalse);
      expect(EgyptValidators.isValidEgyptianPhone('01912345678'), isFalse);
    });

    test('rejects wrong lengths and non-numeric input', () {
      expect(EgyptValidators.isValidEgyptianPhone('0101234567'), isFalse);
      expect(EgyptValidators.isValidEgyptianPhone('010123456789'), isFalse);
      expect(EgyptValidators.isValidEgyptianPhone('phone'), isFalse);
      expect(EgyptValidators.isValidEgyptianPhone(''), isFalse);
    });
  });

  group('EgyptValidators.normalizeEgyptianPhone', () {
    test('converts every accepted format to E.164', () {
      expect(EgyptValidators.normalizeEgyptianPhone('01012345678'), '+201012345678');
      expect(EgyptValidators.normalizeEgyptianPhone('+201012345678'), '+201012345678');
      expect(EgyptValidators.normalizeEgyptianPhone('201012345678'), '+201012345678');
      expect(EgyptValidators.normalizeEgyptianPhone('00201012345678'), '+201012345678');
      expect(EgyptValidators.normalizeEgyptianPhone('1012345678'), '+201012345678');
      expect(EgyptValidators.normalizeEgyptianPhone(' 010 1234 5678 '), '+201012345678');
    });

    test('returns an empty string for anything invalid', () {
      expect(EgyptValidators.normalizeEgyptianPhone('12345'), isEmpty);
      expect(EgyptValidators.normalizeEgyptianPhone('01312345678'), isEmpty);
      expect(EgyptValidators.normalizeEgyptianPhone(''), isEmpty);
    });
  });

  group('EgyptValidators.formatEgp', () {
    test('always renders two decimals with the EGP suffix', () {
      expect(EgyptValidators.formatEgp(1250), '1250.00 ج.م');
      expect(EgyptValidators.formatEgp(1250.5), '1250.50 ج.م');
      expect(EgyptValidators.formatEgp(0.005), '0.01 ج.م');
    });
  });

  group('EgyptValidators.generateDeviceFingerprint', () {
    test('is deterministic for the same input', () {
      final first = EgyptValidators.generateDeviceFingerprint('device-1');
      final second = EgyptValidators.generateDeviceFingerprint('device-1');
      expect(first, second);
    });

    test('produces a 64 character hex SHA-256 digest', () {
      final digest = EgyptValidators.generateDeviceFingerprint('device-1');
      expect(digest, hasLength(64));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(digest), isTrue);
    });

    test('differs when the input changes', () {
      final a = EgyptValidators.generateDeviceFingerprint('device-1');
      final b = EgyptValidators.generateDeviceFingerprint('device-2');
      expect(a, isNot(b));
    });
  });

  // =========================================================================
  // Money Hygiene Tests (Pre-Solver Validators)
  // =========================================================================

  group('EgyptValidators.validatePiasters', () {
    test('accepts non-negative piasters within bounds', () {
      final r = EgyptValidators.validatePiasters(5000);
      expect(r.isValid, isTrue);
      expect(r.message, isNull);
    });

    test('rejects negative piasters with exact diagnostic', () {
      final r = EgyptValidators.validatePiasters(-100);
      expect(r.isValid, isFalse);
      expect(r.message, contains('سالبًا'));
      expect(r.sourceField, 'piasters');
      expect(r.sourceValue, '-100');
    });

    test('rejects piasters above max bound', () {
      final r = EgyptValidators.validatePiasters(2000000, maxPiasters: 1000000);
      expect(r.isValid, isFalse);
      expect(r.message, contains('يتجاوز الحد الأقصى'));
    });
  });

  group('EgyptValidators.normalizeMoneyToPiasters', () {
    test('converts EGP double to piasters int', () {
      expect(EgyptValidators.normalizeMoneyToPiasters(1250.50), 125050);
      expect(EgyptValidators.normalizeMoneyToPiasters(0), 0);
      expect(EgyptValidators.normalizeMoneyToPiasters(0.01), 1);
    });

    test('returns null for negative or non-finite amounts', () {
      expect(EgyptValidators.normalizeMoneyToPiasters(-10), isNull);
      expect(EgyptValidators.normalizeMoneyToPiasters(double.negativeInfinity), isNull);
      expect(EgyptValidators.normalizeMoneyToPiasters(double.nan), isNull);
    });
  });

  group('EgyptValidators.validateEgpMoney', () {
    test('accepts finite non-negative amounts within bounds', () {
      final r = EgyptValidators.validateEgpMoney(1250.50);
      expect(r.isValid, isTrue);
    });

    test('rejects negative amounts', () {
      final r = EgyptValidators.validateEgpMoney(-50);
      expect(r.isValid, isFalse);
      expect(r.sourceField, 'amount');
    });

    test('rejects non-finite amounts', () {
      final r = EgyptValidators.validateEgpMoney(double.infinity);
      expect(r.isValid, isFalse);
      expect(r.message, contains('fini'));
    });

    test('rejects amounts above max bound', () {
      final r = EgyptValidators.validateEgpMoney(200000, maxEgp: 100000);
      expect(r.isValid, isFalse);
      expect(r.message, contains('يتجاوز الحد الأقصى'));
    });
  });

  group('EgyptValidators.formatPiasters', () {
    test('formats piasters to EGP with two decimals', () {
      expect(EgyptValidators.formatPiasters(125050), '1250.50 ج.م');
      expect(EgyptValidators.formatPiasters(0), '0.00 ج.م');
      expect(EgyptValidators.formatPiasters(1), '0.01 ج.م');
    });
  });

  // =========================================================================
  // Session Schedule Hygiene Tests
  // =========================================================================

  group('EgyptValidators.validateSessionSchedule', () {
    final roomMap = <String, String>{
      's1': 'ROOM-A',
      's2': 'ROOM-A',
      's3': 'ROOM-B',
    };
    final teacherMap = <String, String>{
      's1': 'TEACHER-X',
      's2': 'TEACHER-X',
      's3': 'TEACHER-Y',
    };

    test('accepts session with no overlaps', () {
      final existing = [
        SessionModel(
          sessionId: 's1',
          tenantId: 't1',
          groupId: 'g1',
          title: 'Math',
          type: SessionType.offline,
          startTime: DateTime(2026, 1, 1, 9, 0),
          qrSecret: 'qr1',
          studentIds: ['stu1'],
        ),
      ];
      final result = EgyptValidators.validateSessionSchedule(
        SessionModel(
          sessionId: 's2',
          tenantId: 't1',
          groupId: 'g2',
          title: 'Science',
          type: SessionType.offline,
          startTime: DateTime(2026, 1, 1, 13, 0),
          qrSecret: 'qr2',
          studentIds: ['stu2'],
        ),
        existing,
        roomIdBySessionId: roomMap,
        teacherIdBySessionId: teacherMap,
      );
      expect(result.isValid, isTrue);
      expect(result.conflicts, isEmpty);
    });

    test('detects room overlap conflict', () {
      final existing = [
        SessionModel(
          sessionId: 's1',
          tenantId: 't1',
          groupId: 'g1',
          title: 'Math',
          type: SessionType.offline,
          startTime: DateTime(2026, 1, 1, 9, 0),
          qrSecret: 'qr1',
          studentIds: ['stu1'],
        ),
      ];
      // s2 uses same room ROOM-A at overlapping time 10:00
      final result = EgyptValidators.validateSessionSchedule(
        SessionModel(
          sessionId: 's2',
          tenantId: 't1',
          groupId: 'g2',
          title: 'Science',
          type: SessionType.offline,
          startTime: DateTime(2026, 1, 1, 10, 0),
          qrSecret: 'qr2',
          studentIds: ['stu2'],
        ),
        existing,
        roomIdBySessionId: roomMap,
        teacherIdBySessionId: teacherMap,
      );
      expect(result.isValid, isFalse);
      expect(result.conflicts.any((c) => c.type == ConflictType.roomOverlap), isTrue);
      expect(result.diagnosticSummary, contains('ROOM-A'));
    });

    test('detects teacher overlap conflict', () {
      final existing = [
        SessionModel(
          sessionId: 's1',
          tenantId: 't1',
          groupId: 'g1',
          title: 'Math',
          type: SessionType.offline,
          startTime: DateTime(2026, 1, 1, 9, 0),
          qrSecret: 'qr1',
          studentIds: ['stu1'],
        ),
      ];
      // s3 uses different room ROOM-B but same teacher TEACHER-X at overlapping time
      final result = EgyptValidators.validateSessionSchedule(
        SessionModel(
          sessionId: 's3',
          tenantId: 't1',
          groupId: 'g3',
          title: 'English',
          type: SessionType.offline,
          startTime: DateTime(2026, 1, 1, 10, 0),
          qrSecret: 'qr3',
          studentIds: ['stu3'],
        ),
        existing,
        roomIdBySessionId: <String, String>{'s1': 'ROOM-A', 's3': 'ROOM-B'},
        teacherIdBySessionId: <String, String>{'s1': 'TEACHER-X', 's3': 'TEACHER-X'},
      );
      expect(result.isValid, isFalse);
      expect(result.conflicts.any((c) => c.type == ConflictType.teacherOverlap), isTrue);
      expect(result.diagnosticSummary, contains('TEACHER-X'));
    });

    test('accepts same teacher in different rooms at non-overlapping times', () {
      final existing = [
        SessionModel(
          sessionId: 's1',
          tenantId: 't1',
          groupId: 'g1',
          title: 'Math',
          type: SessionType.offline,
          startTime: DateTime(2026, 1, 1, 9, 0),
          qrSecret: 'qr1',
          studentIds: ['stu1'],
        ),
      ];
      final result = EgyptValidators.validateSessionSchedule(
        SessionModel(
          sessionId: 's2',
          tenantId: 't1',
          groupId: 'g2',
          title: 'Science',
          type: SessionType.offline,
          startTime: DateTime(2026, 1, 1, 14, 0),
          qrSecret: 'qr2',
          studentIds: ['stu2'],
        ),
        existing,
        roomIdBySessionId: roomMap,
        teacherIdBySessionId: teacherMap,
      );
      expect(result.isValid, isTrue);
    });
  });

  // =========================================================================
  // Capacity Hygiene Tests
  // =========================================================================

  group('EgyptValidators.validateCapacityBounds', () {
    test('accepts enrolled within capacity', () {
      final r = EgyptValidators.validateCapacityBounds(50, 30, hallId: 'H1');
      expect(r.isValid, isTrue);
      expect(r.capacity, 50);
      expect(r.enrolled, 30);
    });

    test('rejects negative capacity', () {
      final r = EgyptValidators.validateCapacityBounds(-5, 10);
      expect(r.isValid, isFalse);
      expect(r.message, contains('سعة القاعة'));
    });

    test('rejects enrolled exceeding capacity', () {
      final r = EgyptValidators.validateCapacityBounds(20, 35, hallId: 'H2');
      expect(r.isValid, isFalse);
      expect(r.message, contains('يتجاوز'));
      expect(r.capacity, 20);
      expect(r.enrolled, 35);
    });

    test('accepts enrolled equal to capacity', () {
      final r = EgyptValidators.validateCapacityBounds(30, 30);
      expect(r.isValid, isTrue);
    });
  });

  group('core models', () {
    test('user model exposes the role and tenant claims', () {
      const user = UserModel(
        uid: 'uid-1',
        email: 'student@example.com',
        displayName: 'Ahmed',
        role: UserRole.student,
        tenantId: 'CAI-001',
        deviceFingerprint: 'fp-1',
        isEmailVerified: true,
        createdAt: 1700000000,
      );

      expect(user.uid, 'uid-1');
      expect(user.role, UserRole.student);
      expect(user.tenantId, 'CAI-001');
      expect(user.isEmailVerified, isTrue);
    });

    test('copyWith keeps untouched fields', () {
      const user = UserModel(
        uid: 'uid-1',
        email: 'student@example.com',
        displayName: 'Ahmed',
        role: UserRole.student,
        tenantId: 'CAI-001',
        deviceFingerprint: 'fp-1',
        isEmailVerified: false,
        createdAt: 1700000000,
      );

      final updated = user.copyWith(tenantId: 'ALX-002', isEmailVerified: true);

      expect(updated.tenantId, 'ALX-002');
      expect(updated.isEmailVerified, isTrue);
      expect(updated.uid, user.uid);
      expect(updated.role, user.role);
    });
  });
}
