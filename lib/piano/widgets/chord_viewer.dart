import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:piano_app/common/app_sizes.dart';

class ChordViewer extends StatelessWidget {
  const ChordViewer({
    super.key,
    required this.chord,
    required this.splitChordName,
    this.fontWeight = FontWeight.bold,
  });

  final String chord;
  final (String, String) Function(String) splitChordName;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final (root, suffix) = splitChordName(chord);
    if (root.isEmpty && suffix.isEmpty) {
      return const Text('');
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeBasis = math.min(
          constraints.maxWidth * 0.75,
          constraints.maxHeight * 1.5,
        );
        final scaledRootSize = AppSizes.chordRootFontSize(sizeBasis);
        final scaledSuffixSize = AppSizes.chordSuffixFontSize(sizeBasis);

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: root,
                    style: TextStyle(
                      fontSize: scaledRootSize,
                      fontWeight: fontWeight,
                    ),
                  ),
                  TextSpan(
                    text: suffix,
                    style: TextStyle(
                      fontSize: scaledSuffixSize,
                      fontWeight: fontWeight,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              softWrap: false,
            ),
          ),
        );
      },
    );
  }
}
