/// Egyptian phone (+2010/11/12/15), currency (EGP) & crypto hash helpers.
///
/// Data Hygiene at Source (Pre-Solver Validators):
/// Every financial amount, session schedule and capacity bound is validated
/// **before** any calculation or schedule runs. Exact source-data conflicts
/// surface with clear diagnostics instead of silent downstream failures.

import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/session_model.dart';

class EgyptValidators {
  static bool isValidEgyptianPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s-]+'), '');
    // Accepts 01xxxxxxxxx, +201xxxxxxxxx, 00201xxxxxxxxx and 201xxxxxxxxx.
    final regex = RegExp(r'^(?:\+|00)?(?:20)?0?1[0125][0-9]{8}$');
    return regex.hasMatch(clean);
  }

  /// Converts any accepted Egyptian format to E.164 (`+201012345678`).
  /// Returns an empty string when the number is not a valid Egyptian mobile.
  static String normalizeEgyptianPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s\-()]+'), '');
    if (!isValidEgyptianPhone(clean)) return '';

    var digits = clean.replaceFirst(RegExp(r'^(\+|00)'), '');
    if (digits.startsWith('20')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '+20$digits';
  }

  static String formatEgp(double amount) {
    return '${amount.toStringAsFixed(2)} ج.م';
  }

  static String generateDeviceFingerprint(String rawData) {
    final bytes = utf8.encode(rawData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // =========================================================================
  // Money Hygiene — Piasters (int minor units) & EGP (double)
  // =========================================================================

  /// Validates a piasters amount is non-negative and within safe bounds.
  /// Returns [MoneyValidation.ok] if valid, otherwise [MoneyValidation.invalid]
  /// with an exact diagnostic message.
  static MoneyValidation validatePiasters(int piasters, {int maxPiasters = 1000000}) {
    if (piasters < 0) {
      return MoneyValidation.invalid(
        'المبلغ بالقرش لا يمكن أن يكون سالبًا (piasters=$piasters)',
        sourceField: 'piasters',
        sourceValue: piasters.toString(),
      );
    }
    if (piasters > maxPiasters) {
      return MoneyValidation.invalid(
        'المبلغ يتجاوز الحد الأقصى المسموح (${maxPiasters ~/ 100} ج.م)',
        sourceField: 'piasters',
        sourceValue: piasters.toString(),
      );
    }
    return MoneyValidation.ok();
  }

  /// Converts an EGP double amount to piasters (int minor units) safely.
  /// Returns null when the amount is negative or not finite.
  static int? normalizeMoneyToPiasters(double amount) {
    if (!amount.isFinite || amount < 0) return null;
    return (amount * 100).round();
  }

  /// Validates an EGP double amount is non-negative, finite and within bounds.
  static MoneyValidation validateEgpMoney(double amount, {double maxEgp = 100000}) {
    if (!amount.isFinite) {
      return MoneyValidation.invalid(
        'المبلغ ليس رقمًا fini (amount=$amount)',
        sourceField: 'amount',
        sourceValue: amount.toString(),
      );
    }
    if (amount < 0) {
      return MoneyValidation.invalid(
        'المبلغ بالجنيه لا يمكن أن يكون سالبًا (amount=$amount)',
        sourceField: 'amount',
        sourceValue: amount.toString(),
      );
    }
    if (amount > maxEgp) {
      return MoneyValidation.invalid(
        'المبلغ يتجاوز الحد الأقصى المسموح ($maxEgp ج.م)',
        sourceField: 'amount',
        sourceValue: amount.toString(),
      );
    }
    return MoneyValidation.ok();
  }

  /// Formats piasters (int minor units) to EGP string with two decimals.
  static String formatPiasters(int piasters) {
    final egp = piasters / 100;
    return '${egp.toStringAsFixed(2)} ج.م';
  }

  // =========================================================================
  // Session Schedule Hygiene — non-overlapping sessions per hall & teacher
  // =========================================================================

  /// Validates a new session against existing sessions for schedule conflicts.
  /// Checks:
  ///   1. Same room cannot host two sessions at overlapping times.
  ///   2. Same teacher cannot teach two sessions at overlapping times.
  ///   3. Session duration must be positive.
  ///   4. Start time must be before end time.
  static SessionValidationResult validateSessionSchedule(
    SessionModel newSession,
    List<SessionModel> existingSessions, {
    required Map<String, String> roomIdBySessionId,
    required Map<String, String> teacherIdBySessionId,
  }) {
    final conflicts = <SessionConflict>[];

    // Duration must be positive (assume 2-hour default if endTime not stored)
    final newEnd = newSession.startTime.add(const Duration(hours: 2));
    if (!newSession.startTime.isBefore(newEnd)) {
      conflicts.add(SessionConflict(
        type: ConflictType.invalidDuration,
        message: 'مدة الجلسة غير صالحة: بداية الجلسة ${_fmt(newSession.startTime)} ليست قبل نهاية الجلسة ${_fmt(newEnd)}',
        sourceField: 'startTime',
        conflictingEntity: newSession.sessionId,
      ));
    }

    for (final existing in existingSessions) {
      if (existing.sessionId == newSession.sessionId) continue;

      final existingEnd = existing.startTime.add(const Duration(hours: 2));

      // Time overlap check
      final overlaps = newSession.startTime.isBefore(existingEnd) &&
          newEnd.isAfter(existing.startTime);

      if (!overlaps) continue;

      // Same room conflict
      final newRoom = roomIdBySessionId[newSession.sessionId] ?? '';
      final existingRoom = roomIdBySessionId[existing.sessionId] ?? '';
      if (newRoom.isNotEmpty && newRoom == existingRoom) {
        conflicts.add(SessionConflict(
          type: ConflictType.roomOverlap,
          message:
              'القاعة $newRoom بها تداخل بين الجلسة ${existing.sessionId} (${_fmt(existing.startTime)}-${_fmt(existingEnd)}) والجلسة الجديدة (${_fmt(newSession.startTime)}-${_fmt(newEnd)})',
          sourceField: 'roomId',
          sourceValue: newRoom,
          conflictingEntity: existing.sessionId,
        ));
      }

      // Same teacher conflict
      final newTeacher = teacherIdBySessionId[newSession.sessionId] ?? '';
      final existingTeacher = teacherIdBySessionId[existing.sessionId] ?? '';
      if (newTeacher.isNotEmpty && newTeacher == existingTeacher) {
        conflicts.add(SessionConflict(
          type: ConflictType.teacherOverlap,
          message:
              'المعلم $newTeacher لديه تداخل بين الجلسة ${existing.sessionId} (${_fmt(existing.startTime)}-${_fmt(existingEnd)}) والجلسة الجديدة (${_fmt(newSession.startTime)}-${_fmt(newEnd)})',
          sourceField: 'teacherId',
          sourceValue: newTeacher,
          conflictingEntity: existing.sessionId,
        ));
      }
    }

    return SessionValidationResult(
      isValid: conflicts.isEmpty,
      conflicts: conflicts,
    );
  }

  static String _fmt(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // =========================================================================
  // Capacity Hygiene — hall capacity vs enrolled students
  // =========================================================================

  /// Validates that enrolled students do not exceed hall capacity.
  static CapacityValidation validateCapacityBounds(
    int capacity,
    int enrolled, {
    String? hallId,
  }) {
    if (capacity < 0) {
      return CapacityValidation.invalid(
        'سعة القاعة ${hallId ?? ''} لا يمكن أن تكون سالبة (capacity=$capacity)',
        sourceField: 'capacity',
        sourceValue: capacity.toString(),
      );
    }
    if (enrolled < 0) {
      return CapacityValidation.invalid(
        'عدد الطلاب المسجلين لا يمكن أن يكون سالبًا (enrolled=$enrolled)',
        sourceField: 'enrolled',
        sourceValue: enrolled.toString(),
      );
    }
    if (enrolled > capacity) {
      return CapacityValidation.invalid(
        'عدد الطلاب المسجلين ($enrolled) يتجاوز سعة القاعة $capacity${hallId != null ? ' ($hallId)' : ''}',
        sourceField: 'enrolled',
        sourceValue: enrolled.toString(),
        capacity: capacity,
        enrolled: enrolled,
      );
    }
    return CapacityValidation.ok(capacity: capacity, enrolled: enrolled);
  }
}

/// Result of a money validation with exact source diagnostics.
class MoneyValidation {
  final bool isValid;
  final String? message;
  final String? sourceField;
  final String? sourceValue;

  const MoneyValidation._({
    required this.isValid,
    this.message,
    this.sourceField,
    this.sourceValue,
  });

  factory MoneyValidation.ok() => const MoneyValidation._(isValid: true);

  factory MoneyValidation.invalid(
    String message, {
    required String sourceField,
    required String sourceValue,
  }) =>
      MoneyValidation._(
        isValid: false,
        message: message,
        sourceField: sourceField,
        sourceValue: sourceValue,
      );
}

/// Result of a session schedule validation with exact conflict diagnostics.
class SessionValidationResult {
  final bool isValid;
  final List<SessionConflict> conflicts;

  const SessionValidationResult({
    required this.isValid,
    required this.conflicts,
  });

  /// Human-readable summary of all conflicts, joined by newlines.
  String get diagnosticSummary {
    if (conflicts.isEmpty) return 'لا توجد تعارضات في الجدولة';
    return conflicts.map((c) => c.message).join('\n');
  }
}

/// A single scheduling conflict with source attribution.
class SessionConflict {
  final ConflictType type;
  final String message;
  final String? sourceField;
  final String? sourceValue;
  final String? conflictingEntity;

  const SessionConflict({
    required this.type,
    required this.message,
    this.sourceField,
    this.sourceValue,
    this.conflictingEntity,
  });
}

/// Types of scheduling conflicts.
enum ConflictType {
  roomOverlap,
  teacherOverlap,
  invalidDuration,
}

/// Result of a capacity validation.
class CapacityValidation {
  final bool isValid;
  final String? message;
  final String? sourceField;
  final String? sourceValue;
  final int? capacity;
  final int? enrolled;

  const CapacityValidation._({
    required this.isValid,
    this.message,
    this.sourceField,
    this.sourceValue,
    this.capacity,
    this.enrolled,
  });

  factory CapacityValidation.ok({required int capacity, required int enrolled}) =>
      CapacityValidation._(
        isValid: true,
        capacity: capacity,
        enrolled: enrolled,
      );

  factory CapacityValidation.invalid(
    String message, {
    required String sourceField,
    required String sourceValue,
    int? capacity,
    int? enrolled,
  }) =>
      CapacityValidation._(
        isValid: false,
        message: message,
        sourceField: sourceField,
        sourceValue: sourceValue,
        capacity: capacity,
        enrolled: enrolled,
      );
}

