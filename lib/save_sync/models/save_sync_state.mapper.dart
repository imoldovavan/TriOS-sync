// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'save_sync_state.dart';

class SaveSyncStateMapper extends ClassMapperBase<SaveSyncState> {
  SaveSyncStateMapper._();

  static SaveSyncStateMapper? _instance;
  static SaveSyncStateMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SaveSyncStateMapper._());
      SaveSyncRecordMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SaveSyncState';

  static String? _$machineId(SaveSyncState v) => v.machineId;
  static const Field<SaveSyncState, String> _f$machineId = Field(
    'machineId',
    _$machineId,
    opt: true,
  );
  static Map<String, SaveSyncRecord> _$records(SaveSyncState v) => v.records;
  static const Field<SaveSyncState, Map<String, SaveSyncRecord>> _f$records =
      Field('records', _$records, opt: true, def: const {});

  @override
  final MappableFields<SaveSyncState> fields = const {
    #machineId: _f$machineId,
    #records: _f$records,
  };

  static SaveSyncState _instantiate(DecodingData data) {
    return SaveSyncState(
      machineId: data.dec(_f$machineId),
      records: data.dec(_f$records),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SaveSyncState fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SaveSyncState>(map);
  }

  static SaveSyncState fromJson(String json) {
    return ensureInitialized().decodeJson<SaveSyncState>(json);
  }
}

mixin SaveSyncStateMappable {
  String toJson() {
    return SaveSyncStateMapper.ensureInitialized().encodeJson<SaveSyncState>(
      this as SaveSyncState,
    );
  }

  Map<String, dynamic> toMap() {
    return SaveSyncStateMapper.ensureInitialized().encodeMap<SaveSyncState>(
      this as SaveSyncState,
    );
  }

  SaveSyncStateCopyWith<SaveSyncState, SaveSyncState, SaveSyncState>
  get copyWith => _SaveSyncStateCopyWithImpl<SaveSyncState, SaveSyncState>(
    this as SaveSyncState,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return SaveSyncStateMapper.ensureInitialized().stringifyValue(
      this as SaveSyncState,
    );
  }

  @override
  bool operator ==(Object other) {
    return SaveSyncStateMapper.ensureInitialized().equalsValue(
      this as SaveSyncState,
      other,
    );
  }

  @override
  int get hashCode {
    return SaveSyncStateMapper.ensureInitialized().hashValue(
      this as SaveSyncState,
    );
  }
}

extension SaveSyncStateValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SaveSyncState, $Out> {
  SaveSyncStateCopyWith<$R, SaveSyncState, $Out> get $asSaveSyncState =>
      $base.as((v, t, t2) => _SaveSyncStateCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SaveSyncStateCopyWith<$R, $In extends SaveSyncState, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  MapCopyWith<
    $R,
    String,
    SaveSyncRecord,
    SaveSyncRecordCopyWith<$R, SaveSyncRecord, SaveSyncRecord>
  >
  get records;
  $R call({String? machineId, Map<String, SaveSyncRecord>? records});
  SaveSyncStateCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _SaveSyncStateCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SaveSyncState, $Out>
    implements SaveSyncStateCopyWith<$R, SaveSyncState, $Out> {
  _SaveSyncStateCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SaveSyncState> $mapper =
      SaveSyncStateMapper.ensureInitialized();
  @override
  MapCopyWith<
    $R,
    String,
    SaveSyncRecord,
    SaveSyncRecordCopyWith<$R, SaveSyncRecord, SaveSyncRecord>
  >
  get records => MapCopyWith(
    $value.records,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(records: v),
  );
  @override
  $R call({Object? machineId = $none, Map<String, SaveSyncRecord>? records}) =>
      $apply(
        FieldCopyWithData({
          if (machineId != $none) #machineId: machineId,
          if (records != null) #records: records,
        }),
      );
  @override
  SaveSyncState $make(CopyWithData data) => SaveSyncState(
    machineId: data.get(#machineId, or: $value.machineId),
    records: data.get(#records, or: $value.records),
  );

  @override
  SaveSyncStateCopyWith<$R2, SaveSyncState, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SaveSyncStateCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class SaveSyncRecordMapper extends ClassMapperBase<SaveSyncRecord> {
  SaveSyncRecordMapper._();

  static SaveSyncRecordMapper? _instance;
  static SaveSyncRecordMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SaveSyncRecordMapper._());
      SaveSyncManifestMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SaveSyncRecord';

  static String _$saveFolderName(SaveSyncRecord v) => v.saveFolderName;
  static const Field<SaveSyncRecord, String> _f$saveFolderName = Field(
    'saveFolderName',
    _$saveFolderName,
  );
  static String _$contentHash(SaveSyncRecord v) => v.contentHash;
  static const Field<SaveSyncRecord, String> _f$contentHash = Field(
    'contentHash',
    _$contentHash,
  );
  static SaveSyncManifest _$manifest(SaveSyncRecord v) => v.manifest;
  static const Field<SaveSyncRecord, SaveSyncManifest> _f$manifest = Field(
    'manifest',
    _$manifest,
  );
  static DateTime _$syncedAt(SaveSyncRecord v) => v.syncedAt;
  static const Field<SaveSyncRecord, DateTime> _f$syncedAt = Field(
    'syncedAt',
    _$syncedAt,
  );

  @override
  final MappableFields<SaveSyncRecord> fields = const {
    #saveFolderName: _f$saveFolderName,
    #contentHash: _f$contentHash,
    #manifest: _f$manifest,
    #syncedAt: _f$syncedAt,
  };

  static SaveSyncRecord _instantiate(DecodingData data) {
    return SaveSyncRecord(
      saveFolderName: data.dec(_f$saveFolderName),
      contentHash: data.dec(_f$contentHash),
      manifest: data.dec(_f$manifest),
      syncedAt: data.dec(_f$syncedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SaveSyncRecord fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SaveSyncRecord>(map);
  }

  static SaveSyncRecord fromJson(String json) {
    return ensureInitialized().decodeJson<SaveSyncRecord>(json);
  }
}

mixin SaveSyncRecordMappable {
  String toJson() {
    return SaveSyncRecordMapper.ensureInitialized().encodeJson<SaveSyncRecord>(
      this as SaveSyncRecord,
    );
  }

  Map<String, dynamic> toMap() {
    return SaveSyncRecordMapper.ensureInitialized().encodeMap<SaveSyncRecord>(
      this as SaveSyncRecord,
    );
  }

  SaveSyncRecordCopyWith<SaveSyncRecord, SaveSyncRecord, SaveSyncRecord>
  get copyWith => _SaveSyncRecordCopyWithImpl<SaveSyncRecord, SaveSyncRecord>(
    this as SaveSyncRecord,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return SaveSyncRecordMapper.ensureInitialized().stringifyValue(
      this as SaveSyncRecord,
    );
  }

  @override
  bool operator ==(Object other) {
    return SaveSyncRecordMapper.ensureInitialized().equalsValue(
      this as SaveSyncRecord,
      other,
    );
  }

  @override
  int get hashCode {
    return SaveSyncRecordMapper.ensureInitialized().hashValue(
      this as SaveSyncRecord,
    );
  }
}

extension SaveSyncRecordValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SaveSyncRecord, $Out> {
  SaveSyncRecordCopyWith<$R, SaveSyncRecord, $Out> get $asSaveSyncRecord =>
      $base.as((v, t, t2) => _SaveSyncRecordCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SaveSyncRecordCopyWith<$R, $In extends SaveSyncRecord, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  SaveSyncManifestCopyWith<$R, SaveSyncManifest, SaveSyncManifest> get manifest;
  $R call({
    String? saveFolderName,
    String? contentHash,
    SaveSyncManifest? manifest,
    DateTime? syncedAt,
  });
  SaveSyncRecordCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SaveSyncRecordCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SaveSyncRecord, $Out>
    implements SaveSyncRecordCopyWith<$R, SaveSyncRecord, $Out> {
  _SaveSyncRecordCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SaveSyncRecord> $mapper =
      SaveSyncRecordMapper.ensureInitialized();
  @override
  SaveSyncManifestCopyWith<$R, SaveSyncManifest, SaveSyncManifest>
  get manifest => $value.manifest.copyWith.$chain((v) => call(manifest: v));
  @override
  $R call({
    String? saveFolderName,
    String? contentHash,
    SaveSyncManifest? manifest,
    DateTime? syncedAt,
  }) => $apply(
    FieldCopyWithData({
      if (saveFolderName != null) #saveFolderName: saveFolderName,
      if (contentHash != null) #contentHash: contentHash,
      if (manifest != null) #manifest: manifest,
      if (syncedAt != null) #syncedAt: syncedAt,
    }),
  );
  @override
  SaveSyncRecord $make(CopyWithData data) => SaveSyncRecord(
    saveFolderName: data.get(#saveFolderName, or: $value.saveFolderName),
    contentHash: data.get(#contentHash, or: $value.contentHash),
    manifest: data.get(#manifest, or: $value.manifest),
    syncedAt: data.get(#syncedAt, or: $value.syncedAt),
  );

  @override
  SaveSyncRecordCopyWith<$R2, SaveSyncRecord, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SaveSyncRecordCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

