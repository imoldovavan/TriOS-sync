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
      ModSyncRecordMapper.ensureInitialized();
      ModFolderHashMapper.ensureInitialized();
      EnabledModListRecordMapper.ensureInitialized();
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
  static Map<String, ModSyncRecord> _$modRecords(SaveSyncState v) =>
      v.modRecords;
  static const Field<SaveSyncState, Map<String, ModSyncRecord>> _f$modRecords =
      Field('modRecords', _$modRecords, opt: true, def: const {});
  static Map<String, ModFolderHash> _$modHashes(SaveSyncState v) => v.modHashes;
  static const Field<SaveSyncState, Map<String, ModFolderHash>> _f$modHashes =
      Field('modHashes', _$modHashes, opt: true, def: const {});
  static Map<String, EnabledModListRecord> _$enabledModListRecords(
    SaveSyncState v,
  ) => v.enabledModListRecords;
  static const Field<SaveSyncState, Map<String, EnabledModListRecord>>
  _f$enabledModListRecords = Field(
    'enabledModListRecords',
    _$enabledModListRecords,
    opt: true,
    def: const {},
  );

  @override
  final MappableFields<SaveSyncState> fields = const {
    #machineId: _f$machineId,
    #records: _f$records,
    #modRecords: _f$modRecords,
    #modHashes: _f$modHashes,
    #enabledModListRecords: _f$enabledModListRecords,
  };

  static SaveSyncState _instantiate(DecodingData data) {
    return SaveSyncState(
      machineId: data.dec(_f$machineId),
      records: data.dec(_f$records),
      modRecords: data.dec(_f$modRecords),
      modHashes: data.dec(_f$modHashes),
      enabledModListRecords: data.dec(_f$enabledModListRecords),
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
  MapCopyWith<
    $R,
    String,
    ModSyncRecord,
    ModSyncRecordCopyWith<$R, ModSyncRecord, ModSyncRecord>
  >
  get modRecords;
  MapCopyWith<
    $R,
    String,
    ModFolderHash,
    ModFolderHashCopyWith<$R, ModFolderHash, ModFolderHash>
  >
  get modHashes;
  MapCopyWith<
    $R,
    String,
    EnabledModListRecord,
    EnabledModListRecordCopyWith<$R, EnabledModListRecord, EnabledModListRecord>
  >
  get enabledModListRecords;
  $R call({
    String? machineId,
    Map<String, SaveSyncRecord>? records,
    Map<String, ModSyncRecord>? modRecords,
    Map<String, ModFolderHash>? modHashes,
    Map<String, EnabledModListRecord>? enabledModListRecords,
  });
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
  MapCopyWith<
    $R,
    String,
    ModSyncRecord,
    ModSyncRecordCopyWith<$R, ModSyncRecord, ModSyncRecord>
  >
  get modRecords => MapCopyWith(
    $value.modRecords,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(modRecords: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    ModFolderHash,
    ModFolderHashCopyWith<$R, ModFolderHash, ModFolderHash>
  >
  get modHashes => MapCopyWith(
    $value.modHashes,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(modHashes: v),
  );
  @override
  MapCopyWith<
    $R,
    String,
    EnabledModListRecord,
    EnabledModListRecordCopyWith<$R, EnabledModListRecord, EnabledModListRecord>
  >
  get enabledModListRecords => MapCopyWith(
    $value.enabledModListRecords,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(enabledModListRecords: v),
  );
  @override
  $R call({
    Object? machineId = $none,
    Map<String, SaveSyncRecord>? records,
    Map<String, ModSyncRecord>? modRecords,
    Map<String, ModFolderHash>? modHashes,
    Map<String, EnabledModListRecord>? enabledModListRecords,
  }) => $apply(
    FieldCopyWithData({
      if (machineId != $none) #machineId: machineId,
      if (records != null) #records: records,
      if (modRecords != null) #modRecords: modRecords,
      if (modHashes != null) #modHashes: modHashes,
      if (enabledModListRecords != null)
        #enabledModListRecords: enabledModListRecords,
    }),
  );
  @override
  SaveSyncState $make(CopyWithData data) => SaveSyncState(
    machineId: data.get(#machineId, or: $value.machineId),
    records: data.get(#records, or: $value.records),
    modRecords: data.get(#modRecords, or: $value.modRecords),
    modHashes: data.get(#modHashes, or: $value.modHashes),
    enabledModListRecords: data.get(
      #enabledModListRecords,
      or: $value.enabledModListRecords,
    ),
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

class ModSyncRecordMapper extends ClassMapperBase<ModSyncRecord> {
  ModSyncRecordMapper._();

  static ModSyncRecordMapper? _instance;
  static ModSyncRecordMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModSyncRecordMapper._());
      ModSyncManifestMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModSyncRecord';

  static String _$folderName(ModSyncRecord v) => v.folderName;
  static const Field<ModSyncRecord, String> _f$folderName = Field(
    'folderName',
    _$folderName,
  );
  static String _$contentHash(ModSyncRecord v) => v.contentHash;
  static const Field<ModSyncRecord, String> _f$contentHash = Field(
    'contentHash',
    _$contentHash,
  );
  static ModSyncManifest _$manifest(ModSyncRecord v) => v.manifest;
  static const Field<ModSyncRecord, ModSyncManifest> _f$manifest = Field(
    'manifest',
    _$manifest,
  );
  static DateTime _$syncedAt(ModSyncRecord v) => v.syncedAt;
  static const Field<ModSyncRecord, DateTime> _f$syncedAt = Field(
    'syncedAt',
    _$syncedAt,
  );

  @override
  final MappableFields<ModSyncRecord> fields = const {
    #folderName: _f$folderName,
    #contentHash: _f$contentHash,
    #manifest: _f$manifest,
    #syncedAt: _f$syncedAt,
  };

  static ModSyncRecord _instantiate(DecodingData data) {
    return ModSyncRecord(
      folderName: data.dec(_f$folderName),
      contentHash: data.dec(_f$contentHash),
      manifest: data.dec(_f$manifest),
      syncedAt: data.dec(_f$syncedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModSyncRecord fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModSyncRecord>(map);
  }

  static ModSyncRecord fromJson(String json) {
    return ensureInitialized().decodeJson<ModSyncRecord>(json);
  }
}

mixin ModSyncRecordMappable {
  String toJson() {
    return ModSyncRecordMapper.ensureInitialized().encodeJson<ModSyncRecord>(
      this as ModSyncRecord,
    );
  }

  Map<String, dynamic> toMap() {
    return ModSyncRecordMapper.ensureInitialized().encodeMap<ModSyncRecord>(
      this as ModSyncRecord,
    );
  }

  ModSyncRecordCopyWith<ModSyncRecord, ModSyncRecord, ModSyncRecord>
  get copyWith => _ModSyncRecordCopyWithImpl<ModSyncRecord, ModSyncRecord>(
    this as ModSyncRecord,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return ModSyncRecordMapper.ensureInitialized().stringifyValue(
      this as ModSyncRecord,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModSyncRecordMapper.ensureInitialized().equalsValue(
      this as ModSyncRecord,
      other,
    );
  }

  @override
  int get hashCode {
    return ModSyncRecordMapper.ensureInitialized().hashValue(
      this as ModSyncRecord,
    );
  }
}

extension ModSyncRecordValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModSyncRecord, $Out> {
  ModSyncRecordCopyWith<$R, ModSyncRecord, $Out> get $asModSyncRecord =>
      $base.as((v, t, t2) => _ModSyncRecordCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModSyncRecordCopyWith<$R, $In extends ModSyncRecord, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ModSyncManifestCopyWith<$R, ModSyncManifest, ModSyncManifest> get manifest;
  $R call({
    String? folderName,
    String? contentHash,
    ModSyncManifest? manifest,
    DateTime? syncedAt,
  });
  ModSyncRecordCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModSyncRecordCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModSyncRecord, $Out>
    implements ModSyncRecordCopyWith<$R, ModSyncRecord, $Out> {
  _ModSyncRecordCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModSyncRecord> $mapper =
      ModSyncRecordMapper.ensureInitialized();
  @override
  ModSyncManifestCopyWith<$R, ModSyncManifest, ModSyncManifest> get manifest =>
      $value.manifest.copyWith.$chain((v) => call(manifest: v));
  @override
  $R call({
    String? folderName,
    String? contentHash,
    ModSyncManifest? manifest,
    DateTime? syncedAt,
  }) => $apply(
    FieldCopyWithData({
      if (folderName != null) #folderName: folderName,
      if (contentHash != null) #contentHash: contentHash,
      if (manifest != null) #manifest: manifest,
      if (syncedAt != null) #syncedAt: syncedAt,
    }),
  );
  @override
  ModSyncRecord $make(CopyWithData data) => ModSyncRecord(
    folderName: data.get(#folderName, or: $value.folderName),
    contentHash: data.get(#contentHash, or: $value.contentHash),
    manifest: data.get(#manifest, or: $value.manifest),
    syncedAt: data.get(#syncedAt, or: $value.syncedAt),
  );

  @override
  ModSyncRecordCopyWith<$R2, ModSyncRecord, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModSyncRecordCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ModFolderHashMapper extends ClassMapperBase<ModFolderHash> {
  ModFolderHashMapper._();

  static ModFolderHashMapper? _instance;
  static ModFolderHashMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModFolderHashMapper._());
      ModFolderFingerprintMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ModFolderHash';

  static ModFolderFingerprint _$fingerprint(ModFolderHash v) => v.fingerprint;
  static const Field<ModFolderHash, ModFolderFingerprint> _f$fingerprint =
      Field('fingerprint', _$fingerprint);
  static String _$contentHash(ModFolderHash v) => v.contentHash;
  static const Field<ModFolderHash, String> _f$contentHash = Field(
    'contentHash',
    _$contentHash,
  );

  @override
  final MappableFields<ModFolderHash> fields = const {
    #fingerprint: _f$fingerprint,
    #contentHash: _f$contentHash,
  };

  static ModFolderHash _instantiate(DecodingData data) {
    return ModFolderHash(
      fingerprint: data.dec(_f$fingerprint),
      contentHash: data.dec(_f$contentHash),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModFolderHash fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModFolderHash>(map);
  }

  static ModFolderHash fromJson(String json) {
    return ensureInitialized().decodeJson<ModFolderHash>(json);
  }
}

mixin ModFolderHashMappable {
  String toJson() {
    return ModFolderHashMapper.ensureInitialized().encodeJson<ModFolderHash>(
      this as ModFolderHash,
    );
  }

  Map<String, dynamic> toMap() {
    return ModFolderHashMapper.ensureInitialized().encodeMap<ModFolderHash>(
      this as ModFolderHash,
    );
  }

  ModFolderHashCopyWith<ModFolderHash, ModFolderHash, ModFolderHash>
  get copyWith => _ModFolderHashCopyWithImpl<ModFolderHash, ModFolderHash>(
    this as ModFolderHash,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return ModFolderHashMapper.ensureInitialized().stringifyValue(
      this as ModFolderHash,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModFolderHashMapper.ensureInitialized().equalsValue(
      this as ModFolderHash,
      other,
    );
  }

  @override
  int get hashCode {
    return ModFolderHashMapper.ensureInitialized().hashValue(
      this as ModFolderHash,
    );
  }
}

extension ModFolderHashValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModFolderHash, $Out> {
  ModFolderHashCopyWith<$R, ModFolderHash, $Out> get $asModFolderHash =>
      $base.as((v, t, t2) => _ModFolderHashCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModFolderHashCopyWith<$R, $In extends ModFolderHash, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ModFolderFingerprintCopyWith<$R, ModFolderFingerprint, ModFolderFingerprint>
  get fingerprint;
  $R call({ModFolderFingerprint? fingerprint, String? contentHash});
  ModFolderHashCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ModFolderHashCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModFolderHash, $Out>
    implements ModFolderHashCopyWith<$R, ModFolderHash, $Out> {
  _ModFolderHashCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModFolderHash> $mapper =
      ModFolderHashMapper.ensureInitialized();
  @override
  ModFolderFingerprintCopyWith<$R, ModFolderFingerprint, ModFolderFingerprint>
  get fingerprint =>
      $value.fingerprint.copyWith.$chain((v) => call(fingerprint: v));
  @override
  $R call({ModFolderFingerprint? fingerprint, String? contentHash}) => $apply(
    FieldCopyWithData({
      if (fingerprint != null) #fingerprint: fingerprint,
      if (contentHash != null) #contentHash: contentHash,
    }),
  );
  @override
  ModFolderHash $make(CopyWithData data) => ModFolderHash(
    fingerprint: data.get(#fingerprint, or: $value.fingerprint),
    contentHash: data.get(#contentHash, or: $value.contentHash),
  );

  @override
  ModFolderHashCopyWith<$R2, ModFolderHash, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModFolderHashCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ModFolderFingerprintMapper extends ClassMapperBase<ModFolderFingerprint> {
  ModFolderFingerprintMapper._();

  static ModFolderFingerprintMapper? _instance;
  static ModFolderFingerprintMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModFolderFingerprintMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ModFolderFingerprint';

  static int _$fileCount(ModFolderFingerprint v) => v.fileCount;
  static const Field<ModFolderFingerprint, int> _f$fileCount = Field(
    'fileCount',
    _$fileCount,
  );
  static int _$totalBytes(ModFolderFingerprint v) => v.totalBytes;
  static const Field<ModFolderFingerprint, int> _f$totalBytes = Field(
    'totalBytes',
    _$totalBytes,
  );
  static int _$newestModifiedMs(ModFolderFingerprint v) => v.newestModifiedMs;
  static const Field<ModFolderFingerprint, int> _f$newestModifiedMs = Field(
    'newestModifiedMs',
    _$newestModifiedMs,
  );

  @override
  final MappableFields<ModFolderFingerprint> fields = const {
    #fileCount: _f$fileCount,
    #totalBytes: _f$totalBytes,
    #newestModifiedMs: _f$newestModifiedMs,
  };

  static ModFolderFingerprint _instantiate(DecodingData data) {
    return ModFolderFingerprint(
      fileCount: data.dec(_f$fileCount),
      totalBytes: data.dec(_f$totalBytes),
      newestModifiedMs: data.dec(_f$newestModifiedMs),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModFolderFingerprint fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModFolderFingerprint>(map);
  }

  static ModFolderFingerprint fromJson(String json) {
    return ensureInitialized().decodeJson<ModFolderFingerprint>(json);
  }
}

mixin ModFolderFingerprintMappable {
  String toJson() {
    return ModFolderFingerprintMapper.ensureInitialized()
        .encodeJson<ModFolderFingerprint>(this as ModFolderFingerprint);
  }

  Map<String, dynamic> toMap() {
    return ModFolderFingerprintMapper.ensureInitialized()
        .encodeMap<ModFolderFingerprint>(this as ModFolderFingerprint);
  }

  ModFolderFingerprintCopyWith<
    ModFolderFingerprint,
    ModFolderFingerprint,
    ModFolderFingerprint
  >
  get copyWith =>
      _ModFolderFingerprintCopyWithImpl<
        ModFolderFingerprint,
        ModFolderFingerprint
      >(this as ModFolderFingerprint, $identity, $identity);
  @override
  String toString() {
    return ModFolderFingerprintMapper.ensureInitialized().stringifyValue(
      this as ModFolderFingerprint,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModFolderFingerprintMapper.ensureInitialized().equalsValue(
      this as ModFolderFingerprint,
      other,
    );
  }

  @override
  int get hashCode {
    return ModFolderFingerprintMapper.ensureInitialized().hashValue(
      this as ModFolderFingerprint,
    );
  }
}

extension ModFolderFingerprintValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModFolderFingerprint, $Out> {
  ModFolderFingerprintCopyWith<$R, ModFolderFingerprint, $Out>
  get $asModFolderFingerprint => $base.as(
    (v, t, t2) => _ModFolderFingerprintCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class ModFolderFingerprintCopyWith<
  $R,
  $In extends ModFolderFingerprint,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? fileCount, int? totalBytes, int? newestModifiedMs});
  ModFolderFingerprintCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ModFolderFingerprintCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModFolderFingerprint, $Out>
    implements ModFolderFingerprintCopyWith<$R, ModFolderFingerprint, $Out> {
  _ModFolderFingerprintCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModFolderFingerprint> $mapper =
      ModFolderFingerprintMapper.ensureInitialized();
  @override
  $R call({int? fileCount, int? totalBytes, int? newestModifiedMs}) => $apply(
    FieldCopyWithData({
      if (fileCount != null) #fileCount: fileCount,
      if (totalBytes != null) #totalBytes: totalBytes,
      if (newestModifiedMs != null) #newestModifiedMs: newestModifiedMs,
    }),
  );
  @override
  ModFolderFingerprint $make(CopyWithData data) => ModFolderFingerprint(
    fileCount: data.get(#fileCount, or: $value.fileCount),
    totalBytes: data.get(#totalBytes, or: $value.totalBytes),
    newestModifiedMs: data.get(#newestModifiedMs, or: $value.newestModifiedMs),
  );

  @override
  ModFolderFingerprintCopyWith<$R2, ModFolderFingerprint, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _ModFolderFingerprintCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class EnabledModListRecordMapper extends ClassMapperBase<EnabledModListRecord> {
  EnabledModListRecordMapper._();

  static EnabledModListRecordMapper? _instance;
  static EnabledModListRecordMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EnabledModListRecordMapper._());
      EnabledModListManifestMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'EnabledModListRecord';

  static String _$contentHash(EnabledModListRecord v) => v.contentHash;
  static const Field<EnabledModListRecord, String> _f$contentHash = Field(
    'contentHash',
    _$contentHash,
  );
  static EnabledModListManifest _$manifest(EnabledModListRecord v) =>
      v.manifest;
  static const Field<EnabledModListRecord, EnabledModListManifest> _f$manifest =
      Field('manifest', _$manifest);
  static DateTime _$syncedAt(EnabledModListRecord v) => v.syncedAt;
  static const Field<EnabledModListRecord, DateTime> _f$syncedAt = Field(
    'syncedAt',
    _$syncedAt,
  );

  @override
  final MappableFields<EnabledModListRecord> fields = const {
    #contentHash: _f$contentHash,
    #manifest: _f$manifest,
    #syncedAt: _f$syncedAt,
  };

  static EnabledModListRecord _instantiate(DecodingData data) {
    return EnabledModListRecord(
      contentHash: data.dec(_f$contentHash),
      manifest: data.dec(_f$manifest),
      syncedAt: data.dec(_f$syncedAt),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static EnabledModListRecord fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<EnabledModListRecord>(map);
  }

  static EnabledModListRecord fromJson(String json) {
    return ensureInitialized().decodeJson<EnabledModListRecord>(json);
  }
}

mixin EnabledModListRecordMappable {
  String toJson() {
    return EnabledModListRecordMapper.ensureInitialized()
        .encodeJson<EnabledModListRecord>(this as EnabledModListRecord);
  }

  Map<String, dynamic> toMap() {
    return EnabledModListRecordMapper.ensureInitialized()
        .encodeMap<EnabledModListRecord>(this as EnabledModListRecord);
  }

  EnabledModListRecordCopyWith<
    EnabledModListRecord,
    EnabledModListRecord,
    EnabledModListRecord
  >
  get copyWith =>
      _EnabledModListRecordCopyWithImpl<
        EnabledModListRecord,
        EnabledModListRecord
      >(this as EnabledModListRecord, $identity, $identity);
  @override
  String toString() {
    return EnabledModListRecordMapper.ensureInitialized().stringifyValue(
      this as EnabledModListRecord,
    );
  }

  @override
  bool operator ==(Object other) {
    return EnabledModListRecordMapper.ensureInitialized().equalsValue(
      this as EnabledModListRecord,
      other,
    );
  }

  @override
  int get hashCode {
    return EnabledModListRecordMapper.ensureInitialized().hashValue(
      this as EnabledModListRecord,
    );
  }
}

extension EnabledModListRecordValueCopy<$R, $Out>
    on ObjectCopyWith<$R, EnabledModListRecord, $Out> {
  EnabledModListRecordCopyWith<$R, EnabledModListRecord, $Out>
  get $asEnabledModListRecord => $base.as(
    (v, t, t2) => _EnabledModListRecordCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class EnabledModListRecordCopyWith<
  $R,
  $In extends EnabledModListRecord,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  EnabledModListManifestCopyWith<
    $R,
    EnabledModListManifest,
    EnabledModListManifest
  >
  get manifest;
  $R call({
    String? contentHash,
    EnabledModListManifest? manifest,
    DateTime? syncedAt,
  });
  EnabledModListRecordCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _EnabledModListRecordCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, EnabledModListRecord, $Out>
    implements EnabledModListRecordCopyWith<$R, EnabledModListRecord, $Out> {
  _EnabledModListRecordCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<EnabledModListRecord> $mapper =
      EnabledModListRecordMapper.ensureInitialized();
  @override
  EnabledModListManifestCopyWith<
    $R,
    EnabledModListManifest,
    EnabledModListManifest
  >
  get manifest => $value.manifest.copyWith.$chain((v) => call(manifest: v));
  @override
  $R call({
    String? contentHash,
    EnabledModListManifest? manifest,
    DateTime? syncedAt,
  }) => $apply(
    FieldCopyWithData({
      if (contentHash != null) #contentHash: contentHash,
      if (manifest != null) #manifest: manifest,
      if (syncedAt != null) #syncedAt: syncedAt,
    }),
  );
  @override
  EnabledModListRecord $make(CopyWithData data) => EnabledModListRecord(
    contentHash: data.get(#contentHash, or: $value.contentHash),
    manifest: data.get(#manifest, or: $value.manifest),
    syncedAt: data.get(#syncedAt, or: $value.syncedAt),
  );

  @override
  EnabledModListRecordCopyWith<$R2, EnabledModListRecord, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _EnabledModListRecordCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

