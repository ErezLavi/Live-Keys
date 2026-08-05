class KeySignatureReference {
  final String majorKey;
  final String minorKey;
  final int accidentalCount;
  final bool usesFlats;
  final List<String> accidentals;

  const KeySignatureReference({
    required this.majorKey,
    required this.minorKey,
    required this.accidentalCount,
    required this.usesFlats,
    required this.accidentals,
  });

  String get label => '$majorKey / $minorKey';

  String get accidentalsLabel {
    if (accidentals.isEmpty) return 'No accidentals';
    final suffix = usesFlats ? 'b' : '#';
    return '$accidentalCount$suffix: ${accidentals.join(' ')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KeySignatureReference &&
        other.majorKey == majorKey &&
        other.minorKey == minorKey &&
        other.accidentalCount == accidentalCount &&
        other.usesFlats == usesFlats;
  }

  @override
  int get hashCode =>
      Object.hash(majorKey, minorKey, accidentalCount, usesFlats);
}
