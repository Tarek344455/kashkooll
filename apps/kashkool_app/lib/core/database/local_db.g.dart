// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_db.dart';

// ignore_for_file: type=lint
class $LocalStudentsTable extends LocalStudents
    with TableInfo<$LocalStudentsTable, LocalStudent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalStudentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
      'student_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceFingerprintMeta =
      const VerificationMeta('deviceFingerprint');
  @override
  late final GeneratedColumn<String> deviceFingerprint =
      GeneratedColumn<String>('device_fingerprint', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _balanceMeta =
      const VerificationMeta('balance');
  @override
  late final GeneratedColumn<int> balance = GeneratedColumn<int>(
      'balance', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [studentId, tenantId, name, phone, deviceFingerprint, balance, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_students';
  @override
  VerificationContext validateIntegrity(Insertable<LocalStudent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('device_fingerprint')) {
      context.handle(
          _deviceFingerprintMeta,
          deviceFingerprint.isAcceptableOrUnknown(
              data['device_fingerprint']!, _deviceFingerprintMeta));
    } else if (isInserting) {
      context.missing(_deviceFingerprintMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(_balanceMeta,
          balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta));
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {studentId};
  @override
  LocalStudent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalStudent(
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      deviceFingerprint: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}device_fingerprint'])!,
      balance: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}balance']),
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $LocalStudentsTable createAlias(String alias) {
    return $LocalStudentsTable(attachedDatabase, alias);
  }
}

class LocalStudent extends DataClass implements Insertable<LocalStudent> {
  final String studentId;
  final String tenantId;
  final String name;
  final String phone;
  final String deviceFingerprint;
  final int? balance;
  final DateTime? syncedAt;
  const LocalStudent(
      {required this.studentId,
      required this.tenantId,
      required this.name,
      required this.phone,
      required this.deviceFingerprint,
      this.balance,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['student_id'] = Variable<String>(studentId);
    map['tenant_id'] = Variable<String>(tenantId);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['device_fingerprint'] = Variable<String>(deviceFingerprint);
    if (!nullToAbsent || balance != null) {
      map['balance'] = Variable<int>(balance);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  LocalStudentsCompanion toCompanion(bool nullToAbsent) {
    return LocalStudentsCompanion(
      studentId: Value(studentId),
      tenantId: Value(tenantId),
      name: Value(name),
      phone: Value(phone),
      deviceFingerprint: Value(deviceFingerprint),
      balance: balance == null && nullToAbsent
          ? const Value.absent()
          : Value(balance),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory LocalStudent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalStudent(
      studentId: serializer.fromJson<String>(json['studentId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      deviceFingerprint: serializer.fromJson<String>(json['deviceFingerprint']),
      balance: serializer.fromJson<int?>(json['balance']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'studentId': serializer.toJson<String>(studentId),
      'tenantId': serializer.toJson<String>(tenantId),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'deviceFingerprint': serializer.toJson<String>(deviceFingerprint),
      'balance': serializer.toJson<int?>(balance),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  LocalStudent copyWith(
          {String? studentId,
          String? tenantId,
          String? name,
          String? phone,
          String? deviceFingerprint,
          Value<int?> balance = const Value.absent(),
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      LocalStudent(
        studentId: studentId ?? this.studentId,
        tenantId: tenantId ?? this.tenantId,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
        balance: balance.present ? balance.value : this.balance,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  LocalStudent copyWithCompanion(LocalStudentsCompanion data) {
    return LocalStudent(
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      deviceFingerprint: data.deviceFingerprint.present
          ? data.deviceFingerprint.value
          : this.deviceFingerprint,
      balance: data.balance.present ? data.balance.value : this.balance,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalStudent(')
          ..write('studentId: $studentId, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('deviceFingerprint: $deviceFingerprint, ')
          ..write('balance: $balance, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      studentId, tenantId, name, phone, deviceFingerprint, balance, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalStudent &&
          other.studentId == this.studentId &&
          other.tenantId == this.tenantId &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.deviceFingerprint == this.deviceFingerprint &&
          other.balance == this.balance &&
          other.syncedAt == this.syncedAt);
}

class LocalStudentsCompanion extends UpdateCompanion<LocalStudent> {
  final Value<String> studentId;
  final Value<String> tenantId;
  final Value<String> name;
  final Value<String> phone;
  final Value<String> deviceFingerprint;
  final Value<int?> balance;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const LocalStudentsCompanion({
    this.studentId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.deviceFingerprint = const Value.absent(),
    this.balance = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalStudentsCompanion.insert({
    required String studentId,
    required String tenantId,
    required String name,
    required String phone,
    required String deviceFingerprint,
    this.balance = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : studentId = Value(studentId),
        tenantId = Value(tenantId),
        name = Value(name),
        phone = Value(phone),
        deviceFingerprint = Value(deviceFingerprint);
  static Insertable<LocalStudent> custom({
    Expression<String>? studentId,
    Expression<String>? tenantId,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? deviceFingerprint,
    Expression<int>? balance,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (studentId != null) 'student_id': studentId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (deviceFingerprint != null) 'device_fingerprint': deviceFingerprint,
      if (balance != null) 'balance': balance,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalStudentsCompanion copyWith(
      {Value<String>? studentId,
      Value<String>? tenantId,
      Value<String>? name,
      Value<String>? phone,
      Value<String>? deviceFingerprint,
      Value<int?>? balance,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return LocalStudentsCompanion(
      studentId: studentId ?? this.studentId,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      balance: balance ?? this.balance,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (deviceFingerprint.present) {
      map['device_fingerprint'] = Variable<String>(deviceFingerprint.value);
    }
    if (balance.present) {
      map['balance'] = Variable<int>(balance.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalStudentsCompanion(')
          ..write('studentId: $studentId, ')
          ..write('tenantId: $tenantId, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('deviceFingerprint: $deviceFingerprint, ')
          ..write('balance: $balance, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSessionsTable extends LocalSessions
    with TableInfo<$LocalSessionsTable, LocalSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _qrSecretMeta =
      const VerificationMeta('qrSecret');
  @override
  late final GeneratedColumn<String> qrSecret = GeneratedColumn<String>(
      'qr_secret', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        sessionId,
        tenantId,
        groupId,
        title,
        type,
        startTime,
        qrSecret,
        syncedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<LocalSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('qr_secret')) {
      context.handle(_qrSecretMeta,
          qrSecret.isAcceptableOrUnknown(data['qr_secret']!, _qrSecretMeta));
    } else if (isInserting) {
      context.missing(_qrSecretMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  LocalSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSession(
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      qrSecret: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}qr_secret'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
    );
  }

  @override
  $LocalSessionsTable createAlias(String alias) {
    return $LocalSessionsTable(attachedDatabase, alias);
  }
}

class LocalSession extends DataClass implements Insertable<LocalSession> {
  final String sessionId;
  final String tenantId;
  final String groupId;
  final String title;
  final String type;
  final DateTime startTime;
  final String qrSecret;
  final DateTime? syncedAt;
  const LocalSession(
      {required this.sessionId,
      required this.tenantId,
      required this.groupId,
      required this.title,
      required this.type,
      required this.startTime,
      required this.qrSecret,
      this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['tenant_id'] = Variable<String>(tenantId);
    map['group_id'] = Variable<String>(groupId);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    map['start_time'] = Variable<DateTime>(startTime);
    map['qr_secret'] = Variable<String>(qrSecret);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    return map;
  }

  LocalSessionsCompanion toCompanion(bool nullToAbsent) {
    return LocalSessionsCompanion(
      sessionId: Value(sessionId),
      tenantId: Value(tenantId),
      groupId: Value(groupId),
      title: Value(title),
      type: Value(type),
      startTime: Value(startTime),
      qrSecret: Value(qrSecret),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory LocalSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSession(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      qrSecret: serializer.fromJson<String>(json['qrSecret']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'tenantId': serializer.toJson<String>(tenantId),
      'groupId': serializer.toJson<String>(groupId),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'startTime': serializer.toJson<DateTime>(startTime),
      'qrSecret': serializer.toJson<String>(qrSecret),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
    };
  }

  LocalSession copyWith(
          {String? sessionId,
          String? tenantId,
          String? groupId,
          String? title,
          String? type,
          DateTime? startTime,
          String? qrSecret,
          Value<DateTime?> syncedAt = const Value.absent()}) =>
      LocalSession(
        sessionId: sessionId ?? this.sessionId,
        tenantId: tenantId ?? this.tenantId,
        groupId: groupId ?? this.groupId,
        title: title ?? this.title,
        type: type ?? this.type,
        startTime: startTime ?? this.startTime,
        qrSecret: qrSecret ?? this.qrSecret,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
      );
  LocalSession copyWithCompanion(LocalSessionsCompanion data) {
    return LocalSession(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      qrSecret: data.qrSecret.present ? data.qrSecret.value : this.qrSecret,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSession(')
          ..write('sessionId: $sessionId, ')
          ..write('tenantId: $tenantId, ')
          ..write('groupId: $groupId, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('startTime: $startTime, ')
          ..write('qrSecret: $qrSecret, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      sessionId, tenantId, groupId, title, type, startTime, qrSecret, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSession &&
          other.sessionId == this.sessionId &&
          other.tenantId == this.tenantId &&
          other.groupId == this.groupId &&
          other.title == this.title &&
          other.type == this.type &&
          other.startTime == this.startTime &&
          other.qrSecret == this.qrSecret &&
          other.syncedAt == this.syncedAt);
}

class LocalSessionsCompanion extends UpdateCompanion<LocalSession> {
  final Value<String> sessionId;
  final Value<String> tenantId;
  final Value<String> groupId;
  final Value<String> title;
  final Value<String> type;
  final Value<DateTime> startTime;
  final Value<String> qrSecret;
  final Value<DateTime?> syncedAt;
  final Value<int> rowid;
  const LocalSessionsCompanion({
    this.sessionId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.startTime = const Value.absent(),
    this.qrSecret = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSessionsCompanion.insert({
    required String sessionId,
    required String tenantId,
    required String groupId,
    required String title,
    required String type,
    required DateTime startTime,
    required String qrSecret,
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : sessionId = Value(sessionId),
        tenantId = Value(tenantId),
        groupId = Value(groupId),
        title = Value(title),
        type = Value(type),
        startTime = Value(startTime),
        qrSecret = Value(qrSecret);
  static Insertable<LocalSession> custom({
    Expression<String>? sessionId,
    Expression<String>? tenantId,
    Expression<String>? groupId,
    Expression<String>? title,
    Expression<String>? type,
    Expression<DateTime>? startTime,
    Expression<String>? qrSecret,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (groupId != null) 'group_id': groupId,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (startTime != null) 'start_time': startTime,
      if (qrSecret != null) 'qr_secret': qrSecret,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSessionsCompanion copyWith(
      {Value<String>? sessionId,
      Value<String>? tenantId,
      Value<String>? groupId,
      Value<String>? title,
      Value<String>? type,
      Value<DateTime>? startTime,
      Value<String>? qrSecret,
      Value<DateTime?>? syncedAt,
      Value<int>? rowid}) {
    return LocalSessionsCompanion(
      sessionId: sessionId ?? this.sessionId,
      tenantId: tenantId ?? this.tenantId,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      qrSecret: qrSecret ?? this.qrSecret,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (qrSecret.present) {
      map['qr_secret'] = Variable<String>(qrSecret.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSessionsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('tenantId: $tenantId, ')
          ..write('groupId: $groupId, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('startTime: $startTime, ')
          ..write('qrSecret: $qrSecret, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalAttendanceTable extends LocalAttendance
    with TableInfo<$LocalAttendanceTable, LocalAttendanceData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAttendanceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
      'student_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, studentId, sessionId, tenantId, timestamp, syncStatus];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_attendance';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalAttendanceData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAttendanceData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAttendanceData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $LocalAttendanceTable createAlias(String alias) {
    return $LocalAttendanceTable(attachedDatabase, alias);
  }
}

class LocalAttendanceData extends DataClass
    implements Insertable<LocalAttendanceData> {
  final int id;
  final String studentId;
  final String sessionId;
  final String tenantId;
  final DateTime timestamp;
  final String syncStatus;
  const LocalAttendanceData(
      {required this.id,
      required this.studentId,
      required this.sessionId,
      required this.tenantId,
      required this.timestamp,
      required this.syncStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['student_id'] = Variable<String>(studentId);
    map['session_id'] = Variable<String>(sessionId);
    map['tenant_id'] = Variable<String>(tenantId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  LocalAttendanceCompanion toCompanion(bool nullToAbsent) {
    return LocalAttendanceCompanion(
      id: Value(id),
      studentId: Value(studentId),
      sessionId: Value(sessionId),
      tenantId: Value(tenantId),
      timestamp: Value(timestamp),
      syncStatus: Value(syncStatus),
    );
  }

  factory LocalAttendanceData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAttendanceData(
      id: serializer.fromJson<int>(json['id']),
      studentId: serializer.fromJson<String>(json['studentId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'studentId': serializer.toJson<String>(studentId),
      'sessionId': serializer.toJson<String>(sessionId),
      'tenantId': serializer.toJson<String>(tenantId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  LocalAttendanceData copyWith(
          {int? id,
          String? studentId,
          String? sessionId,
          String? tenantId,
          DateTime? timestamp,
          String? syncStatus}) =>
      LocalAttendanceData(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        sessionId: sessionId ?? this.sessionId,
        tenantId: tenantId ?? this.tenantId,
        timestamp: timestamp ?? this.timestamp,
        syncStatus: syncStatus ?? this.syncStatus,
      );
  LocalAttendanceData copyWithCompanion(LocalAttendanceCompanion data) {
    return LocalAttendanceData(
      id: data.id.present ? data.id.value : this.id,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAttendanceData(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('sessionId: $sessionId, ')
          ..write('tenantId: $tenantId, ')
          ..write('timestamp: $timestamp, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, studentId, sessionId, tenantId, timestamp, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAttendanceData &&
          other.id == this.id &&
          other.studentId == this.studentId &&
          other.sessionId == this.sessionId &&
          other.tenantId == this.tenantId &&
          other.timestamp == this.timestamp &&
          other.syncStatus == this.syncStatus);
}

class LocalAttendanceCompanion extends UpdateCompanion<LocalAttendanceData> {
  final Value<int> id;
  final Value<String> studentId;
  final Value<String> sessionId;
  final Value<String> tenantId;
  final Value<DateTime> timestamp;
  final Value<String> syncStatus;
  const LocalAttendanceCompanion({
    this.id = const Value.absent(),
    this.studentId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.syncStatus = const Value.absent(),
  });
  LocalAttendanceCompanion.insert({
    this.id = const Value.absent(),
    required String studentId,
    required String sessionId,
    required String tenantId,
    required DateTime timestamp,
    required String syncStatus,
  })  : studentId = Value(studentId),
        sessionId = Value(sessionId),
        tenantId = Value(tenantId),
        timestamp = Value(timestamp),
        syncStatus = Value(syncStatus);
  static Insertable<LocalAttendanceData> custom({
    Expression<int>? id,
    Expression<String>? studentId,
    Expression<String>? sessionId,
    Expression<String>? tenantId,
    Expression<DateTime>? timestamp,
    Expression<String>? syncStatus,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (studentId != null) 'student_id': studentId,
      if (sessionId != null) 'session_id': sessionId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (timestamp != null) 'timestamp': timestamp,
      if (syncStatus != null) 'sync_status': syncStatus,
    });
  }

  LocalAttendanceCompanion copyWith(
      {Value<int>? id,
      Value<String>? studentId,
      Value<String>? sessionId,
      Value<String>? tenantId,
      Value<DateTime>? timestamp,
      Value<String>? syncStatus}) {
    return LocalAttendanceCompanion(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      sessionId: sessionId ?? this.sessionId,
      tenantId: tenantId ?? this.tenantId,
      timestamp: timestamp ?? this.timestamp,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAttendanceCompanion(')
          ..write('id: $id, ')
          ..write('studentId: $studentId, ')
          ..write('sessionId: $sessionId, ')
          ..write('tenantId: $tenantId, ')
          ..write('timestamp: $timestamp, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }
}

class $LocalTransactionsTable extends LocalTransactions
    with TableInfo<$LocalTransactionsTable, LocalTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
      'transaction_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _channelMeta =
      const VerificationMeta('channel');
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
      'channel', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        transactionId,
        userId,
        amount,
        channel,
        timestamp,
        description,
        syncStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_transactions';
  @override
  VerificationContext validateIntegrity(Insertable<LocalTransaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('channel')) {
      context.handle(_channelMeta,
          channel.isAcceptableOrUnknown(data['channel']!, _channelMeta));
    } else if (isInserting) {
      context.missing(_channelMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {transactionId};
  @override
  LocalTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTransaction(
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transaction_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      channel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}channel'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $LocalTransactionsTable createAlias(String alias) {
    return $LocalTransactionsTable(attachedDatabase, alias);
  }
}

class LocalTransaction extends DataClass
    implements Insertable<LocalTransaction> {
  final String transactionId;
  final String userId;
  final double amount;
  final String channel;
  final DateTime timestamp;
  final String description;
  final String syncStatus;
  const LocalTransaction(
      {required this.transactionId,
      required this.userId,
      required this.amount,
      required this.channel,
      required this.timestamp,
      required this.description,
      required this.syncStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['transaction_id'] = Variable<String>(transactionId);
    map['user_id'] = Variable<String>(userId);
    map['amount'] = Variable<double>(amount);
    map['channel'] = Variable<String>(channel);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['description'] = Variable<String>(description);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  LocalTransactionsCompanion toCompanion(bool nullToAbsent) {
    return LocalTransactionsCompanion(
      transactionId: Value(transactionId),
      userId: Value(userId),
      amount: Value(amount),
      channel: Value(channel),
      timestamp: Value(timestamp),
      description: Value(description),
      syncStatus: Value(syncStatus),
    );
  }

  factory LocalTransaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTransaction(
      transactionId: serializer.fromJson<String>(json['transactionId']),
      userId: serializer.fromJson<String>(json['userId']),
      amount: serializer.fromJson<double>(json['amount']),
      channel: serializer.fromJson<String>(json['channel']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      description: serializer.fromJson<String>(json['description']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'transactionId': serializer.toJson<String>(transactionId),
      'userId': serializer.toJson<String>(userId),
      'amount': serializer.toJson<double>(amount),
      'channel': serializer.toJson<String>(channel),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'description': serializer.toJson<String>(description),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  LocalTransaction copyWith(
          {String? transactionId,
          String? userId,
          double? amount,
          String? channel,
          DateTime? timestamp,
          String? description,
          String? syncStatus}) =>
      LocalTransaction(
        transactionId: transactionId ?? this.transactionId,
        userId: userId ?? this.userId,
        amount: amount ?? this.amount,
        channel: channel ?? this.channel,
        timestamp: timestamp ?? this.timestamp,
        description: description ?? this.description,
        syncStatus: syncStatus ?? this.syncStatus,
      );
  LocalTransaction copyWithCompanion(LocalTransactionsCompanion data) {
    return LocalTransaction(
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      userId: data.userId.present ? data.userId.value : this.userId,
      amount: data.amount.present ? data.amount.value : this.amount,
      channel: data.channel.present ? data.channel.value : this.channel,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      description:
          data.description.present ? data.description.value : this.description,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTransaction(')
          ..write('transactionId: $transactionId, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('channel: $channel, ')
          ..write('timestamp: $timestamp, ')
          ..write('description: $description, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(transactionId, userId, amount, channel,
      timestamp, description, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTransaction &&
          other.transactionId == this.transactionId &&
          other.userId == this.userId &&
          other.amount == this.amount &&
          other.channel == this.channel &&
          other.timestamp == this.timestamp &&
          other.description == this.description &&
          other.syncStatus == this.syncStatus);
}

class LocalTransactionsCompanion extends UpdateCompanion<LocalTransaction> {
  final Value<String> transactionId;
  final Value<String> userId;
  final Value<double> amount;
  final Value<String> channel;
  final Value<DateTime> timestamp;
  final Value<String> description;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const LocalTransactionsCompanion({
    this.transactionId = const Value.absent(),
    this.userId = const Value.absent(),
    this.amount = const Value.absent(),
    this.channel = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.description = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTransactionsCompanion.insert({
    required String transactionId,
    required String userId,
    required double amount,
    required String channel,
    required DateTime timestamp,
    required String description,
    required String syncStatus,
    this.rowid = const Value.absent(),
  })  : transactionId = Value(transactionId),
        userId = Value(userId),
        amount = Value(amount),
        channel = Value(channel),
        timestamp = Value(timestamp),
        description = Value(description),
        syncStatus = Value(syncStatus);
  static Insertable<LocalTransaction> custom({
    Expression<String>? transactionId,
    Expression<String>? userId,
    Expression<double>? amount,
    Expression<String>? channel,
    Expression<DateTime>? timestamp,
    Expression<String>? description,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (transactionId != null) 'transaction_id': transactionId,
      if (userId != null) 'user_id': userId,
      if (amount != null) 'amount': amount,
      if (channel != null) 'channel': channel,
      if (timestamp != null) 'timestamp': timestamp,
      if (description != null) 'description': description,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTransactionsCompanion copyWith(
      {Value<String>? transactionId,
      Value<String>? userId,
      Value<double>? amount,
      Value<String>? channel,
      Value<DateTime>? timestamp,
      Value<String>? description,
      Value<String>? syncStatus,
      Value<int>? rowid}) {
    return LocalTransactionsCompanion(
      transactionId: transactionId ?? this.transactionId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      channel: channel ?? this.channel,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTransactionsCompanion(')
          ..write('transactionId: $transactionId, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('channel: $channel, ')
          ..write('timestamp: $timestamp, ')
          ..write('description: $description, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalQuizzesTable extends LocalQuizzes
    with TableInfo<$LocalQuizzesTable, LocalQuiz> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalQuizzesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _quizIdMeta = const VerificationMeta('quizId');
  @override
  late final GeneratedColumn<String> quizId = GeneratedColumn<String>(
      'quiz_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timeLimitMinutesMeta =
      const VerificationMeta('timeLimitMinutes');
  @override
  late final GeneratedColumn<int> timeLimitMinutes = GeneratedColumn<int>(
      'time_limit_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        quizId,
        title,
        tenantId,
        timeLimitMinutes,
        difficulty,
        createdAt,
        syncStatus
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_quizzes';
  @override
  VerificationContext validateIntegrity(Insertable<LocalQuiz> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('quiz_id')) {
      context.handle(_quizIdMeta,
          quizId.isAcceptableOrUnknown(data['quiz_id']!, _quizIdMeta));
    } else if (isInserting) {
      context.missing(_quizIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('time_limit_minutes')) {
      context.handle(
          _timeLimitMinutesMeta,
          timeLimitMinutes.isAcceptableOrUnknown(
              data['time_limit_minutes']!, _timeLimitMinutesMeta));
    } else if (isInserting) {
      context.missing(_timeLimitMinutesMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {quizId};
  @override
  LocalQuiz map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalQuiz(
      quizId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quiz_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      timeLimitMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}time_limit_minutes'])!,
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}difficulty'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $LocalQuizzesTable createAlias(String alias) {
    return $LocalQuizzesTable(attachedDatabase, alias);
  }
}

class LocalQuiz extends DataClass implements Insertable<LocalQuiz> {
  final String quizId;
  final String title;
  final String tenantId;
  final int timeLimitMinutes;
  final String difficulty;
  final DateTime createdAt;
  final String syncStatus;
  const LocalQuiz(
      {required this.quizId,
      required this.title,
      required this.tenantId,
      required this.timeLimitMinutes,
      required this.difficulty,
      required this.createdAt,
      required this.syncStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['quiz_id'] = Variable<String>(quizId);
    map['title'] = Variable<String>(title);
    map['tenant_id'] = Variable<String>(tenantId);
    map['time_limit_minutes'] = Variable<int>(timeLimitMinutes);
    map['difficulty'] = Variable<String>(difficulty);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  LocalQuizzesCompanion toCompanion(bool nullToAbsent) {
    return LocalQuizzesCompanion(
      quizId: Value(quizId),
      title: Value(title),
      tenantId: Value(tenantId),
      timeLimitMinutes: Value(timeLimitMinutes),
      difficulty: Value(difficulty),
      createdAt: Value(createdAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory LocalQuiz.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalQuiz(
      quizId: serializer.fromJson<String>(json['quizId']),
      title: serializer.fromJson<String>(json['title']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      timeLimitMinutes: serializer.fromJson<int>(json['timeLimitMinutes']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'quizId': serializer.toJson<String>(quizId),
      'title': serializer.toJson<String>(title),
      'tenantId': serializer.toJson<String>(tenantId),
      'timeLimitMinutes': serializer.toJson<int>(timeLimitMinutes),
      'difficulty': serializer.toJson<String>(difficulty),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  LocalQuiz copyWith(
          {String? quizId,
          String? title,
          String? tenantId,
          int? timeLimitMinutes,
          String? difficulty,
          DateTime? createdAt,
          String? syncStatus}) =>
      LocalQuiz(
        quizId: quizId ?? this.quizId,
        title: title ?? this.title,
        tenantId: tenantId ?? this.tenantId,
        timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
        difficulty: difficulty ?? this.difficulty,
        createdAt: createdAt ?? this.createdAt,
        syncStatus: syncStatus ?? this.syncStatus,
      );
  LocalQuiz copyWithCompanion(LocalQuizzesCompanion data) {
    return LocalQuiz(
      quizId: data.quizId.present ? data.quizId.value : this.quizId,
      title: data.title.present ? data.title.value : this.title,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      timeLimitMinutes: data.timeLimitMinutes.present
          ? data.timeLimitMinutes.value
          : this.timeLimitMinutes,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalQuiz(')
          ..write('quizId: $quizId, ')
          ..write('title: $title, ')
          ..write('tenantId: $tenantId, ')
          ..write('timeLimitMinutes: $timeLimitMinutes, ')
          ..write('difficulty: $difficulty, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(quizId, title, tenantId, timeLimitMinutes,
      difficulty, createdAt, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalQuiz &&
          other.quizId == this.quizId &&
          other.title == this.title &&
          other.tenantId == this.tenantId &&
          other.timeLimitMinutes == this.timeLimitMinutes &&
          other.difficulty == this.difficulty &&
          other.createdAt == this.createdAt &&
          other.syncStatus == this.syncStatus);
}

class LocalQuizzesCompanion extends UpdateCompanion<LocalQuiz> {
  final Value<String> quizId;
  final Value<String> title;
  final Value<String> tenantId;
  final Value<int> timeLimitMinutes;
  final Value<String> difficulty;
  final Value<DateTime> createdAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const LocalQuizzesCompanion({
    this.quizId = const Value.absent(),
    this.title = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.timeLimitMinutes = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalQuizzesCompanion.insert({
    required String quizId,
    required String title,
    required String tenantId,
    required int timeLimitMinutes,
    required String difficulty,
    required DateTime createdAt,
    required String syncStatus,
    this.rowid = const Value.absent(),
  })  : quizId = Value(quizId),
        title = Value(title),
        tenantId = Value(tenantId),
        timeLimitMinutes = Value(timeLimitMinutes),
        difficulty = Value(difficulty),
        createdAt = Value(createdAt),
        syncStatus = Value(syncStatus);
  static Insertable<LocalQuiz> custom({
    Expression<String>? quizId,
    Expression<String>? title,
    Expression<String>? tenantId,
    Expression<int>? timeLimitMinutes,
    Expression<String>? difficulty,
    Expression<DateTime>? createdAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (quizId != null) 'quiz_id': quizId,
      if (title != null) 'title': title,
      if (tenantId != null) 'tenant_id': tenantId,
      if (timeLimitMinutes != null) 'time_limit_minutes': timeLimitMinutes,
      if (difficulty != null) 'difficulty': difficulty,
      if (createdAt != null) 'created_at': createdAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalQuizzesCompanion copyWith(
      {Value<String>? quizId,
      Value<String>? title,
      Value<String>? tenantId,
      Value<int>? timeLimitMinutes,
      Value<String>? difficulty,
      Value<DateTime>? createdAt,
      Value<String>? syncStatus,
      Value<int>? rowid}) {
    return LocalQuizzesCompanion(
      quizId: quizId ?? this.quizId,
      title: title ?? this.title,
      tenantId: tenantId ?? this.tenantId,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (quizId.present) {
      map['quiz_id'] = Variable<String>(quizId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (timeLimitMinutes.present) {
      map['time_limit_minutes'] = Variable<int>(timeLimitMinutes.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalQuizzesCompanion(')
          ..write('quizId: $quizId, ')
          ..write('title: $title, ')
          ..write('tenantId: $tenantId, ')
          ..write('timeLimitMinutes: $timeLimitMinutes, ')
          ..write('difficulty: $difficulty, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPaymentSubmissionsTable extends LocalPaymentSubmissions
    with TableInfo<$LocalPaymentSubmissionsTable, LocalPaymentSubmission> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPaymentSubmissionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _submissionIdMeta =
      const VerificationMeta('submissionId');
  @override
  late final GeneratedColumn<String> submissionId = GeneratedColumn<String>(
      'submission_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _tenantIdMeta =
      const VerificationMeta('tenantId');
  @override
  late final GeneratedColumn<String> tenantId = GeneratedColumn<String>(
      'tenant_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _studentIdMeta =
      const VerificationMeta('studentId');
  @override
  late final GeneratedColumn<String> studentId = GeneratedColumn<String>(
      'student_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _channelIdMeta =
      const VerificationMeta('channelId');
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
      'channel_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountPiastersMeta =
      const VerificationMeta('amountPiasters');
  @override
  late final GeneratedColumn<int> amountPiasters = GeneratedColumn<int>(
      'amount_piasters', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _senderReferenceMeta =
      const VerificationMeta('senderReference');
  @override
  late final GeneratedColumn<String> senderReference = GeneratedColumn<String>(
      'sender_reference', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _receiptUrlMeta =
      const VerificationMeta('receiptUrl');
  @override
  late final GeneratedColumn<String> receiptUrl = GeneratedColumn<String>(
      'receipt_url', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _syncStatusMeta =
      const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
      'sync_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        submissionId,
        tenantId,
        studentId,
        channelId,
        amountPiasters,
        senderReference,
        receiptUrl,
        status,
        syncStatus,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_payment_submissions';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalPaymentSubmission> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('submission_id')) {
      context.handle(
          _submissionIdMeta,
          submissionId.isAcceptableOrUnknown(
              data['submission_id']!, _submissionIdMeta));
    } else if (isInserting) {
      context.missing(_submissionIdMeta);
    }
    if (data.containsKey('tenant_id')) {
      context.handle(_tenantIdMeta,
          tenantId.isAcceptableOrUnknown(data['tenant_id']!, _tenantIdMeta));
    } else if (isInserting) {
      context.missing(_tenantIdMeta);
    }
    if (data.containsKey('student_id')) {
      context.handle(_studentIdMeta,
          studentId.isAcceptableOrUnknown(data['student_id']!, _studentIdMeta));
    } else if (isInserting) {
      context.missing(_studentIdMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(_channelIdMeta,
          channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta));
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('amount_piasters')) {
      context.handle(
          _amountPiastersMeta,
          amountPiasters.isAcceptableOrUnknown(
              data['amount_piasters']!, _amountPiastersMeta));
    } else if (isInserting) {
      context.missing(_amountPiastersMeta);
    }
    if (data.containsKey('sender_reference')) {
      context.handle(
          _senderReferenceMeta,
          senderReference.isAcceptableOrUnknown(
              data['sender_reference']!, _senderReferenceMeta));
    } else if (isInserting) {
      context.missing(_senderReferenceMeta);
    }
    if (data.containsKey('receipt_url')) {
      context.handle(
          _receiptUrlMeta,
          receiptUrl.isAcceptableOrUnknown(
              data['receipt_url']!, _receiptUrlMeta));
    } else if (isInserting) {
      context.missing(_receiptUrlMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
          _syncStatusMeta,
          syncStatus.isAcceptableOrUnknown(
              data['sync_status']!, _syncStatusMeta));
    } else if (isInserting) {
      context.missing(_syncStatusMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {submissionId};
  @override
  LocalPaymentSubmission map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPaymentSubmission(
      submissionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}submission_id'])!,
      tenantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tenant_id'])!,
      studentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}student_id'])!,
      channelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}channel_id'])!,
      amountPiasters: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_piasters'])!,
      senderReference: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sender_reference'])!,
      receiptUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}receipt_url'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      syncStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_status'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LocalPaymentSubmissionsTable createAlias(String alias) {
    return $LocalPaymentSubmissionsTable(attachedDatabase, alias);
  }
}

class LocalPaymentSubmission extends DataClass
    implements Insertable<LocalPaymentSubmission> {
  final String submissionId;
  final String tenantId;
  final String studentId;
  final String channelId;
  final int amountPiasters;
  final String senderReference;
  final String receiptUrl;
  final String status;
  final String syncStatus;
  final DateTime createdAt;
  const LocalPaymentSubmission(
      {required this.submissionId,
      required this.tenantId,
      required this.studentId,
      required this.channelId,
      required this.amountPiasters,
      required this.senderReference,
      required this.receiptUrl,
      required this.status,
      required this.syncStatus,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['submission_id'] = Variable<String>(submissionId);
    map['tenant_id'] = Variable<String>(tenantId);
    map['student_id'] = Variable<String>(studentId);
    map['channel_id'] = Variable<String>(channelId);
    map['amount_piasters'] = Variable<int>(amountPiasters);
    map['sender_reference'] = Variable<String>(senderReference);
    map['receipt_url'] = Variable<String>(receiptUrl);
    map['status'] = Variable<String>(status);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalPaymentSubmissionsCompanion toCompanion(bool nullToAbsent) {
    return LocalPaymentSubmissionsCompanion(
      submissionId: Value(submissionId),
      tenantId: Value(tenantId),
      studentId: Value(studentId),
      channelId: Value(channelId),
      amountPiasters: Value(amountPiasters),
      senderReference: Value(senderReference),
      receiptUrl: Value(receiptUrl),
      status: Value(status),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
    );
  }

  factory LocalPaymentSubmission.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPaymentSubmission(
      submissionId: serializer.fromJson<String>(json['submissionId']),
      tenantId: serializer.fromJson<String>(json['tenantId']),
      studentId: serializer.fromJson<String>(json['studentId']),
      channelId: serializer.fromJson<String>(json['channelId']),
      amountPiasters: serializer.fromJson<int>(json['amountPiasters']),
      senderReference: serializer.fromJson<String>(json['senderReference']),
      receiptUrl: serializer.fromJson<String>(json['receiptUrl']),
      status: serializer.fromJson<String>(json['status']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'submissionId': serializer.toJson<String>(submissionId),
      'tenantId': serializer.toJson<String>(tenantId),
      'studentId': serializer.toJson<String>(studentId),
      'channelId': serializer.toJson<String>(channelId),
      'amountPiasters': serializer.toJson<int>(amountPiasters),
      'senderReference': serializer.toJson<String>(senderReference),
      'receiptUrl': serializer.toJson<String>(receiptUrl),
      'status': serializer.toJson<String>(status),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalPaymentSubmission copyWith(
          {String? submissionId,
          String? tenantId,
          String? studentId,
          String? channelId,
          int? amountPiasters,
          String? senderReference,
          String? receiptUrl,
          String? status,
          String? syncStatus,
          DateTime? createdAt}) =>
      LocalPaymentSubmission(
        submissionId: submissionId ?? this.submissionId,
        tenantId: tenantId ?? this.tenantId,
        studentId: studentId ?? this.studentId,
        channelId: channelId ?? this.channelId,
        amountPiasters: amountPiasters ?? this.amountPiasters,
        senderReference: senderReference ?? this.senderReference,
        receiptUrl: receiptUrl ?? this.receiptUrl,
        status: status ?? this.status,
        syncStatus: syncStatus ?? this.syncStatus,
        createdAt: createdAt ?? this.createdAt,
      );
  LocalPaymentSubmission copyWithCompanion(
      LocalPaymentSubmissionsCompanion data) {
    return LocalPaymentSubmission(
      submissionId: data.submissionId.present
          ? data.submissionId.value
          : this.submissionId,
      tenantId: data.tenantId.present ? data.tenantId.value : this.tenantId,
      studentId: data.studentId.present ? data.studentId.value : this.studentId,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      amountPiasters: data.amountPiasters.present
          ? data.amountPiasters.value
          : this.amountPiasters,
      senderReference: data.senderReference.present
          ? data.senderReference.value
          : this.senderReference,
      receiptUrl:
          data.receiptUrl.present ? data.receiptUrl.value : this.receiptUrl,
      status: data.status.present ? data.status.value : this.status,
      syncStatus:
          data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPaymentSubmission(')
          ..write('submissionId: $submissionId, ')
          ..write('tenantId: $tenantId, ')
          ..write('studentId: $studentId, ')
          ..write('channelId: $channelId, ')
          ..write('amountPiasters: $amountPiasters, ')
          ..write('senderReference: $senderReference, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('status: $status, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      submissionId,
      tenantId,
      studentId,
      channelId,
      amountPiasters,
      senderReference,
      receiptUrl,
      status,
      syncStatus,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPaymentSubmission &&
          other.submissionId == this.submissionId &&
          other.tenantId == this.tenantId &&
          other.studentId == this.studentId &&
          other.channelId == this.channelId &&
          other.amountPiasters == this.amountPiasters &&
          other.senderReference == this.senderReference &&
          other.receiptUrl == this.receiptUrl &&
          other.status == this.status &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt);
}

class LocalPaymentSubmissionsCompanion
    extends UpdateCompanion<LocalPaymentSubmission> {
  final Value<String> submissionId;
  final Value<String> tenantId;
  final Value<String> studentId;
  final Value<String> channelId;
  final Value<int> amountPiasters;
  final Value<String> senderReference;
  final Value<String> receiptUrl;
  final Value<String> status;
  final Value<String> syncStatus;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalPaymentSubmissionsCompanion({
    this.submissionId = const Value.absent(),
    this.tenantId = const Value.absent(),
    this.studentId = const Value.absent(),
    this.channelId = const Value.absent(),
    this.amountPiasters = const Value.absent(),
    this.senderReference = const Value.absent(),
    this.receiptUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPaymentSubmissionsCompanion.insert({
    required String submissionId,
    required String tenantId,
    required String studentId,
    required String channelId,
    required int amountPiasters,
    required String senderReference,
    required String receiptUrl,
    required String status,
    required String syncStatus,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : submissionId = Value(submissionId),
        tenantId = Value(tenantId),
        studentId = Value(studentId),
        channelId = Value(channelId),
        amountPiasters = Value(amountPiasters),
        senderReference = Value(senderReference),
        receiptUrl = Value(receiptUrl),
        status = Value(status),
        syncStatus = Value(syncStatus),
        createdAt = Value(createdAt);
  static Insertable<LocalPaymentSubmission> custom({
    Expression<String>? submissionId,
    Expression<String>? tenantId,
    Expression<String>? studentId,
    Expression<String>? channelId,
    Expression<int>? amountPiasters,
    Expression<String>? senderReference,
    Expression<String>? receiptUrl,
    Expression<String>? status,
    Expression<String>? syncStatus,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (submissionId != null) 'submission_id': submissionId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (studentId != null) 'student_id': studentId,
      if (channelId != null) 'channel_id': channelId,
      if (amountPiasters != null) 'amount_piasters': amountPiasters,
      if (senderReference != null) 'sender_reference': senderReference,
      if (receiptUrl != null) 'receipt_url': receiptUrl,
      if (status != null) 'status': status,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPaymentSubmissionsCompanion copyWith(
      {Value<String>? submissionId,
      Value<String>? tenantId,
      Value<String>? studentId,
      Value<String>? channelId,
      Value<int>? amountPiasters,
      Value<String>? senderReference,
      Value<String>? receiptUrl,
      Value<String>? status,
      Value<String>? syncStatus,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return LocalPaymentSubmissionsCompanion(
      submissionId: submissionId ?? this.submissionId,
      tenantId: tenantId ?? this.tenantId,
      studentId: studentId ?? this.studentId,
      channelId: channelId ?? this.channelId,
      amountPiasters: amountPiasters ?? this.amountPiasters,
      senderReference: senderReference ?? this.senderReference,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      status: status ?? this.status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (submissionId.present) {
      map['submission_id'] = Variable<String>(submissionId.value);
    }
    if (tenantId.present) {
      map['tenant_id'] = Variable<String>(tenantId.value);
    }
    if (studentId.present) {
      map['student_id'] = Variable<String>(studentId.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (amountPiasters.present) {
      map['amount_piasters'] = Variable<int>(amountPiasters.value);
    }
    if (senderReference.present) {
      map['sender_reference'] = Variable<String>(senderReference.value);
    }
    if (receiptUrl.present) {
      map['receipt_url'] = Variable<String>(receiptUrl.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPaymentSubmissionsCompanion(')
          ..write('submissionId: $submissionId, ')
          ..write('tenantId: $tenantId, ')
          ..write('studentId: $studentId, ')
          ..write('channelId: $channelId, ')
          ..write('amountPiasters: $amountPiasters, ')
          ..write('senderReference: $senderReference, ')
          ..write('receiptUrl: $receiptUrl, ')
          ..write('status: $status, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTableTable extends SyncQueueTable
    with TableInfo<$SyncQueueTableTable, SyncQueueTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _collectionNameMeta =
      const VerificationMeta('collectionName');
  @override
  late final GeneratedColumn<String> collectionName = GeneratedColumn<String>(
      'collection_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _documentIdMeta =
      const VerificationMeta('documentId');
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
      'document_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataJsonMeta =
      const VerificationMeta('dataJson');
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
      'data_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        collectionName,
        documentId,
        operation,
        dataJson,
        priority,
        status,
        retryCount,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue_table';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('collection_name')) {
      context.handle(
          _collectionNameMeta,
          collectionName.isAcceptableOrUnknown(
              data['collection_name']!, _collectionNameMeta));
    } else if (isInserting) {
      context.missing(_collectionNameMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
          _documentIdMeta,
          documentId.isAcceptableOrUnknown(
              data['document_id']!, _documentIdMeta));
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(_dataJsonMeta,
          dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta));
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      collectionName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}collection_name'])!,
      documentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}document_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      dataJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data_json'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SyncQueueTableTable createAlias(String alias) {
    return $SyncQueueTableTable(attachedDatabase, alias);
  }
}

class SyncQueueTableData extends DataClass
    implements Insertable<SyncQueueTableData> {
  final int id;
  final String collectionName;
  final String documentId;
  final String operation;
  final String dataJson;
  final int priority;
  final String status;
  final int retryCount;
  final DateTime createdAt;
  const SyncQueueTableData(
      {required this.id,
      required this.collectionName,
      required this.documentId,
      required this.operation,
      required this.dataJson,
      required this.priority,
      required this.status,
      required this.retryCount,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['collection_name'] = Variable<String>(collectionName);
    map['document_id'] = Variable<String>(documentId);
    map['operation'] = Variable<String>(operation);
    map['data_json'] = Variable<String>(dataJson);
    map['priority'] = Variable<int>(priority);
    map['status'] = Variable<String>(status);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueTableCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueTableCompanion(
      id: Value(id),
      collectionName: Value(collectionName),
      documentId: Value(documentId),
      operation: Value(operation),
      dataJson: Value(dataJson),
      priority: Value(priority),
      status: Value(status),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueTableData(
      id: serializer.fromJson<int>(json['id']),
      collectionName: serializer.fromJson<String>(json['collectionName']),
      documentId: serializer.fromJson<String>(json['documentId']),
      operation: serializer.fromJson<String>(json['operation']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
      priority: serializer.fromJson<int>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'collectionName': serializer.toJson<String>(collectionName),
      'documentId': serializer.toJson<String>(documentId),
      'operation': serializer.toJson<String>(operation),
      'dataJson': serializer.toJson<String>(dataJson),
      'priority': serializer.toJson<int>(priority),
      'status': serializer.toJson<String>(status),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueTableData copyWith(
          {int? id,
          String? collectionName,
          String? documentId,
          String? operation,
          String? dataJson,
          int? priority,
          String? status,
          int? retryCount,
          DateTime? createdAt}) =>
      SyncQueueTableData(
        id: id ?? this.id,
        collectionName: collectionName ?? this.collectionName,
        documentId: documentId ?? this.documentId,
        operation: operation ?? this.operation,
        dataJson: dataJson ?? this.dataJson,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        retryCount: retryCount ?? this.retryCount,
        createdAt: createdAt ?? this.createdAt,
      );
  SyncQueueTableData copyWithCompanion(SyncQueueTableCompanion data) {
    return SyncQueueTableData(
      id: data.id.present ? data.id.value : this.id,
      collectionName: data.collectionName.present
          ? data.collectionName.value
          : this.collectionName,
      documentId:
          data.documentId.present ? data.documentId.value : this.documentId,
      operation: data.operation.present ? data.operation.value : this.operation,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableData(')
          ..write('id: $id, ')
          ..write('collectionName: $collectionName, ')
          ..write('documentId: $documentId, ')
          ..write('operation: $operation, ')
          ..write('dataJson: $dataJson, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, collectionName, documentId, operation,
      dataJson, priority, status, retryCount, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueTableData &&
          other.id == this.id &&
          other.collectionName == this.collectionName &&
          other.documentId == this.documentId &&
          other.operation == this.operation &&
          other.dataJson == this.dataJson &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt);
}

class SyncQueueTableCompanion extends UpdateCompanion<SyncQueueTableData> {
  final Value<int> id;
  final Value<String> collectionName;
  final Value<String> documentId;
  final Value<String> operation;
  final Value<String> dataJson;
  final Value<int> priority;
  final Value<String> status;
  final Value<int> retryCount;
  final Value<DateTime> createdAt;
  const SyncQueueTableCompanion({
    this.id = const Value.absent(),
    this.collectionName = const Value.absent(),
    this.documentId = const Value.absent(),
    this.operation = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueTableCompanion.insert({
    this.id = const Value.absent(),
    required String collectionName,
    required String documentId,
    required String operation,
    required String dataJson,
    required int priority,
    required String status,
    this.retryCount = const Value.absent(),
    required DateTime createdAt,
  })  : collectionName = Value(collectionName),
        documentId = Value(documentId),
        operation = Value(operation),
        dataJson = Value(dataJson),
        priority = Value(priority),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<SyncQueueTableData> custom({
    Expression<int>? id,
    Expression<String>? collectionName,
    Expression<String>? documentId,
    Expression<String>? operation,
    Expression<String>? dataJson,
    Expression<int>? priority,
    Expression<String>? status,
    Expression<int>? retryCount,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (collectionName != null) 'collection_name': collectionName,
      if (documentId != null) 'document_id': documentId,
      if (operation != null) 'operation': operation,
      if (dataJson != null) 'data_json': dataJson,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? collectionName,
      Value<String>? documentId,
      Value<String>? operation,
      Value<String>? dataJson,
      Value<int>? priority,
      Value<String>? status,
      Value<int>? retryCount,
      Value<DateTime>? createdAt}) {
    return SyncQueueTableCompanion(
      id: id ?? this.id,
      collectionName: collectionName ?? this.collectionName,
      documentId: documentId ?? this.documentId,
      operation: operation ?? this.operation,
      dataJson: dataJson ?? this.dataJson,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (collectionName.present) {
      map['collection_name'] = Variable<String>(collectionName.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueTableCompanion(')
          ..write('id: $id, ')
          ..write('collectionName: $collectionName, ')
          ..write('documentId: $documentId, ')
          ..write('operation: $operation, ')
          ..write('dataJson: $dataJson, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDb extends GeneratedDatabase {
  _$LocalDb(QueryExecutor e) : super(e);
  $LocalDbManager get managers => $LocalDbManager(this);
  late final $LocalStudentsTable localStudents = $LocalStudentsTable(this);
  late final $LocalSessionsTable localSessions = $LocalSessionsTable(this);
  late final $LocalAttendanceTable localAttendance =
      $LocalAttendanceTable(this);
  late final $LocalTransactionsTable localTransactions =
      $LocalTransactionsTable(this);
  late final $LocalQuizzesTable localQuizzes = $LocalQuizzesTable(this);
  late final $LocalPaymentSubmissionsTable localPaymentSubmissions =
      $LocalPaymentSubmissionsTable(this);
  late final $SyncQueueTableTable syncQueueTable = $SyncQueueTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        localStudents,
        localSessions,
        localAttendance,
        localTransactions,
        localQuizzes,
        localPaymentSubmissions,
        syncQueueTable
      ];
}

typedef $$LocalStudentsTableCreateCompanionBuilder = LocalStudentsCompanion
    Function({
  required String studentId,
  required String tenantId,
  required String name,
  required String phone,
  required String deviceFingerprint,
  Value<int?> balance,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$LocalStudentsTableUpdateCompanionBuilder = LocalStudentsCompanion
    Function({
  Value<String> studentId,
  Value<String> tenantId,
  Value<String> name,
  Value<String> phone,
  Value<String> deviceFingerprint,
  Value<int?> balance,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$LocalStudentsTableFilterComposer
    extends Composer<_$LocalDb, $LocalStudentsTable> {
  $$LocalStudentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceFingerprint => $composableBuilder(
      column: $table.deviceFingerprint,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get balance => $composableBuilder(
      column: $table.balance, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalStudentsTableOrderingComposer
    extends Composer<_$LocalDb, $LocalStudentsTable> {
  $$LocalStudentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceFingerprint => $composableBuilder(
      column: $table.deviceFingerprint,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get balance => $composableBuilder(
      column: $table.balance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalStudentsTableAnnotationComposer
    extends Composer<_$LocalDb, $LocalStudentsTable> {
  $$LocalStudentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get deviceFingerprint => $composableBuilder(
      column: $table.deviceFingerprint, builder: (column) => column);

  GeneratedColumn<int> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalStudentsTableTableManager extends RootTableManager<
    _$LocalDb,
    $LocalStudentsTable,
    LocalStudent,
    $$LocalStudentsTableFilterComposer,
    $$LocalStudentsTableOrderingComposer,
    $$LocalStudentsTableAnnotationComposer,
    $$LocalStudentsTableCreateCompanionBuilder,
    $$LocalStudentsTableUpdateCompanionBuilder,
    (
      LocalStudent,
      BaseReferences<_$LocalDb, $LocalStudentsTable, LocalStudent>
    ),
    LocalStudent,
    PrefetchHooks Function()> {
  $$LocalStudentsTableTableManager(_$LocalDb db, $LocalStudentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalStudentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalStudentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalStudentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> studentId = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String> deviceFingerprint = const Value.absent(),
            Value<int?> balance = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalStudentsCompanion(
            studentId: studentId,
            tenantId: tenantId,
            name: name,
            phone: phone,
            deviceFingerprint: deviceFingerprint,
            balance: balance,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String studentId,
            required String tenantId,
            required String name,
            required String phone,
            required String deviceFingerprint,
            Value<int?> balance = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalStudentsCompanion.insert(
            studentId: studentId,
            tenantId: tenantId,
            name: name,
            phone: phone,
            deviceFingerprint: deviceFingerprint,
            balance: balance,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalStudentsTable, LocalStudent>(table),
                    BaseReferences<_$LocalDb, $LocalStudentsTable,
                        LocalStudent>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalStudentsTableProcessedTableManager = ProcessedTableManager<
    _$LocalDb,
    $LocalStudentsTable,
    LocalStudent,
    $$LocalStudentsTableFilterComposer,
    $$LocalStudentsTableOrderingComposer,
    $$LocalStudentsTableAnnotationComposer,
    $$LocalStudentsTableCreateCompanionBuilder,
    $$LocalStudentsTableUpdateCompanionBuilder,
    (
      LocalStudent,
      BaseReferences<_$LocalDb, $LocalStudentsTable, LocalStudent>
    ),
    LocalStudent,
    PrefetchHooks Function()>;
typedef $$LocalSessionsTableCreateCompanionBuilder = LocalSessionsCompanion
    Function({
  required String sessionId,
  required String tenantId,
  required String groupId,
  required String title,
  required String type,
  required DateTime startTime,
  required String qrSecret,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});
typedef $$LocalSessionsTableUpdateCompanionBuilder = LocalSessionsCompanion
    Function({
  Value<String> sessionId,
  Value<String> tenantId,
  Value<String> groupId,
  Value<String> title,
  Value<String> type,
  Value<DateTime> startTime,
  Value<String> qrSecret,
  Value<DateTime?> syncedAt,
  Value<int> rowid,
});

class $$LocalSessionsTableFilterComposer
    extends Composer<_$LocalDb, $LocalSessionsTable> {
  $$LocalSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get qrSecret => $composableBuilder(
      column: $table.qrSecret, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$LocalSessionsTableOrderingComposer
    extends Composer<_$LocalDb, $LocalSessionsTable> {
  $$LocalSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get qrSecret => $composableBuilder(
      column: $table.qrSecret, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalSessionsTableAnnotationComposer
    extends Composer<_$LocalDb, $LocalSessionsTable> {
  $$LocalSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get qrSecret =>
      $composableBuilder(column: $table.qrSecret, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$LocalSessionsTableTableManager extends RootTableManager<
    _$LocalDb,
    $LocalSessionsTable,
    LocalSession,
    $$LocalSessionsTableFilterComposer,
    $$LocalSessionsTableOrderingComposer,
    $$LocalSessionsTableAnnotationComposer,
    $$LocalSessionsTableCreateCompanionBuilder,
    $$LocalSessionsTableUpdateCompanionBuilder,
    (
      LocalSession,
      BaseReferences<_$LocalDb, $LocalSessionsTable, LocalSession>
    ),
    LocalSession,
    PrefetchHooks Function()> {
  $$LocalSessionsTableTableManager(_$LocalDb db, $LocalSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> sessionId = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<String> qrSecret = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSessionsCompanion(
            sessionId: sessionId,
            tenantId: tenantId,
            groupId: groupId,
            title: title,
            type: type,
            startTime: startTime,
            qrSecret: qrSecret,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String sessionId,
            required String tenantId,
            required String groupId,
            required String title,
            required String type,
            required DateTime startTime,
            required String qrSecret,
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalSessionsCompanion.insert(
            sessionId: sessionId,
            tenantId: tenantId,
            groupId: groupId,
            title: title,
            type: type,
            startTime: startTime,
            qrSecret: qrSecret,
            syncedAt: syncedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalSessionsTable, LocalSession>(table),
                    BaseReferences<_$LocalDb, $LocalSessionsTable,
                        LocalSession>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalSessionsTableProcessedTableManager = ProcessedTableManager<
    _$LocalDb,
    $LocalSessionsTable,
    LocalSession,
    $$LocalSessionsTableFilterComposer,
    $$LocalSessionsTableOrderingComposer,
    $$LocalSessionsTableAnnotationComposer,
    $$LocalSessionsTableCreateCompanionBuilder,
    $$LocalSessionsTableUpdateCompanionBuilder,
    (
      LocalSession,
      BaseReferences<_$LocalDb, $LocalSessionsTable, LocalSession>
    ),
    LocalSession,
    PrefetchHooks Function()>;
typedef $$LocalAttendanceTableCreateCompanionBuilder = LocalAttendanceCompanion
    Function({
  Value<int> id,
  required String studentId,
  required String sessionId,
  required String tenantId,
  required DateTime timestamp,
  required String syncStatus,
});
typedef $$LocalAttendanceTableUpdateCompanionBuilder = LocalAttendanceCompanion
    Function({
  Value<int> id,
  Value<String> studentId,
  Value<String> sessionId,
  Value<String> tenantId,
  Value<DateTime> timestamp,
  Value<String> syncStatus,
});

class $$LocalAttendanceTableFilterComposer
    extends Composer<_$LocalDb, $LocalAttendanceTable> {
  $$LocalAttendanceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));
}

class $$LocalAttendanceTableOrderingComposer
    extends Composer<_$LocalDb, $LocalAttendanceTable> {
  $$LocalAttendanceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$LocalAttendanceTableAnnotationComposer
    extends Composer<_$LocalDb, $LocalAttendanceTable> {
  $$LocalAttendanceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);
}

class $$LocalAttendanceTableTableManager extends RootTableManager<
    _$LocalDb,
    $LocalAttendanceTable,
    LocalAttendanceData,
    $$LocalAttendanceTableFilterComposer,
    $$LocalAttendanceTableOrderingComposer,
    $$LocalAttendanceTableAnnotationComposer,
    $$LocalAttendanceTableCreateCompanionBuilder,
    $$LocalAttendanceTableUpdateCompanionBuilder,
    (
      LocalAttendanceData,
      BaseReferences<_$LocalDb, $LocalAttendanceTable, LocalAttendanceData>
    ),
    LocalAttendanceData,
    PrefetchHooks Function()> {
  $$LocalAttendanceTableTableManager(_$LocalDb db, $LocalAttendanceTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAttendanceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAttendanceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAttendanceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> studentId = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
          }) =>
              LocalAttendanceCompanion(
            id: id,
            studentId: studentId,
            sessionId: sessionId,
            tenantId: tenantId,
            timestamp: timestamp,
            syncStatus: syncStatus,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String studentId,
            required String sessionId,
            required String tenantId,
            required DateTime timestamp,
            required String syncStatus,
          }) =>
              LocalAttendanceCompanion.insert(
            id: id,
            studentId: studentId,
            sessionId: sessionId,
            tenantId: tenantId,
            timestamp: timestamp,
            syncStatus: syncStatus,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalAttendanceTable, LocalAttendanceData>(
                        table),
                    BaseReferences<_$LocalDb, $LocalAttendanceTable,
                        LocalAttendanceData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalAttendanceTableProcessedTableManager = ProcessedTableManager<
    _$LocalDb,
    $LocalAttendanceTable,
    LocalAttendanceData,
    $$LocalAttendanceTableFilterComposer,
    $$LocalAttendanceTableOrderingComposer,
    $$LocalAttendanceTableAnnotationComposer,
    $$LocalAttendanceTableCreateCompanionBuilder,
    $$LocalAttendanceTableUpdateCompanionBuilder,
    (
      LocalAttendanceData,
      BaseReferences<_$LocalDb, $LocalAttendanceTable, LocalAttendanceData>
    ),
    LocalAttendanceData,
    PrefetchHooks Function()>;
typedef $$LocalTransactionsTableCreateCompanionBuilder
    = LocalTransactionsCompanion Function({
  required String transactionId,
  required String userId,
  required double amount,
  required String channel,
  required DateTime timestamp,
  required String description,
  required String syncStatus,
  Value<int> rowid,
});
typedef $$LocalTransactionsTableUpdateCompanionBuilder
    = LocalTransactionsCompanion Function({
  Value<String> transactionId,
  Value<String> userId,
  Value<double> amount,
  Value<String> channel,
  Value<DateTime> timestamp,
  Value<String> description,
  Value<String> syncStatus,
  Value<int> rowid,
});

class $$LocalTransactionsTableFilterComposer
    extends Composer<_$LocalDb, $LocalTransactionsTable> {
  $$LocalTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get channel => $composableBuilder(
      column: $table.channel, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));
}

class $$LocalTransactionsTableOrderingComposer
    extends Composer<_$LocalDb, $LocalTransactionsTable> {
  $$LocalTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get transactionId => $composableBuilder(
      column: $table.transactionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get channel => $composableBuilder(
      column: $table.channel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$LocalTransactionsTableAnnotationComposer
    extends Composer<_$LocalDb, $LocalTransactionsTable> {
  $$LocalTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get transactionId => $composableBuilder(
      column: $table.transactionId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);
}

class $$LocalTransactionsTableTableManager extends RootTableManager<
    _$LocalDb,
    $LocalTransactionsTable,
    LocalTransaction,
    $$LocalTransactionsTableFilterComposer,
    $$LocalTransactionsTableOrderingComposer,
    $$LocalTransactionsTableAnnotationComposer,
    $$LocalTransactionsTableCreateCompanionBuilder,
    $$LocalTransactionsTableUpdateCompanionBuilder,
    (
      LocalTransaction,
      BaseReferences<_$LocalDb, $LocalTransactionsTable, LocalTransaction>
    ),
    LocalTransaction,
    PrefetchHooks Function()> {
  $$LocalTransactionsTableTableManager(
      _$LocalDb db, $LocalTransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTransactionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> transactionId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> channel = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTransactionsCompanion(
            transactionId: transactionId,
            userId: userId,
            amount: amount,
            channel: channel,
            timestamp: timestamp,
            description: description,
            syncStatus: syncStatus,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String transactionId,
            required String userId,
            required double amount,
            required String channel,
            required DateTime timestamp,
            required String description,
            required String syncStatus,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTransactionsCompanion.insert(
            transactionId: transactionId,
            userId: userId,
            amount: amount,
            channel: channel,
            timestamp: timestamp,
            description: description,
            syncStatus: syncStatus,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalTransactionsTable, LocalTransaction>(
                        table),
                    BaseReferences<_$LocalDb, $LocalTransactionsTable,
                        LocalTransaction>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalTransactionsTableProcessedTableManager = ProcessedTableManager<
    _$LocalDb,
    $LocalTransactionsTable,
    LocalTransaction,
    $$LocalTransactionsTableFilterComposer,
    $$LocalTransactionsTableOrderingComposer,
    $$LocalTransactionsTableAnnotationComposer,
    $$LocalTransactionsTableCreateCompanionBuilder,
    $$LocalTransactionsTableUpdateCompanionBuilder,
    (
      LocalTransaction,
      BaseReferences<_$LocalDb, $LocalTransactionsTable, LocalTransaction>
    ),
    LocalTransaction,
    PrefetchHooks Function()>;
typedef $$LocalQuizzesTableCreateCompanionBuilder = LocalQuizzesCompanion
    Function({
  required String quizId,
  required String title,
  required String tenantId,
  required int timeLimitMinutes,
  required String difficulty,
  required DateTime createdAt,
  required String syncStatus,
  Value<int> rowid,
});
typedef $$LocalQuizzesTableUpdateCompanionBuilder = LocalQuizzesCompanion
    Function({
  Value<String> quizId,
  Value<String> title,
  Value<String> tenantId,
  Value<int> timeLimitMinutes,
  Value<String> difficulty,
  Value<DateTime> createdAt,
  Value<String> syncStatus,
  Value<int> rowid,
});

class $$LocalQuizzesTableFilterComposer
    extends Composer<_$LocalDb, $LocalQuizzesTable> {
  $$LocalQuizzesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get quizId => $composableBuilder(
      column: $table.quizId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timeLimitMinutes => $composableBuilder(
      column: $table.timeLimitMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));
}

class $$LocalQuizzesTableOrderingComposer
    extends Composer<_$LocalDb, $LocalQuizzesTable> {
  $$LocalQuizzesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get quizId => $composableBuilder(
      column: $table.quizId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timeLimitMinutes => $composableBuilder(
      column: $table.timeLimitMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$LocalQuizzesTableAnnotationComposer
    extends Composer<_$LocalDb, $LocalQuizzesTable> {
  $$LocalQuizzesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get quizId =>
      $composableBuilder(column: $table.quizId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<int> get timeLimitMinutes => $composableBuilder(
      column: $table.timeLimitMinutes, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);
}

class $$LocalQuizzesTableTableManager extends RootTableManager<
    _$LocalDb,
    $LocalQuizzesTable,
    LocalQuiz,
    $$LocalQuizzesTableFilterComposer,
    $$LocalQuizzesTableOrderingComposer,
    $$LocalQuizzesTableAnnotationComposer,
    $$LocalQuizzesTableCreateCompanionBuilder,
    $$LocalQuizzesTableUpdateCompanionBuilder,
    (LocalQuiz, BaseReferences<_$LocalDb, $LocalQuizzesTable, LocalQuiz>),
    LocalQuiz,
    PrefetchHooks Function()> {
  $$LocalQuizzesTableTableManager(_$LocalDb db, $LocalQuizzesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalQuizzesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalQuizzesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalQuizzesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> quizId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<int> timeLimitMinutes = const Value.absent(),
            Value<String> difficulty = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalQuizzesCompanion(
            quizId: quizId,
            title: title,
            tenantId: tenantId,
            timeLimitMinutes: timeLimitMinutes,
            difficulty: difficulty,
            createdAt: createdAt,
            syncStatus: syncStatus,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String quizId,
            required String title,
            required String tenantId,
            required int timeLimitMinutes,
            required String difficulty,
            required DateTime createdAt,
            required String syncStatus,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalQuizzesCompanion.insert(
            quizId: quizId,
            title: title,
            tenantId: tenantId,
            timeLimitMinutes: timeLimitMinutes,
            difficulty: difficulty,
            createdAt: createdAt,
            syncStatus: syncStatus,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalQuizzesTable, LocalQuiz>(table),
                    BaseReferences<_$LocalDb, $LocalQuizzesTable, LocalQuiz>(
                        db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalQuizzesTableProcessedTableManager = ProcessedTableManager<
    _$LocalDb,
    $LocalQuizzesTable,
    LocalQuiz,
    $$LocalQuizzesTableFilterComposer,
    $$LocalQuizzesTableOrderingComposer,
    $$LocalQuizzesTableAnnotationComposer,
    $$LocalQuizzesTableCreateCompanionBuilder,
    $$LocalQuizzesTableUpdateCompanionBuilder,
    (LocalQuiz, BaseReferences<_$LocalDb, $LocalQuizzesTable, LocalQuiz>),
    LocalQuiz,
    PrefetchHooks Function()>;
typedef $$LocalPaymentSubmissionsTableCreateCompanionBuilder
    = LocalPaymentSubmissionsCompanion Function({
  required String submissionId,
  required String tenantId,
  required String studentId,
  required String channelId,
  required int amountPiasters,
  required String senderReference,
  required String receiptUrl,
  required String status,
  required String syncStatus,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$LocalPaymentSubmissionsTableUpdateCompanionBuilder
    = LocalPaymentSubmissionsCompanion Function({
  Value<String> submissionId,
  Value<String> tenantId,
  Value<String> studentId,
  Value<String> channelId,
  Value<int> amountPiasters,
  Value<String> senderReference,
  Value<String> receiptUrl,
  Value<String> status,
  Value<String> syncStatus,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$LocalPaymentSubmissionsTableFilterComposer
    extends Composer<_$LocalDb, $LocalPaymentSubmissionsTable> {
  $$LocalPaymentSubmissionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get submissionId => $composableBuilder(
      column: $table.submissionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get channelId => $composableBuilder(
      column: $table.channelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountPiasters => $composableBuilder(
      column: $table.amountPiasters,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get senderReference => $composableBuilder(
      column: $table.senderReference,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get receiptUrl => $composableBuilder(
      column: $table.receiptUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$LocalPaymentSubmissionsTableOrderingComposer
    extends Composer<_$LocalDb, $LocalPaymentSubmissionsTable> {
  $$LocalPaymentSubmissionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get submissionId => $composableBuilder(
      column: $table.submissionId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tenantId => $composableBuilder(
      column: $table.tenantId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studentId => $composableBuilder(
      column: $table.studentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get channelId => $composableBuilder(
      column: $table.channelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountPiasters => $composableBuilder(
      column: $table.amountPiasters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get senderReference => $composableBuilder(
      column: $table.senderReference,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get receiptUrl => $composableBuilder(
      column: $table.receiptUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalPaymentSubmissionsTableAnnotationComposer
    extends Composer<_$LocalDb, $LocalPaymentSubmissionsTable> {
  $$LocalPaymentSubmissionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get submissionId => $composableBuilder(
      column: $table.submissionId, builder: (column) => column);

  GeneratedColumn<String> get tenantId =>
      $composableBuilder(column: $table.tenantId, builder: (column) => column);

  GeneratedColumn<String> get studentId =>
      $composableBuilder(column: $table.studentId, builder: (column) => column);

  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<int> get amountPiasters => $composableBuilder(
      column: $table.amountPiasters, builder: (column) => column);

  GeneratedColumn<String> get senderReference => $composableBuilder(
      column: $table.senderReference, builder: (column) => column);

  GeneratedColumn<String> get receiptUrl => $composableBuilder(
      column: $table.receiptUrl, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
      column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalPaymentSubmissionsTableTableManager extends RootTableManager<
    _$LocalDb,
    $LocalPaymentSubmissionsTable,
    LocalPaymentSubmission,
    $$LocalPaymentSubmissionsTableFilterComposer,
    $$LocalPaymentSubmissionsTableOrderingComposer,
    $$LocalPaymentSubmissionsTableAnnotationComposer,
    $$LocalPaymentSubmissionsTableCreateCompanionBuilder,
    $$LocalPaymentSubmissionsTableUpdateCompanionBuilder,
    (
      LocalPaymentSubmission,
      BaseReferences<_$LocalDb, $LocalPaymentSubmissionsTable,
          LocalPaymentSubmission>
    ),
    LocalPaymentSubmission,
    PrefetchHooks Function()> {
  $$LocalPaymentSubmissionsTableTableManager(
      _$LocalDb db, $LocalPaymentSubmissionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPaymentSubmissionsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPaymentSubmissionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPaymentSubmissionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> submissionId = const Value.absent(),
            Value<String> tenantId = const Value.absent(),
            Value<String> studentId = const Value.absent(),
            Value<String> channelId = const Value.absent(),
            Value<int> amountPiasters = const Value.absent(),
            Value<String> senderReference = const Value.absent(),
            Value<String> receiptUrl = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> syncStatus = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPaymentSubmissionsCompanion(
            submissionId: submissionId,
            tenantId: tenantId,
            studentId: studentId,
            channelId: channelId,
            amountPiasters: amountPiasters,
            senderReference: senderReference,
            receiptUrl: receiptUrl,
            status: status,
            syncStatus: syncStatus,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String submissionId,
            required String tenantId,
            required String studentId,
            required String channelId,
            required int amountPiasters,
            required String senderReference,
            required String receiptUrl,
            required String status,
            required String syncStatus,
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalPaymentSubmissionsCompanion.insert(
            submissionId: submissionId,
            tenantId: tenantId,
            studentId: studentId,
            channelId: channelId,
            amountPiasters: amountPiasters,
            senderReference: senderReference,
            receiptUrl: receiptUrl,
            status: status,
            syncStatus: syncStatus,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$LocalPaymentSubmissionsTable,
                        LocalPaymentSubmission>(table),
                    BaseReferences<_$LocalDb, $LocalPaymentSubmissionsTable,
                        LocalPaymentSubmission>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalPaymentSubmissionsTableProcessedTableManager
    = ProcessedTableManager<
        _$LocalDb,
        $LocalPaymentSubmissionsTable,
        LocalPaymentSubmission,
        $$LocalPaymentSubmissionsTableFilterComposer,
        $$LocalPaymentSubmissionsTableOrderingComposer,
        $$LocalPaymentSubmissionsTableAnnotationComposer,
        $$LocalPaymentSubmissionsTableCreateCompanionBuilder,
        $$LocalPaymentSubmissionsTableUpdateCompanionBuilder,
        (
          LocalPaymentSubmission,
          BaseReferences<_$LocalDb, $LocalPaymentSubmissionsTable,
              LocalPaymentSubmission>
        ),
        LocalPaymentSubmission,
        PrefetchHooks Function()>;
typedef $$SyncQueueTableTableCreateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<int> id,
  required String collectionName,
  required String documentId,
  required String operation,
  required String dataJson,
  required int priority,
  required String status,
  Value<int> retryCount,
  required DateTime createdAt,
});
typedef $$SyncQueueTableTableUpdateCompanionBuilder = SyncQueueTableCompanion
    Function({
  Value<int> id,
  Value<String> collectionName,
  Value<String> documentId,
  Value<String> operation,
  Value<String> dataJson,
  Value<int> priority,
  Value<String> status,
  Value<int> retryCount,
  Value<DateTime> createdAt,
});

class $$SyncQueueTableTableFilterComposer
    extends Composer<_$LocalDb, $SyncQueueTableTable> {
  $$SyncQueueTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get collectionName => $composableBuilder(
      column: $table.collectionName,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dataJson => $composableBuilder(
      column: $table.dataJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableTableOrderingComposer
    extends Composer<_$LocalDb, $SyncQueueTableTable> {
  $$SyncQueueTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get collectionName => $composableBuilder(
      column: $table.collectionName,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dataJson => $composableBuilder(
      column: $table.dataJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableTableAnnotationComposer
    extends Composer<_$LocalDb, $SyncQueueTableTable> {
  $$SyncQueueTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get collectionName => $composableBuilder(
      column: $table.collectionName, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
      column: $table.documentId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableTableManager extends RootTableManager<
    _$LocalDb,
    $SyncQueueTableTable,
    SyncQueueTableData,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueTableData,
      BaseReferences<_$LocalDb, $SyncQueueTableTable, SyncQueueTableData>
    ),
    SyncQueueTableData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableTableManager(_$LocalDb db, $SyncQueueTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> collectionName = const Value.absent(),
            Value<String> documentId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> dataJson = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SyncQueueTableCompanion(
            id: id,
            collectionName: collectionName,
            documentId: documentId,
            operation: operation,
            dataJson: dataJson,
            priority: priority,
            status: status,
            retryCount: retryCount,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String collectionName,
            required String documentId,
            required String operation,
            required String dataJson,
            required int priority,
            required String status,
            Value<int> retryCount = const Value.absent(),
            required DateTime createdAt,
          }) =>
              SyncQueueTableCompanion.insert(
            id: id,
            collectionName: collectionName,
            documentId: documentId,
            operation: operation,
            dataJson: dataJson,
            priority: priority,
            status: status,
            retryCount: retryCount,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable<$SyncQueueTableTable, SyncQueueTableData>(
                        table),
                    BaseReferences<_$LocalDb, $SyncQueueTableTable,
                        SyncQueueTableData>(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableTableProcessedTableManager = ProcessedTableManager<
    _$LocalDb,
    $SyncQueueTableTable,
    SyncQueueTableData,
    $$SyncQueueTableTableFilterComposer,
    $$SyncQueueTableTableOrderingComposer,
    $$SyncQueueTableTableAnnotationComposer,
    $$SyncQueueTableTableCreateCompanionBuilder,
    $$SyncQueueTableTableUpdateCompanionBuilder,
    (
      SyncQueueTableData,
      BaseReferences<_$LocalDb, $SyncQueueTableTable, SyncQueueTableData>
    ),
    SyncQueueTableData,
    PrefetchHooks Function()>;

class $LocalDbManager {
  final _$LocalDb _db;
  $LocalDbManager(this._db);
  $$LocalStudentsTableTableManager get localStudents =>
      $$LocalStudentsTableTableManager(_db, _db.localStudents);
  $$LocalSessionsTableTableManager get localSessions =>
      $$LocalSessionsTableTableManager(_db, _db.localSessions);
  $$LocalAttendanceTableTableManager get localAttendance =>
      $$LocalAttendanceTableTableManager(_db, _db.localAttendance);
  $$LocalTransactionsTableTableManager get localTransactions =>
      $$LocalTransactionsTableTableManager(_db, _db.localTransactions);
  $$LocalQuizzesTableTableManager get localQuizzes =>
      $$LocalQuizzesTableTableManager(_db, _db.localQuizzes);
  $$LocalPaymentSubmissionsTableTableManager get localPaymentSubmissions =>
      $$LocalPaymentSubmissionsTableTableManager(
          _db, _db.localPaymentSubmissions);
  $$SyncQueueTableTableTableManager get syncQueueTable =>
      $$SyncQueueTableTableTableManager(_db, _db.syncQueueTable);
}
