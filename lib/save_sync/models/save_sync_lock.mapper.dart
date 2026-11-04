// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'save_sync_lock.dart';

class SaveSyncLockMapper extends ClassMapperBase<SaveSyncLock> {
  SaveSyncLockMapper._();

  static SaveSyncLockMapper? _instance;
  static SaveSyncLockMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SaveSyncLockMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SaveSyncLock';

  static String _$machineId(SaveSyncLock v) => v.machineId;
  static const Field<SaveSyncLock, String> _f$machineId = Field(
    'machineId',
    _$machineId,
  );
  static String _$machineName(SaveSyncLock v) => v.machineName;
  static const Field<SaveSyncLock, String> _f$machineName = Field(
    'machineName',
    _$machineName,
  );
  static String _$os(SaveSyncLock v) => v.os;
  static const Field<SaveSyncLock, String> _f$os = Field('os', _$os);
  static String? _$triosVersion(SaveSyncLock v) => v.triosVersion;
  static const Field<SaveSyncLock, String> _f$triosVersion = Field(
    'triosVersion',
    _$triosVersion,
    opt: true,
  );
  static DateTime _$startedAt(SaveSyncLock v) => v.startedAt;
  static const Field<SaveSyncLock, DateTime> _f$startedAt = Field(
    'startedAt',
    _$startedAt,
  );

  @override
  final MappableFields<SaveSyncLock> fields = const {
    #machineId: _f$machineId,
    #machineName: _f$machineName,
    #os: _f$os,
    #triosVersion: _f$triosVersion,
    #startedAt: _f$startedAt,
  };

  static SaveSyncLock _instantiate(DecodingData data) {
    return SaveSyncLock(
      machineId: data.dec(_f$machineId),
      machineName: data.dec(_f$machineName),
      os: data.dec(_f$os),
      triosVersion: data.dec(_f$triosVersion),
      startedAt: data.dec(_f$startedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SaveSyncLock fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SaveSyncLock>(map);
  }

  static SaveSyncLock fromJson(String json) {
    return ensureInitialized().decodeJson<SaveSyncLock>(json);
  }
}

mixin SaveSyncLockMappable {
  String toJson() {
    return SaveSyncLockMapper.ensureInitialized().encodeJson<SaveSyncLock>(
      this as SaveSyncLock,
    );
  }

  Map<String, dynamic> toMap() {
    return SaveSyncLockMapper.ensureInitialized().encodeMap<SaveSyncLock>(
      this as SaveSyncLock,
    );
  }

  SaveSyncLockCopyWith<SaveSyncLock, SaveSyncLock, SaveSyncLock> get copyWith =>
      _SaveSyncLockCopyWithImpl<SaveSyncLock, SaveSyncLock>(
        this as SaveSyncLock,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SaveSyncLockMapper.ensureInitialized().stringifyValue(
      this as SaveSyncLock,
    );
  }

  @override
  bool operator ==(Object other) {
    return SaveSyncLockMapper.ensureInitialized().equalsValue(
      this as SaveSyncLock,
      other,
    );
  }

  @override
  int get hashCode {
    return SaveSyncLockMapper.ensureInitialized().hashValue(
      this as SaveSyncLock,
    );
  }
}

extension SaveSyncLockValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SaveSyncLock, $Out> {
  SaveSyncLockCopyWith<$R, SaveSyncLock, $Out> get $asSaveSyncLock =>
      $base.as((v, t, t2) => _SaveSyncLockCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SaveSyncLockCopyWith<$R, $In extends SaveSyncLock, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? machineId,
    String? machineName,
    String? os,
    String? triosVersion,
    DateTime? startedAt,
  });
  SaveSyncLockCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SaveSyncLockCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SaveSyncLock, $Out>
    implements SaveSyncLockCopyWith<$R, SaveSyncLock, $Out> {
  _SaveSyncLockCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SaveSyncLock> $mapper =
      SaveSyncLockMapper.ensureInitialized();
  @override
  $R call({
    String? machineId,
    String? machineName,
    String? os,
    Object? triosVersion = $none,
    DateTime? startedAt,
  }) => $apply(
    FieldCopyWithData({
      if (machineId != null) #machineId: machineId,
      if (machineName != null) #machineName: machineName,
      if (os != null) #os: os,
      if (triosVersion != $none) #triosVersion: triosVersion,
      if (startedAt != null) #startedAt: startedAt,
    }),
  );
  @override
  SaveSyncLock $make(CopyWithData data) => SaveSyncLock(
    machineId: data.get(#machineId, or: $value.machineId),
    machineName: data.get(#machineName, or: $value.machineName),
    os: data.get(#os, or: $value.os),
    triosVersion: data.get(#triosVersion, or: $value.triosVersion),
    startedAt: data.get(#startedAt, or: $value.startedAt),
  );

  @override
  SaveSyncLockCopyWith<$R2, SaveSyncLock, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SaveSyncLockCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

