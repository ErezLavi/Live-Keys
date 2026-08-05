// ignore_for_file: must_be_immutable

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:piano/piano.dart';
import 'package:piano_app/common/piano_utils.dart';
import 'package:piano_app/domain/key_signature_reference.dart';

class CustomClefPainter extends CustomPainter with EquatableMixin {
  final Clef clef;

  /// The note range we'll make space for in this drawing.
  final NoteRange noteRange;

  /// The note range we'll actually draw notes for.
  final NoteRange? noteRangeToClip;
  final List<NoteImage> noteImages;
  final EdgeInsets padding;
  final int lineHeight;
  final Color clefColor;
  final Color noteColor;
  final KeySignatureReference? keySignature;

  /// Satisfies `EquatableMixin` and used in shouldRepaint for redraw efficiency
  @override
  List<Object?> get props => [
        clef,
        noteRange,
        noteRangeToClip,
        noteImages,
        padding,
        lineHeight,
        clefColor,
        noteColor,
        keySignature,
      ];

  final Paint _linePaint;
  final Paint _notePaint;
  final Paint _tailPaint;

  TextPainter? _clefSymbolPainter;
  final Map<Accidental, TextPainter> _accidentalSymbolPainters = {};
  Size? _lastClefSize;
  final List<NotePosition> _naturalPositions;

  CustomClefPainter({
    required this.clef,
    required this.noteRange,
    this.noteRangeToClip,
    this.noteImages = const [],
    this.padding = const EdgeInsets.all(16),
    this.clefColor = Colors.black,
    this.noteColor = Colors.black,
    this.lineHeight = 1,
    this.keySignature,
  })  : _naturalPositions = noteRange.naturalPositions,
        _linePaint = Paint()
          ..color = clefColor
          ..strokeWidth = lineHeight.toDouble(),
        _notePaint = Paint(),
        _tailPaint = Paint()..strokeWidth = lineHeight.toDouble();

  String _accidentalGlyph(Accidental accidental) {
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (!isAndroid) {
      return accidental.symbol;
    }
    switch (accidental) {
      case Accidental.Flat:
        return 'b';
      case Accidental.Sharp:
        return '#';
      default:
        return accidental.symbol;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = padding.deflateRect(Offset.zero & size);

    if (bounds.height <= 0) {
      return;
    }

    naturalPositionOf(NotePosition notePosition) =>
        (noteRangeToClip?.contains(notePosition) == false)
            ? -1
            : _naturalPositions.indexWhere((position) =>
                position.note == notePosition.note &&
                position.octave == notePosition.octave);

    final clefSize = Size(80, bounds.height);

    final noteHeight = bounds.height / _naturalPositions.length.toDouble();

    final firstLineIndex =
        _naturalPositions.indexOf(clef.firstLineNotePosition);
    final lastLineIndex = _naturalPositions.indexOf(clef.lastLineNotePosition);

    final firstLineIsEven = firstLineIndex % 2 == 0;

    final ovalHeight = noteHeight * 2;
    final ovalWidth = ovalHeight * 1.5;

    double? firstLineY, lastLineY;

    for (var line = firstLineIsEven ? 0 : 1;
        line < _naturalPositions.length;
        line += 2) {
      NoteImage? ledgerLineImage;
      if (line < firstLineIndex || line > lastLineIndex) {
        ledgerLineImage = line < firstLineIndex
            ? noteImages.firstWhereOrNull((noteImage) {
                final position = naturalPositionOf(noteImage.notePosition);
                return position != -1 && position <= line;
              })
            : noteImages.firstWhereOrNull(
                (noteImage) => naturalPositionOf(noteImage.notePosition) >= line);
        if (ledgerLineImage == null) {
          continue;
        }
      } else {
        ledgerLineImage = null;
      }
      final y = (bounds.height - ((line * noteHeight) - noteHeight / 2))
          .roundToDouble();
      if (ledgerLineImage != null) {
        final ledgerLineLeft = bounds.left +
            clefSize.width +
            (bounds.width - ovalWidth * 2 - clefSize.width) *
                ledgerLineImage.offset;
        final ledgerLineRight = ledgerLineLeft + ovalWidth * 1.6;
        canvas.drawLine(
            Offset(ledgerLineLeft, y), Offset(ledgerLineRight, y), _linePaint);
      } else {
        canvas.drawLine(
            Offset(bounds.left, y), Offset(bounds.right, y), _linePaint);

        firstLineY ??= y;
        lastLineY = y;
      }
    }

    const tailHeight = 7;
    final middleLineIndex =
        (firstLineIndex + (lastLineIndex - firstLineIndex - 1) / 2).floor();

    for (final noteImage in noteImages) {
      final displayNotePosition = const PianoUtils().spellNotePosition(
        noteImage.notePosition,
        keySignature: keySignature,
      );
      final noteIndex = naturalPositionOf(displayNotePosition);
      if (noteIndex == -1) {
        continue;
      }
      final ovalRect = Rect.fromLTWH(
          bounds.left +
              clefSize.width +
              (bounds.width - ovalWidth * 1.5 - clefSize.width) *
                  noteImage.offset,
          bounds.height - (noteIndex * noteHeight) - noteHeight / 2,
          ovalWidth,
          ovalHeight);
      canvas.save();
      canvas.translate(ovalRect.left, ovalRect.top + noteHeight * 0.3);
      canvas.rotate(-0.2);
      _notePaint.color = noteImage.color ?? noteColor;
      canvas.drawOval(Offset.zero & ovalRect.size, _notePaint);
      canvas.restore();

      final isOnOrAboveMiddleLine = noteIndex > middleLineIndex;

      final Offset tailFrom, tailTo;

      if (isOnOrAboveMiddleLine) {
        // Tail hangs down, on the left side
        tailFrom = ovalRect.centerLeft -
            Offset(-_tailPaint.strokeWidth / 2 - ovalWidth * 0.06,
                -ovalHeight * 0.1);
        tailTo = tailFrom + Offset(0, noteHeight * tailHeight);
      } else {
        // Tail stucks up, on the right side
        tailFrom = ovalRect.centerRight +
            Offset(-_tailPaint.strokeWidth / 2 + ovalWidth * 0.06,
                -ovalHeight * 0.1);
        tailTo = tailFrom + Offset(0, -noteHeight * tailHeight);
      }

      _tailPaint.color = noteImage.color ?? noteColor;
      canvas.drawLine(tailFrom, tailTo, _tailPaint);

      if (displayNotePosition.accidental != Accidental.None) {
        if (_accidentalSymbolPainters[displayNotePosition.accidental] ==
            null) {
          _accidentalSymbolPainters[displayNotePosition.accidental] =
              TextPainter(
                  text: TextSpan(
                      text: _accidentalGlyph(displayNotePosition.accidental),
                      style: TextStyle(
                          fontSize: ovalHeight * 2,
                          color: noteImage.color ?? noteColor)),
                  textDirection: TextDirection.ltr)
                ..layout();
        }

        _accidentalSymbolPainters[displayNotePosition.accidental]?.paint(
            canvas,
            ovalRect.topLeft.translate(
              -ovalHeight,
              -ovalHeight / 2,
            ));
      }
    }

    if (firstLineY == null || lastLineY == null) {
      return;
    }

    final clefHeight = (firstLineY - lastLineY);
    final isMacOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    final clefSymbolOffset = isMacOS ? (clef == Clef.Treble ? 0.5 : 0.2) : 0.35;

    if (_clefSymbolPainter == null || clefSize != _lastClefSize) {
      final clefSymbolScale = isMacOS ? (clef == Clef.Treble ? 2.3 : 1.3) : 1.5;
      final targetHeight = clefHeight * clefSymbolScale;
      const baseSize = 100.0;

      final metricsPainter = TextPainter(
        text: TextSpan(
          text: clef.symbol,
          style: const TextStyle(fontSize: baseSize),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final metricsHeight = metricsPainter.height;
      final scale = metricsHeight > 0 ? targetHeight / metricsHeight : 1.0;
      final scaledFontSize = baseSize * scale;

      _clefSymbolPainter = TextPainter(
          text: TextSpan(
              text: clef.symbol,
              style: TextStyle(fontSize: scaledFontSize, color: clefColor)),
          textDirection: TextDirection.ltr)
        ..layout();
    }
    _lastClefSize = clefSize;

    _clefSymbolPainter?.paint(
        canvas, Offset(bounds.left, lastLineY - clefSymbolOffset * clefHeight));
  }

  @override
  bool shouldRepaint(covariant CustomClefPainter oldDelegate) =>
      oldDelegate != this;
}
