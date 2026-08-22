import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:piano_app/common/app_sizes.dart';
import 'package:piano_app/menu/adaptive_menu.dart';
import 'package:piano_app/menu/chords_grid.dart';
import 'package:piano_app/menu/scales_grid.dart';
import 'package:piano_app/piano/piano_screen_controller.dart';

class TopMenuBar extends StatelessWidget {
  final PianoScreenController controller;
  final bool isCompact;

  const TopMenuBar({
    super.key,
    required this.controller,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = isCompact ? AppSizes.space20 : AppSizes.space32;
    final iconPadding = EdgeInsets.all(
      isCompact ? AppSizes.space2 : AppSizes.space8,
    );

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.space4),
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: isCompact ? 1 : AppSizes.space4,
          runSpacing: isCompact ? 1 : AppSizes.space4,
          children: [
            AdaptiveMenu(
              isCompact: isCompact,
              trigger: (context, open) => isCompact
                  ? IconButton(
                      icon: const Icon(Icons.piano),
                      tooltip: 'Chords',
                      iconSize: iconSize,
                      padding: iconPadding,
                      onPressed: open,
                    )
                  : TextButton.icon(
                      onPressed: open,
                      icon: Icon(Icons.piano, size: iconSize),
                      label: const Text('Chords'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
              content: ChordsGrid(
                onChordSelected: controller.onChordSelected,
                onChordCleared: controller.clearSelectedChord,
                initialRootPc: controller.selectedChord.rootPc ?? 0,
                initialChordType: controller.selectedChord.type,
                initialInversion: controller.selectedChord.inversion,
                keySignature: controller.selectedKeySignature,
                useFlats: controller.useFlats,
              ),
            ),
            AdaptiveMenu(
              isCompact: isCompact,
              trigger: (context, open) => isCompact
                  ? IconButton(
                      onPressed: open,
                      icon: const Icon(Icons.music_note),
                      tooltip: 'Scales',
                      iconSize: iconSize,
                      padding: iconPadding,
                    )
                  : TextButton.icon(
                      onPressed: open,
                      icon: Icon(Icons.music_note, size: iconSize),
                      label: const Text('Scales'),
                      style: TextButton.styleFrom(
                        foregroundColor: IconTheme.of(context).color,
                      ),
                    ),
              content: ScalesGrid(
                onScaleSelected: controller.onScaleSelected,
                onScaleCleared: controller.clearSelectedScale,
                initialRootPc: controller.selectedScale.rootPc ?? 0,
                initialScaleType: controller.selectedScale.type,
                keySignature: controller.selectedKeySignature,
                useFlats: controller.useFlats,
              ),
            ),
            MenuAnchor(
              builder: (context, controller, _) {
                return IconButton(
                  icon: const Icon(Icons.devices),
                  tooltip: 'MIDI Devices',
                  iconSize: iconSize,
                  padding: iconPadding,
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                );
              },
              menuChildren: [
                if (controller.connectedDeviceNames.isEmpty)
                  const MenuItemButton(
                    onPressed: null,
                    child: Text('No MIDI device connected'),
                  )
                else
                  for (final device in controller.connectedDeviceNames)
                    MenuItemButton(onPressed: () {}, child: Text(device)),
              ],
            ),
            MenuAnchor(
              builder: (context, controller, _) {
                return IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
                  iconSize: iconSize,
                  padding: iconPadding,
                  onPressed: controller.open,
                );
              },
              menuChildren: [
                MenuAnchor(
                  builder: (context, controller, _) {
                    return MenuItemButton(
                      closeOnActivate: false,
                      onPressed: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chevron_left, size: 18),
                          AppSizes.space6.sbWidth,
                          const Text('Choose Sound'),
                        ],
                      ),
                    );
                  },
                  menuChildren: [
                    for (final soundFont in controller.availableSoundFonts)
                      MenuItemButton(
                        onPressed: () => controller.setSoundFont(soundFont),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              soundFont.assetPath ==controller.selectedSoundFont.assetPath ? Icons.check : null,
                              size: 18,
                            ),
                            AppSizes.space8.sbWidth,
                            Text(soundFont.name),
                          ],
                        ),
                      ),
                    const Divider(),
                    MenuItemButton(
                      closeOnActivate: false,
                      onPressed: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['sf2'],
                          );
                          final path = result?.files.single.path;
                          if (path == null || path.isEmpty) return;
                          await controller.importSoundFontFile(path);
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to import SF2: $error'),
                            ),
                          );
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.upload_file, size: 18),
                          AppSizes.space8.sbWidth,
                          const Text('Import SF2...'),
                        ],
                      ),
                    ),
                  ],
                ),
                MenuItemButton(
                  closeOnActivate: false,
                  onPressed: controller.toggleMuted,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        controller.isMuted ? Icons.volume_off : Icons.volume_up,
                        size: 18,
                      ),
                      AppSizes.space8.sbWidth,
                      Text(controller.isMuted ? 'Unmute' : 'Mute'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
