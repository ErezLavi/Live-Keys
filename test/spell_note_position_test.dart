import 'package:flutter_test/flutter_test.dart';
import 'package:piano/piano.dart';
import 'package:piano_app/common/constants.dart';
import 'package:piano_app/common/piano_utils.dart';

void main() {
  const utils = PianoUtils();

  // All sharp-spelled positions the piano actually renders (A0 .. C8).
  final range = NoteRange(
    from: NotePosition(note: Note.A, octave: 0),
    to: NotePosition(note: Note.C, octave: 8),
  );

  test('spellNotePosition never changes the pitch, for every key', () {
    for (final source in range.allPositions) {
      for (final sig in Constants.keySignatureReferences) {
        final spelled = utils.spellNotePosition(source, keySignature: sig);
        expect(
          spelled.pitch,
          source.pitch,
          reason: 'pitch changed for ${source.name} in ${sig.majorKey} '
              '-> got ${spelled.name}',
        );
      }
    }
  });

  test('spells the expected accidental letter in known keys', () {
    NotePosition sharp(Note n, int octave) =>
        NotePosition(note: n, octave: octave, accidental: Accidental.Sharp);

    String spell(NotePosition p, String key) {
      final sig =
          Constants.keySignatureReferences.firstWhere((s) => s.majorKey == key);
      final r = utils.spellNotePosition(p, keySignature: sig);
      return '${r.note.name}${r.accidental.symbol}';
    }

    // The black key between F and G.
    expect(spell(sharp(Note.F, 4), 'G major'), 'F♯');
    expect(spell(sharp(Note.F, 4), 'D major'), 'F♯');
    // The black key between C and D -> sharp in sharp keys, flat in flat keys.
    expect(spell(sharp(Note.C, 4), 'D major'), 'C♯');
    expect(spell(sharp(Note.C, 4), 'F major'), 'D♭');
    // White keys stay natural in ordinary keys.
    expect(spell(NotePosition(note: Note.B, octave: 4), 'G major'), 'B');
  });
}
