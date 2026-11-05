import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trios/save_sync/save_credits_reader.dart';
import 'package:trios/save_sync/save_sync_engine.dart';
import 'package:trios/thirdparty/dartx/string.dart';
import 'package:trios/trios/constants.dart';
import 'package:trios/trios/constants_theme.dart';
import 'package:trios/utils/extensions.dart';
import 'package:trios/utils/relative_timestamp.dart';
import 'package:trios/widgets/ingame_tooltip_shared.dart';

/// Popup shown when hovering a save in the Save Sync list. Shows this PC's
/// copy and the sync folder's copy side by side in one list.
class SaveDetailsTooltip extends ConsumerWidget {
  const SaveDetailsTooltip({super.key, required this.item});

  final SaveSyncItem item;

  static const _width = 440.0;
  static const _valueColumnWidth = 300.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final local = item.localSave;
    final localCredits = local == null
        ? null
        : ref.watch(
            saveCreditsProvider(
              SaveCreditsKey(local.folder.path, local.saveDate),
            ),
          );
    final manifest = item.remoteManifest;
    // When both copies are the same, the sync folder section only adds who
    // wrote it and when.
    final sameAsLocal = item.status == SaveSyncItemStatus.upToDate;

    return ConstrainedBox(
      constraints: const BoxConstraints.tightFor(width: _width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          tooltipTitle(
            item.characterName.isEmpty
                ? item.saveFolderName
                : item.characterName,
            theme,
          ),
          if (local != null) ...[
            tooltipSectionHeader('THIS PC', theme, theme.colorScheme.primary),
            tooltipStatsGrid(theme, valueColumnWidth: _valueColumnWidth, [
              ..._saveEntries(
                saveDate: local.saveDate,
                gameTimestamp: local.gameTimestamp,
                characterLevel: local.characterLevel,
                credits: switch (localCredits) {
                  AsyncData(:final value) => value?.asCredits(),
                  AsyncError() => null,
                  _ => 'Reading...',
                },
                gameVersion: local.gameVersion,
                difficulty: local.difficulty,
                isIronMode: local.isIronMode,
                modCount: local.mods.length,
              ),
            ]),
          ],
          if (manifest != null) ...[
            tooltipSectionHeader(
              'SYNC FOLDER',
              theme,
              theme.colorScheme.secondary,
            ),
            tooltipStatsGrid(theme, valueColumnWidth: _valueColumnWidth, [
              if (!sameAsLocal)
                ..._saveEntries(
                  saveDate: manifest.saveDate,
                  gameTimestamp: manifest.gameTimestamp,
                  characterLevel: manifest.characterLevel,
                  credits: manifest.credits?.asCredits(),
                  gameVersion: manifest.gameVersion,
                  difficulty: manifest.difficulty,
                  isIronMode: manifest.isIronMode,
                  modCount: manifest.mods.length,
                ),
              TooltipStatEntry(
                label: 'Written by',
                value: '${manifest.machineName} (${manifest.os})',
              ),
              TooltipStatEntry(
                label: 'Written',
                value: _dateText(manifest.syncedAt),
              ),
              TooltipStatEntry(
                label: 'Zip size',
                value: manifest.archiveSizeBytes.bytesAsReadable(),
              ),
            ]),
          ],
          if (local == null && manifest == null)
            Text('No details available.', style: theme.textTheme.bodySmall),
          Text(item.saveFolderName, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }

  List<TooltipStatEntry> _saveEntries({
    required DateTime? saveDate,
    required int? gameTimestamp,
    required int? characterLevel,
    required String? credits,
    required String? gameVersion,
    required String? difficulty,
    required bool? isIronMode,
    required int modCount,
  }) => [
    if (saveDate != null)
      TooltipStatEntry(label: 'Saved', value: _dateText(saveDate)),
    if (gameTimestamp != null && gameTimestamp != 0)
      TooltipStatEntry(
        label: 'In-game date',
        value: Constants.gameDateFormat.format(
          DateTime.fromMillisecondsSinceEpoch(gameTimestamp),
        ),
      ),
    if (characterLevel != null && characterLevel > 0)
      TooltipStatEntry(label: 'Level', value: '$characterLevel'),
    if (credits != null) TooltipStatEntry(label: 'Credits', value: credits),
    if (gameVersion.isNotNullOrBlank)
      TooltipStatEntry(label: 'Game version', value: gameVersion!),
    if (difficulty.isNotNullOrBlank)
      TooltipStatEntry(label: 'Difficulty', value: difficulty!.toTitleCase()),
    if (isIronMode == true)
      TooltipStatEntry(
        label: 'Iron mode',
        value: 'Yes',
        valueColor: TriOSThemeConstants.vanillaErrorColor,
      ),
    TooltipStatEntry(label: 'Mods enabled', value: '$modCount'),
  ];

  String _dateText(DateTime date) {
    final local = date.toLocal();
    return '${Constants.dateTimeFormat.format(local)} '
        '(${local.relativeTimestamp()})';
  }
}
