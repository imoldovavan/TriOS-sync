// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'save_sync_manifest.dart';

class SaveSyncFolderInfoMapper extends ClassMapperBase<SaveSyncFolderInfo> {
  SaveSyncFolderInfoMapper._();

  static SaveSyncFolderInfoMapper? _instance;
  static SaveSyncFolderInfoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SaveSyncFolderInfoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SaveSyncFolderInfo';

  static int _$layoutVersion(SaveSyncFolderInfo v) => v.layoutVersion;
  static const Field<SaveSyncFolderInfo, int> _f$layoutVersion = Field(
    'layoutVersion',
    _$layoutVersion,
    opt: true,
    def: saveSyncLayoutVersion,
  );

  @override
  final MappableFields<SaveSyncFolderInfo> fields = const {
    #layoutVersion: _f$layoutVersion,
  };

  static SaveSyncFolderInfo _instantiate(DecodingData data) {
    return SaveSyncFolderInfo(layoutVersion: data.dec(_f$layoutVersion));
  }

  @override
  final Function instantiate = _instantiate;

  static SaveSyncFolderInfo fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SaveSyncFolderInfo>(map);
  }

  static SaveSyncFolderInfo fromJson(String json) {
    return ensureInitialized().decodeJson<SaveSyncFolderInfo>(json);
  }
}

mixin SaveSyncFolderInfoMappable {
  String toJson() {
    return SaveSyncFolderInfoMapper.ensureInitialized()
        .encodeJson<SaveSyncFolderInfo>(this as SaveSyncFolderInfo);
  }

  Map<String, dynamic> toMap() {
    return SaveSyncFolderInfoMapper.ensureInitialized()
        .encodeMap<SaveSyncFolderInfo>(this as SaveSyncFolderInfo);
  }

  SaveSyncFolderInfoCopyWith<
    SaveSyncFolderInfo,
    SaveSyncFolderInfo,
    SaveSyncFolderInfo
  >
  get copyWith =>
      _SaveSyncFolderInfoCopyWithImpl<SaveSyncFolderInfo, SaveSyncFolderInfo>(
        this as SaveSyncFolderInfo,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SaveSyncFolderInfoMapper.ensureInitialized().stringifyValue(
      this as SaveSyncFolderInfo,
    );
  }

  @override
  bool operator ==(Object other) {
    return SaveSyncFolderInfoMapper.ensureInitialized().equalsValue(
      this as SaveSyncFolderInfo,
      other,
    );
  }

  @override
  int get hashCode {
    return SaveSyncFolderInfoMapper.ensureInitialized().hashValue(
      this as SaveSyncFolderInfo,
    );
  }
}

extension SaveSyncFolderInfoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SaveSyncFolderInfo, $Out> {
  SaveSyncFolderInfoCopyWith<$R, SaveSyncFolderInfo, $Out>
  get $asSaveSyncFolderInfo => $base.as(
    (v, t, t2) => _SaveSyncFolderInfoCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class SaveSyncFolderInfoCopyWith<
  $R,
  $In extends SaveSyncFolderInfo,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? layoutVersion});
  SaveSyncFolderInfoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SaveSyncFolderInfoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SaveSyncFolderInfo, $Out>
    implements SaveSyncFolderInfoCopyWith<$R, SaveSyncFolderInfo, $Out> {
  _SaveSyncFolderInfoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SaveSyncFolderInfo> $mapper =
      SaveSyncFolderInfoMapper.ensureInitialized();
  @override
  $R call({int? layoutVersion}) => $apply(
    FieldCopyWithData({
      if (layoutVersion != null) #layoutVersion: layoutVersion,
    }),
  );
  @override
  SaveSyncFolderInfo $make(CopyWithData data) => SaveSyncFolderInfo(
    layoutVersion: data.get(#layoutVersion, or: $value.layoutVersion),
  );

  @override
  SaveSyncFolderInfoCopyWith<$R2, SaveSyncFolderInfo, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SaveSyncFolderInfoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class SaveSyncManifestMapper extends ClassMapperBase<SaveSyncManifest> {
  SaveSyncManifestMapper._();

  static SaveSyncManifestMapper? _instance;
  static SaveSyncManifestMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SaveSyncManifestMapper._());
      ShallowModVariantMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'SaveSyncManifest';

  static int _$layoutVersion(SaveSyncManifest v) => v.layoutVersion;
  static const Field<SaveSyncManifest, int> _f$layoutVersion = Field(
    'layoutVersion',
    _$layoutVersion,
    opt: true,
    def: saveSyncLayoutVersion,
  );
  static String _$saveFolderName(SaveSyncManifest v) => v.saveFolderName;
  static const Field<SaveSyncManifest, String> _f$saveFolderName = Field(
    'saveFolderName',
    _$saveFolderName,
  );
  static String _$characterName(SaveSyncManifest v) => v.characterName;
  static const Field<SaveSyncManifest, String> _f$characterName = Field(
    'characterName',
    _$characterName,
  );
  static int? _$characterLevel(SaveSyncManifest v) => v.characterLevel;
  static const Field<SaveSyncManifest, int> _f$characterLevel = Field(
    'characterLevel',
    _$characterLevel,
    opt: true,
  );
  static int? _$gameTimestamp(SaveSyncManifest v) => v.gameTimestamp;
  static const Field<SaveSyncManifest, int> _f$gameTimestamp = Field(
    'gameTimestamp',
    _$gameTimestamp,
    opt: true,
  );
  static String? _$difficulty(SaveSyncManifest v) => v.difficulty;
  static const Field<SaveSyncManifest, String> _f$difficulty = Field(
    'difficulty',
    _$difficulty,
    opt: true,
  );
  static bool? _$isIronMode(SaveSyncManifest v) => v.isIronMode;
  static const Field<SaveSyncManifest, bool> _f$isIronMode = Field(
    'isIronMode',
    _$isIronMode,
    opt: true,
  );
  static double? _$credits(SaveSyncManifest v) => v.credits;
  static const Field<SaveSyncManifest, double> _f$credits = Field(
    'credits',
    _$credits,
    opt: true,
  );
  static String _$contentHash(SaveSyncManifest v) => v.contentHash;
  static const Field<SaveSyncManifest, String> _f$contentHash = Field(
    'contentHash',
    _$contentHash,
  );
  static String _$archiveHash(SaveSyncManifest v) => v.archiveHash;
  static const Field<SaveSyncManifest, String> _f$archiveHash = Field(
    'archiveHash',
    _$archiveHash,
  );
  static int _$archiveSizeBytes(SaveSyncManifest v) => v.archiveSizeBytes;
  static const Field<SaveSyncManifest, int> _f$archiveSizeBytes = Field(
    'archiveSizeBytes',
    _$archiveSizeBytes,
  );
  static DateTime? _$saveDate(SaveSyncManifest v) => v.saveDate;
  static const Field<SaveSyncManifest, DateTime> _f$saveDate = Field(
    'saveDate',
    _$saveDate,
    opt: true,
  );
  static DateTime _$syncedAt(SaveSyncManifest v) => v.syncedAt;
  static const Field<SaveSyncManifest, DateTime> _f$syncedAt = Field(
    'syncedAt',
    _$syncedAt,
  );
  static String _$machineId(SaveSyncManifest v) => v.machineId;
  static const Field<SaveSyncManifest, String> _f$machineId = Field(
    'machineId',
    _$machineId,
  );
  static String _$machineName(SaveSyncManifest v) => v.machineName;
  static const Field<SaveSyncManifest, String> _f$machineName = Field(
    'machineName',
    _$machineName,
  );
  static String _$os(SaveSyncManifest v) => v.os;
  static const Field<SaveSyncManifest, String> _f$os = Field('os', _$os);
  static String? _$gameVersion(SaveSyncManifest v) => v.gameVersion;
  static const Field<SaveSyncManifest, String> _f$gameVersion = Field(
    'gameVersion',
    _$gameVersion,
    opt: true,
  );
  static String? _$triosVersion(SaveSyncManifest v) => v.triosVersion;
  static const Field<SaveSyncManifest, String> _f$triosVersion = Field(
    'triosVersion',
    _$triosVersion,
    opt: true,
  );
  static List<ShallowModVariant> _$mods(SaveSyncManifest v) => v.mods;
  static const Field<SaveSyncManifest, List<ShallowModVariant>> _f$mods = Field(
    'mods',
    _$mods,
    opt: true,
    def: const [],
  );

  @override
  final MappableFields<SaveSyncManifest> fields = const {
    #layoutVersion: _f$layoutVersion,
    #saveFolderName: _f$saveFolderName,
    #characterName: _f$characterName,
    #characterLevel: _f$characterLevel,
    #gameTimestamp: _f$gameTimestamp,
    #difficulty: _f$difficulty,
    #isIronMode: _f$isIronMode,
    #credits: _f$credits,
    #contentHash: _f$contentHash,
    #archiveHash: _f$archiveHash,
    #archiveSizeBytes: _f$archiveSizeBytes,
    #saveDate: _f$saveDate,
    #syncedAt: _f$syncedAt,
    #machineId: _f$machineId,
    #machineName: _f$machineName,
    #os: _f$os,
    #gameVersion: _f$gameVersion,
    #triosVersion: _f$triosVersion,
    #mods: _f$mods,
  };

  static SaveSyncManifest _instantiate(DecodingData data) {
    return SaveSyncManifest(
      layoutVersion: data.dec(_f$layoutVersion),
      saveFolderName: data.dec(_f$saveFolderName),
      characterName: data.dec(_f$characterName),
      characterLevel: data.dec(_f$characterLevel),
      gameTimestamp: data.dec(_f$gameTimestamp),
      difficulty: data.dec(_f$difficulty),
      isIronMode: data.dec(_f$isIronMode),
      credits: data.dec(_f$credits),
      contentHash: data.dec(_f$contentHash),
      archiveHash: data.dec(_f$archiveHash),
      archiveSizeBytes: data.dec(_f$archiveSizeBytes),
      saveDate: data.dec(_f$saveDate),
      syncedAt: data.dec(_f$syncedAt),
      machineId: data.dec(_f$machineId),
      machineName: data.dec(_f$machineName),
      os: data.dec(_f$os),
      gameVersion: data.dec(_f$gameVersion),
      triosVersion: data.dec(_f$triosVersion),
      mods: data.dec(_f$mods),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SaveSyncManifest fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SaveSyncManifest>(map);
  }

  static SaveSyncManifest fromJson(String json) {
    return ensureInitialized().decodeJson<SaveSyncManifest>(json);
  }
}

mixin SaveSyncManifestMappable {
  String toJson() {
    return SaveSyncManifestMapper.ensureInitialized()
        .encodeJson<SaveSyncManifest>(this as SaveSyncManifest);
  }

  Map<String, dynamic> toMap() {
    return SaveSyncManifestMapper.ensureInitialized()
        .encodeMap<SaveSyncManifest>(this as SaveSyncManifest);
  }

  SaveSyncManifestCopyWith<SaveSyncManifest, SaveSyncManifest, SaveSyncManifest>
  get copyWith =>
      _SaveSyncManifestCopyWithImpl<SaveSyncManifest, SaveSyncManifest>(
        this as SaveSyncManifest,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return SaveSyncManifestMapper.ensureInitialized().stringifyValue(
      this as SaveSyncManifest,
    );
  }

  @override
  bool operator ==(Object other) {
    return SaveSyncManifestMapper.ensureInitialized().equalsValue(
      this as SaveSyncManifest,
      other,
    );
  }

  @override
  int get hashCode {
    return SaveSyncManifestMapper.ensureInitialized().hashValue(
      this as SaveSyncManifest,
    );
  }
}

extension SaveSyncManifestValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SaveSyncManifest, $Out> {
  SaveSyncManifestCopyWith<$R, SaveSyncManifest, $Out>
  get $asSaveSyncManifest =>
      $base.as((v, t, t2) => _SaveSyncManifestCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SaveSyncManifestCopyWith<$R, $In extends SaveSyncManifest, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    ShallowModVariant,
    ShallowModVariantCopyWith<$R, ShallowModVariant, ShallowModVariant>
  >
  get mods;
  $R call({
    int? layoutVersion,
    String? saveFolderName,
    String? characterName,
    int? characterLevel,
    int? gameTimestamp,
    String? difficulty,
    bool? isIronMode,
    double? credits,
    String? contentHash,
    String? archiveHash,
    int? archiveSizeBytes,
    DateTime? saveDate,
    DateTime? syncedAt,
    String? machineId,
    String? machineName,
    String? os,
    String? gameVersion,
    String? triosVersion,
    List<ShallowModVariant>? mods,
  });
  SaveSyncManifestCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SaveSyncManifestCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SaveSyncManifest, $Out>
    implements SaveSyncManifestCopyWith<$R, SaveSyncManifest, $Out> {
  _SaveSyncManifestCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SaveSyncManifest> $mapper =
      SaveSyncManifestMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    ShallowModVariant,
    ShallowModVariantCopyWith<$R, ShallowModVariant, ShallowModVariant>
  >
  get mods => ListCopyWith(
    $value.mods,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(mods: v),
  );
  @override
  $R call({
    int? layoutVersion,
    String? saveFolderName,
    String? characterName,
    Object? characterLevel = $none,
    Object? gameTimestamp = $none,
    Object? difficulty = $none,
    Object? isIronMode = $none,
    Object? credits = $none,
    String? contentHash,
    String? archiveHash,
    int? archiveSizeBytes,
    Object? saveDate = $none,
    DateTime? syncedAt,
    String? machineId,
    String? machineName,
    String? os,
    Object? gameVersion = $none,
    Object? triosVersion = $none,
    List<ShallowModVariant>? mods,
  }) => $apply(
    FieldCopyWithData({
      if (layoutVersion != null) #layoutVersion: layoutVersion,
      if (saveFolderName != null) #saveFolderName: saveFolderName,
      if (characterName != null) #characterName: characterName,
      if (characterLevel != $none) #characterLevel: characterLevel,
      if (gameTimestamp != $none) #gameTimestamp: gameTimestamp,
      if (difficulty != $none) #difficulty: difficulty,
      if (isIronMode != $none) #isIronMode: isIronMode,
      if (credits != $none) #credits: credits,
      if (contentHash != null) #contentHash: contentHash,
      if (archiveHash != null) #archiveHash: archiveHash,
      if (archiveSizeBytes != null) #archiveSizeBytes: archiveSizeBytes,
      if (saveDate != $none) #saveDate: saveDate,
      if (syncedAt != null) #syncedAt: syncedAt,
      if (machineId != null) #machineId: machineId,
      if (machineName != null) #machineName: machineName,
      if (os != null) #os: os,
      if (gameVersion != $none) #gameVersion: gameVersion,
      if (triosVersion != $none) #triosVersion: triosVersion,
      if (mods != null) #mods: mods,
    }),
  );
  @override
  SaveSyncManifest $make(CopyWithData data) => SaveSyncManifest(
    layoutVersion: data.get(#layoutVersion, or: $value.layoutVersion),
    saveFolderName: data.get(#saveFolderName, or: $value.saveFolderName),
    characterName: data.get(#characterName, or: $value.characterName),
    characterLevel: data.get(#characterLevel, or: $value.characterLevel),
    gameTimestamp: data.get(#gameTimestamp, or: $value.gameTimestamp),
    difficulty: data.get(#difficulty, or: $value.difficulty),
    isIronMode: data.get(#isIronMode, or: $value.isIronMode),
    credits: data.get(#credits, or: $value.credits),
    contentHash: data.get(#contentHash, or: $value.contentHash),
    archiveHash: data.get(#archiveHash, or: $value.archiveHash),
    archiveSizeBytes: data.get(#archiveSizeBytes, or: $value.archiveSizeBytes),
    saveDate: data.get(#saveDate, or: $value.saveDate),
    syncedAt: data.get(#syncedAt, or: $value.syncedAt),
    machineId: data.get(#machineId, or: $value.machineId),
    machineName: data.get(#machineName, or: $value.machineName),
    os: data.get(#os, or: $value.os),
    gameVersion: data.get(#gameVersion, or: $value.gameVersion),
    triosVersion: data.get(#triosVersion, or: $value.triosVersion),
    mods: data.get(#mods, or: $value.mods),
  );

  @override
  SaveSyncManifestCopyWith<$R2, SaveSyncManifest, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SaveSyncManifestCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

