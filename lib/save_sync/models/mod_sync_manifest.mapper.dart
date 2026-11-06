// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'mod_sync_manifest.dart';

class ModSyncManifestMapper extends ClassMapperBase<ModSyncManifest> {
  ModSyncManifestMapper._();

  static ModSyncManifestMapper? _instance;
  static ModSyncManifestMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ModSyncManifestMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ModSyncManifest';

  static int _$layoutVersion(ModSyncManifest v) => v.layoutVersion;
  static const Field<ModSyncManifest, int> _f$layoutVersion = Field(
    'layoutVersion',
    _$layoutVersion,
    opt: true,
    def: saveSyncLayoutVersion,
  );
  static String _$folderName(ModSyncManifest v) => v.folderName;
  static const Field<ModSyncManifest, String> _f$folderName = Field(
    'folderName',
    _$folderName,
  );
  static String? _$modId(ModSyncManifest v) => v.modId;
  static const Field<ModSyncManifest, String> _f$modId = Field(
    'modId',
    _$modId,
    opt: true,
  );
  static String? _$modName(ModSyncManifest v) => v.modName;
  static const Field<ModSyncManifest, String> _f$modName = Field(
    'modName',
    _$modName,
    opt: true,
  );
  static String? _$modVersion(ModSyncManifest v) => v.modVersion;
  static const Field<ModSyncManifest, String> _f$modVersion = Field(
    'modVersion',
    _$modVersion,
    opt: true,
  );
  static String _$contentHash(ModSyncManifest v) => v.contentHash;
  static const Field<ModSyncManifest, String> _f$contentHash = Field(
    'contentHash',
    _$contentHash,
  );
  static String _$archiveHash(ModSyncManifest v) => v.archiveHash;
  static const Field<ModSyncManifest, String> _f$archiveHash = Field(
    'archiveHash',
    _$archiveHash,
  );
  static int _$archiveSizeBytes(ModSyncManifest v) => v.archiveSizeBytes;
  static const Field<ModSyncManifest, int> _f$archiveSizeBytes = Field(
    'archiveSizeBytes',
    _$archiveSizeBytes,
  );
  static DateTime _$syncedAt(ModSyncManifest v) => v.syncedAt;
  static const Field<ModSyncManifest, DateTime> _f$syncedAt = Field(
    'syncedAt',
    _$syncedAt,
  );
  static String _$machineId(ModSyncManifest v) => v.machineId;
  static const Field<ModSyncManifest, String> _f$machineId = Field(
    'machineId',
    _$machineId,
  );
  static String _$machineName(ModSyncManifest v) => v.machineName;
  static const Field<ModSyncManifest, String> _f$machineName = Field(
    'machineName',
    _$machineName,
  );
  static String _$os(ModSyncManifest v) => v.os;
  static const Field<ModSyncManifest, String> _f$os = Field('os', _$os);
  static String? _$triosVersion(ModSyncManifest v) => v.triosVersion;
  static const Field<ModSyncManifest, String> _f$triosVersion = Field(
    'triosVersion',
    _$triosVersion,
    opt: true,
  );

  @override
  final MappableFields<ModSyncManifest> fields = const {
    #layoutVersion: _f$layoutVersion,
    #folderName: _f$folderName,
    #modId: _f$modId,
    #modName: _f$modName,
    #modVersion: _f$modVersion,
    #contentHash: _f$contentHash,
    #archiveHash: _f$archiveHash,
    #archiveSizeBytes: _f$archiveSizeBytes,
    #syncedAt: _f$syncedAt,
    #machineId: _f$machineId,
    #machineName: _f$machineName,
    #os: _f$os,
    #triosVersion: _f$triosVersion,
  };

  static ModSyncManifest _instantiate(DecodingData data) {
    return ModSyncManifest(
      layoutVersion: data.dec(_f$layoutVersion),
      folderName: data.dec(_f$folderName),
      modId: data.dec(_f$modId),
      modName: data.dec(_f$modName),
      modVersion: data.dec(_f$modVersion),
      contentHash: data.dec(_f$contentHash),
      archiveHash: data.dec(_f$archiveHash),
      archiveSizeBytes: data.dec(_f$archiveSizeBytes),
      syncedAt: data.dec(_f$syncedAt),
      machineId: data.dec(_f$machineId),
      machineName: data.dec(_f$machineName),
      os: data.dec(_f$os),
      triosVersion: data.dec(_f$triosVersion),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ModSyncManifest fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ModSyncManifest>(map);
  }

  static ModSyncManifest fromJson(String json) {
    return ensureInitialized().decodeJson<ModSyncManifest>(json);
  }
}

mixin ModSyncManifestMappable {
  String toJson() {
    return ModSyncManifestMapper.ensureInitialized()
        .encodeJson<ModSyncManifest>(this as ModSyncManifest);
  }

  Map<String, dynamic> toMap() {
    return ModSyncManifestMapper.ensureInitialized().encodeMap<ModSyncManifest>(
      this as ModSyncManifest,
    );
  }

  ModSyncManifestCopyWith<ModSyncManifest, ModSyncManifest, ModSyncManifest>
  get copyWith =>
      _ModSyncManifestCopyWithImpl<ModSyncManifest, ModSyncManifest>(
        this as ModSyncManifest,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ModSyncManifestMapper.ensureInitialized().stringifyValue(
      this as ModSyncManifest,
    );
  }

  @override
  bool operator ==(Object other) {
    return ModSyncManifestMapper.ensureInitialized().equalsValue(
      this as ModSyncManifest,
      other,
    );
  }

  @override
  int get hashCode {
    return ModSyncManifestMapper.ensureInitialized().hashValue(
      this as ModSyncManifest,
    );
  }
}

extension ModSyncManifestValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ModSyncManifest, $Out> {
  ModSyncManifestCopyWith<$R, ModSyncManifest, $Out> get $asModSyncManifest =>
      $base.as((v, t, t2) => _ModSyncManifestCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ModSyncManifestCopyWith<$R, $In extends ModSyncManifest, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    int? layoutVersion,
    String? folderName,
    String? modId,
    String? modName,
    String? modVersion,
    String? contentHash,
    String? archiveHash,
    int? archiveSizeBytes,
    DateTime? syncedAt,
    String? machineId,
    String? machineName,
    String? os,
    String? triosVersion,
  });
  ModSyncManifestCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _ModSyncManifestCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ModSyncManifest, $Out>
    implements ModSyncManifestCopyWith<$R, ModSyncManifest, $Out> {
  _ModSyncManifestCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ModSyncManifest> $mapper =
      ModSyncManifestMapper.ensureInitialized();
  @override
  $R call({
    int? layoutVersion,
    String? folderName,
    Object? modId = $none,
    Object? modName = $none,
    Object? modVersion = $none,
    String? contentHash,
    String? archiveHash,
    int? archiveSizeBytes,
    DateTime? syncedAt,
    String? machineId,
    String? machineName,
    String? os,
    Object? triosVersion = $none,
  }) => $apply(
    FieldCopyWithData({
      if (layoutVersion != null) #layoutVersion: layoutVersion,
      if (folderName != null) #folderName: folderName,
      if (modId != $none) #modId: modId,
      if (modName != $none) #modName: modName,
      if (modVersion != $none) #modVersion: modVersion,
      if (contentHash != null) #contentHash: contentHash,
      if (archiveHash != null) #archiveHash: archiveHash,
      if (archiveSizeBytes != null) #archiveSizeBytes: archiveSizeBytes,
      if (syncedAt != null) #syncedAt: syncedAt,
      if (machineId != null) #machineId: machineId,
      if (machineName != null) #machineName: machineName,
      if (os != null) #os: os,
      if (triosVersion != $none) #triosVersion: triosVersion,
    }),
  );
  @override
  ModSyncManifest $make(CopyWithData data) => ModSyncManifest(
    layoutVersion: data.get(#layoutVersion, or: $value.layoutVersion),
    folderName: data.get(#folderName, or: $value.folderName),
    modId: data.get(#modId, or: $value.modId),
    modName: data.get(#modName, or: $value.modName),
    modVersion: data.get(#modVersion, or: $value.modVersion),
    contentHash: data.get(#contentHash, or: $value.contentHash),
    archiveHash: data.get(#archiveHash, or: $value.archiveHash),
    archiveSizeBytes: data.get(#archiveSizeBytes, or: $value.archiveSizeBytes),
    syncedAt: data.get(#syncedAt, or: $value.syncedAt),
    machineId: data.get(#machineId, or: $value.machineId),
    machineName: data.get(#machineName, or: $value.machineName),
    os: data.get(#os, or: $value.os),
    triosVersion: data.get(#triosVersion, or: $value.triosVersion),
  );

  @override
  ModSyncManifestCopyWith<$R2, ModSyncManifest, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ModSyncManifestCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class EnabledModListManifestMapper
    extends ClassMapperBase<EnabledModListManifest> {
  EnabledModListManifestMapper._();

  static EnabledModListManifestMapper? _instance;
  static EnabledModListManifestMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = EnabledModListManifestMapper._());
      ShallowModVariantMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'EnabledModListManifest';

  static int _$layoutVersion(EnabledModListManifest v) => v.layoutVersion;
  static const Field<EnabledModListManifest, int> _f$layoutVersion = Field(
    'layoutVersion',
    _$layoutVersion,
    opt: true,
    def: saveSyncLayoutVersion,
  );
  static String _$contentHash(EnabledModListManifest v) => v.contentHash;
  static const Field<EnabledModListManifest, String> _f$contentHash = Field(
    'contentHash',
    _$contentHash,
  );
  static List<ShallowModVariant> _$mods(EnabledModListManifest v) => v.mods;
  static const Field<EnabledModListManifest, List<ShallowModVariant>> _f$mods =
      Field('mods', _$mods);
  static DateTime _$syncedAt(EnabledModListManifest v) => v.syncedAt;
  static const Field<EnabledModListManifest, DateTime> _f$syncedAt = Field(
    'syncedAt',
    _$syncedAt,
  );
  static String _$machineId(EnabledModListManifest v) => v.machineId;
  static const Field<EnabledModListManifest, String> _f$machineId = Field(
    'machineId',
    _$machineId,
  );
  static String _$machineName(EnabledModListManifest v) => v.machineName;
  static const Field<EnabledModListManifest, String> _f$machineName = Field(
    'machineName',
    _$machineName,
  );
  static String _$os(EnabledModListManifest v) => v.os;
  static const Field<EnabledModListManifest, String> _f$os = Field('os', _$os);
  static String? _$triosVersion(EnabledModListManifest v) => v.triosVersion;
  static const Field<EnabledModListManifest, String> _f$triosVersion = Field(
    'triosVersion',
    _$triosVersion,
    opt: true,
  );

  @override
  final MappableFields<EnabledModListManifest> fields = const {
    #layoutVersion: _f$layoutVersion,
    #contentHash: _f$contentHash,
    #mods: _f$mods,
    #syncedAt: _f$syncedAt,
    #machineId: _f$machineId,
    #machineName: _f$machineName,
    #os: _f$os,
    #triosVersion: _f$triosVersion,
  };

  static EnabledModListManifest _instantiate(DecodingData data) {
    return EnabledModListManifest(
      layoutVersion: data.dec(_f$layoutVersion),
      contentHash: data.dec(_f$contentHash),
      mods: data.dec(_f$mods),
      syncedAt: data.dec(_f$syncedAt),
      machineId: data.dec(_f$machineId),
      machineName: data.dec(_f$machineName),
      os: data.dec(_f$os),
      triosVersion: data.dec(_f$triosVersion),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static EnabledModListManifest fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<EnabledModListManifest>(map);
  }

  static EnabledModListManifest fromJson(String json) {
    return ensureInitialized().decodeJson<EnabledModListManifest>(json);
  }
}

mixin EnabledModListManifestMappable {
  String toJson() {
    return EnabledModListManifestMapper.ensureInitialized()
        .encodeJson<EnabledModListManifest>(this as EnabledModListManifest);
  }

  Map<String, dynamic> toMap() {
    return EnabledModListManifestMapper.ensureInitialized()
        .encodeMap<EnabledModListManifest>(this as EnabledModListManifest);
  }

  EnabledModListManifestCopyWith<
    EnabledModListManifest,
    EnabledModListManifest,
    EnabledModListManifest
  >
  get copyWith =>
      _EnabledModListManifestCopyWithImpl<
        EnabledModListManifest,
        EnabledModListManifest
      >(this as EnabledModListManifest, $identity, $identity);
  @override
  String toString() {
    return EnabledModListManifestMapper.ensureInitialized().stringifyValue(
      this as EnabledModListManifest,
    );
  }

  @override
  bool operator ==(Object other) {
    return EnabledModListManifestMapper.ensureInitialized().equalsValue(
      this as EnabledModListManifest,
      other,
    );
  }

  @override
  int get hashCode {
    return EnabledModListManifestMapper.ensureInitialized().hashValue(
      this as EnabledModListManifest,
    );
  }
}

extension EnabledModListManifestValueCopy<$R, $Out>
    on ObjectCopyWith<$R, EnabledModListManifest, $Out> {
  EnabledModListManifestCopyWith<$R, EnabledModListManifest, $Out>
  get $asEnabledModListManifest => $base.as(
    (v, t, t2) => _EnabledModListManifestCopyWithImpl<$R, $Out>(v, t, t2),
  );
}

abstract class EnabledModListManifestCopyWith<
  $R,
  $In extends EnabledModListManifest,
  $Out
>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    ShallowModVariant,
    ShallowModVariantCopyWith<$R, ShallowModVariant, ShallowModVariant>
  >
  get mods;
  $R call({
    int? layoutVersion,
    String? contentHash,
    List<ShallowModVariant>? mods,
    DateTime? syncedAt,
    String? machineId,
    String? machineName,
    String? os,
    String? triosVersion,
  });
  EnabledModListManifestCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _EnabledModListManifestCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, EnabledModListManifest, $Out>
    implements
        EnabledModListManifestCopyWith<$R, EnabledModListManifest, $Out> {
  _EnabledModListManifestCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<EnabledModListManifest> $mapper =
      EnabledModListManifestMapper.ensureInitialized();
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
    String? contentHash,
    List<ShallowModVariant>? mods,
    DateTime? syncedAt,
    String? machineId,
    String? machineName,
    String? os,
    Object? triosVersion = $none,
  }) => $apply(
    FieldCopyWithData({
      if (layoutVersion != null) #layoutVersion: layoutVersion,
      if (contentHash != null) #contentHash: contentHash,
      if (mods != null) #mods: mods,
      if (syncedAt != null) #syncedAt: syncedAt,
      if (machineId != null) #machineId: machineId,
      if (machineName != null) #machineName: machineName,
      if (os != null) #os: os,
      if (triosVersion != $none) #triosVersion: triosVersion,
    }),
  );
  @override
  EnabledModListManifest $make(CopyWithData data) => EnabledModListManifest(
    layoutVersion: data.get(#layoutVersion, or: $value.layoutVersion),
    contentHash: data.get(#contentHash, or: $value.contentHash),
    mods: data.get(#mods, or: $value.mods),
    syncedAt: data.get(#syncedAt, or: $value.syncedAt),
    machineId: data.get(#machineId, or: $value.machineId),
    machineName: data.get(#machineName, or: $value.machineName),
    os: data.get(#os, or: $value.os),
    triosVersion: data.get(#triosVersion, or: $value.triosVersion),
  );

  @override
  EnabledModListManifestCopyWith<$R2, EnabledModListManifest, $Out2>
  $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _EnabledModListManifestCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

