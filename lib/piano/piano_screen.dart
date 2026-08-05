import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:piano_app/common/app_sizes.dart';
import 'package:piano_app/custom_piano/custom_interactive_piano.dart';
import 'package:piano_app/domain/key_signature_reference.dart';
import 'package:piano_app/piano/piano_screen_controller.dart';
import 'package:piano_app/piano/widgets/grand_stuff_viewer_widget.dart';
import 'package:piano_app/piano/widgets/chord_viewer.dart';
import 'package:piano_app/piano/widgets/octave_buttons_widget.dart';
import 'package:piano_app/menu/key_signature_grid.dart';
import 'package:piano_app/menu/top_bar.dart';

class PianoPage extends StatefulWidget {
  const PianoPage({super.key, required this.controller});

  final PianoPageController controller;

  @override
  State<PianoPage> createState() => _PianoPageState();
}

//TODO: fix #/b with regular on same note display
class _PianoPageState extends State<PianoPage> {
  late final PianoPageController _controller;
  bool get _showOctaveControls =>
      defaultTargetPlatform != TargetPlatform.android ||
      _controller.connectedDeviceNames.isNotEmpty;

  Future<void> _showKeySignaturePicker() async {
    final selected = await showModalBottomSheet<KeySignatureReference>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: _controller.keySignatureReferences.map((signature) {
              final isSelected = signature == _controller.selectedKeySignature;
              return ListTile(
                title: Text(signature.label),
                subtitle: Text(signature.accidentalsLabel),
                trailing: isSelected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(signature),
              );
            }).toList(),
          ),
        );
      },
    );

    if (selected != null) {
      _controller.setSelectedKeySignature(selected);
    }
  }

  void _onControllerUpdated() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.loadSoundFont();
    _controller.startHardwareMidiListening();
    _controller.addListener(_onControllerUpdated);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdated);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final keyWidth = AppSizes.keyWidth(screenSize.width);
    final horizontalPadding = AppSizes.overlayHorizontalPadding(
      screenSize.width,
    );
    final verticalPadding = AppSizes.overlayVerticalPadding(screenSize.height);
    return Scaffold(
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: AppSizes.space16,
                    horizontal: AppSizes.space12,
                  ),
                  child: Row(
                    children: [
                      GrandStaffViewerWidget(
                        pressedNotes: _controller.pressedNotes,
                        keySignature: _controller.selectedKeySignature,
                      ),
                      Expanded(
                        child: ChordViewer(
                          chord: _controller.currentChord,
                          splitChordName: _controller.splitChordName,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: KeyboardListener(
                  focusNode: _controller.focusNode,
                  autofocus: true,
                  onKeyEvent: _controller.handleKeyboardKey,
                  child: CustomInteractivePiano(
                    highlightedNotes: _controller.pressedNotes,
                    chordHighlightedNotes: _controller.combinedHighlightedNotes,
                    naturalColor: Colors.white,
                    accidentalColor: Colors.black,
                    keyWidth: keyWidth,
                    noteRange: _controller.noteRange,
                    keySignature: _controller.selectedKeySignature,
                    onNotePositionTapped: _controller.pressNote,
                    onNotePositionReleased: _controller.releaseNote,
                  ),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = AppSizes.isCompactLayout(constraints);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_showOctaveControls) ...[
                          OctaveButtonsWidget(
                            isCompact: isCompact,
                            keyboardOctave: _controller.keyboardOctave,
                            onIncrement: _controller.incrementOctave,
                            onDecrement: _controller.decrementOctave,
                          ),
                          isCompact
                              ? AppSizes.space12.sbWidth
                              : AppSizes.space36.sbWidth,
                        ],
                        if (isCompact)
                          IconButton(
                            tooltip: _controller.selectedKeySignature.label,
                            onPressed: _showKeySignaturePicker,
                            icon: const Icon(Icons.music_note_outlined),
                          )
                        else
                          MenuAnchor(
                            alignmentOffset: const Offset(0, 8),
                            builder: (context, menuController, _) {
                              void toggleMenu() {
                                if (menuController.isOpen) {
                                  menuController.close();
                                } else {
                                  menuController.open();
                                }
                              }

                              return Material(
                                elevation: 6,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusM,
                                ),
                                child: SizedBox(
                                  width: 180,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.radiusM,
                                    ),
                                    onTap: toggleMenu,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSizes.space12,
                                        vertical: AppSizes.space8,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _controller
                                                  .selectedKeySignature
                                                  .label,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          AppSizes.space8.sbWidth,
                                          const Icon(Icons.arrow_drop_down),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            menuChildren: [
                              KeySignatureGrid(
                                keySignatures:
                                    _controller.keySignatureReferences,
                                selectedKeySignature:
                                    _controller.selectedKeySignature,
                                onSelected: (signature) {
                                  _controller.setSelectedKeySignature(
                                    signature,
                                  );
                                },
                              ),
                            ],
                          ),
                        isCompact
                            ? AppSizes.space12.sbWidth
                            : AppSizes.space36.sbWidth,
                        TopMenuBar(
                          controller: _controller,
                          isCompact: isCompact,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
