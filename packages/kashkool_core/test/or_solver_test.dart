import 'package:test/test.dart';

import 'package:kashkool_core/kashkool_core.dart';

void main() {
  // ===========================================================================
  // ScheduleSolver Tests — Combinatorial / Hard Constraints
  // ===========================================================================
  group('ScheduleSolver.solve', () {
    final roomMap = <String, String>{
      's1': 'ROOM-A',
      's2': 'ROOM-B',
    };
    final teacherMap = <String, String>{
      's1': 'TEACHER-X',
      's2': 'TEACHER-Y',
    };
    final rooms = ['ROOM-A', 'ROOM-B'];

    test('feasible schedule: non-overlapping sessions in different rooms', () {
      final sessions = [
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
        SessionModel(
          sessionId: 's2',
          tenantId: 't1',
          groupId: 'g2',
          title: 'Science',
          type: SessionType.offline,
          startTime: DateTime(2026, 1, 1, 11, 0),
          qrSecret: 'qr2',
          studentIds: ['stu2'],
        ),
      ];
      final result = ScheduleSolver().solve(
        sessions: sessions,
        availableRooms: rooms,
        roomIdBySessionId: roomMap,
        teacherIdBySessionId: teacherMap,
      );
      expect(result.feasible, isTrue);
      expect(result.slots.length, 2);
      expect(result.conflicts, isEmpty);
    });

    test('room overlap conflict detected', () {
      final sessions = [
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
      ];
      final result = ScheduleSolver().solve(
        sessions: sessions,
        availableRooms: ['ROOM-A'],
        roomIdBySessionId: {'s1': 'ROOM-A', 's2': 'ROOM-A'},
        teacherIdBySessionId: teacherMap,
      );
      expect(result.feasible, isFalse);
      expect(result.conflicts.any((c) => c.type == ConflictType.roomOverlap), isTrue);
      expect(result.diagnostic, contains('ROOM-A'));
    });

    test('teacher overlap conflict detected', () {
      final sessions = [
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
      ];
      final result = ScheduleSolver().solve(
        sessions: sessions,
        availableRooms: ['ROOM-A', 'ROOM-B'],
        roomIdBySessionId: {'s1': 'ROOM-A', 's2': 'ROOM-B'},
        teacherIdBySessionId: {'s1': 'TEACHER-X', 's2': 'TEACHER-X'},
      );
      expect(result.feasible, isFalse);
      expect(result.conflicts.any((c) => c.type == ConflictType.teacherOverlap), isTrue);
      expect(result.diagnostic, contains('TEACHER-X'));
    });

    test('alternative room assignment resolves room conflict', () {
      final sessions = [
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
      ];
      final result = ScheduleSolver().solve(
        sessions: sessions,
        availableRooms: ['ROOM-A', 'ROOM-B'],
        roomIdBySessionId: {'s1': 'ROOM-A', 's2': 'ROOM-A'},
        teacherIdBySessionId: {'s1': 'TEACHER-X', 's2': 'TEACHER-Y'},
      );
      expect(result.feasible, isTrue);
      expect(result.slots.length, 2);
      // s2 should be assigned to ROOM-B (alternative)
      final s2Slot = result.slots.firstWhere((s) => s.sessionId == 's2');
      expect(s2Slot.roomId, 'ROOM-B');
    });

    test('empty session list is feasible', () {
      final result = ScheduleSolver().solve(
        sessions: [],
        availableRooms: ['ROOM-A'],
        roomIdBySessionId: {},
        teacherIdBySessionId: {},
      );
      expect(result.feasible, isTrue);
      expect(result.slots, isEmpty);
    });
  });

  // ===========================================================================
  // FinancialOptimizer Tests — Deterministic Ledger Arithmetic
  // ===========================================================================
  group('FinancialOptimizer.planInstallments', () {
    test('creates equal installments when divisible', () {
      final result = FinancialOptimizer().planInstallments(
        totalPiasters: 100000, // 1000 EGP
        installmentCount: 4,
        startDate: DateTime(2026, 1, 1),
        allowPartial: false,
      );
      expect(result.feasible, isTrue);
      expect(result.totalPiasters, 100000);
      expect(result.installments.length, 4);
      // Each installment = 25000 piasters = 250 EGP
      for (final item in result.installments) {
        expect(item.duePiasters, 25000);
        expect(item.paid, isFalse);
      }
    });

    test('distributes remainder to first installments', () {
      final result = FinancialOptimizer().planInstallments(
        totalPiasters: 100001, // 1000.01 EGP
        installmentCount: 4,
        startDate: DateTime(2026, 1, 1),
        allowPartial: true,
      );
      expect(result.feasible, isTrue);
      final amounts = result.installments.map((i) => i.duePiasters).toList();
      expect(amounts.sum, 100001);
      // Remainder 1 added to first installment
      expect(amounts.first, 25001);
    });

    test('rejects zero installments', () {
      final result = FinancialOptimizer().planInstallments(
        totalPiasters: 100000,
        installmentCount: 0,
        startDate: DateTime(2026, 1, 1),
        allowPartial: false,
      );
      expect(result.feasible, isFalse);
      expect(result.warnings, isNotEmpty);
    });

    test('rejects negative amount', () {
      final result = FinancialOptimizer().planInstallments(
        totalPiasters: -5000,
        installmentCount: 2,
        startDate: DateTime(2026, 1, 1),
        allowPartial: false,
      );
      expect(result.feasible, isFalse);
    });
  });

  group('FinancialOptimizer.splitRevenue', () {
    test('splits deterministically with exact piasters, no drift', () {
      final result = FinancialOptimizer().splitRevenue(
        totalPiasters: 100000, // 1000 EGP
        centerWeights: {'C1': 0.5, 'C2': 0.3, 'C3': 0.2},
      );
      // 50000, 30000, 20000 = 100000 exactly
      expect(result['C1'], 50000);
      expect(result['C2'], 30000);
      expect(result['C3'], 20000);
      final total = result.values.fold(0, (sum, v) => sum + v);
      expect(total, 100000); // no drift
    });

    test('equal split when weights sum to zero', () {
      final result = FinancialOptimizer().splitRevenue(
        totalPiasters: 30000,
        centerWeights: {'C1': 0.0, 'C2': 0.0},
      );
      expect(result['C1'], 15000);
      expect(result['C2'], 15000);
    });

    test('zero total yields zero shares', () {
      final result = FinancialOptimizer().splitRevenue(
        totalPiasters: 0,
        centerWeights: {'C1': 0.5, 'C2': 0.5},
      );
      expect(result['C1'], 0);
      expect(result['C2'], 0);
    });
  });

  group('FinancialOptimizer.validateTransaction', () {
    test('accepts valid channel and amount', () {
      final result = FinancialOptimizer().validateTransaction(50000, 'fawry');
      expect(result.isValid, isTrue);
    });

    test('rejects unknown channel', () {
      final result = FinancialOptimizer().validateTransaction(50000, 'bitcoin');
      expect(result.isValid, isFalse);
      expect(result.message, contains('غير معروفة'));
    });

    test('rejects negative amount', () {
      final result = FinancialOptimizer().validateTransaction(-100, 'fawry');
      expect(result.isValid, isFalse);
    });
  });
}

extension ListSumExtension on List<int> {
  int get sum => fold(0, (a, b) => a + b);
}
