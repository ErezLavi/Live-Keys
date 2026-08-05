import 'package:flutter/material.dart';
import 'package:piano_app/common/app_sizes.dart';
import 'package:piano_app/domain/key_signature_reference.dart';

typedef OnKeySignatureSelected = void Function(KeySignatureReference signature);

class KeySignatureGrid extends StatelessWidget {
  const KeySignatureGrid({
    super.key,
    required this.keySignatures,
    required this.selectedKeySignature,
    required this.onSelected,
  });

  final List<KeySignatureReference> keySignatures;
  final KeySignatureReference selectedKeySignature;
  final OnKeySignatureSelected onSelected;

  @override
  Widget build(BuildContext context) {
    final sharpKeys = keySignatures.where((signature) => !signature.usesFlats);
    final flatKeys = keySignatures.where((signature) => signature.usesFlats);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSizes.radiusL),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.space12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sharps', style: Theme.of(context).textTheme.titleSmall),
              AppSizes.space8.sbHeight,
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: sharpKeys
                    .map(
                      (signature) => ChoiceChip(
                        label: Text(signature.label),
                        selected: signature == selectedKeySignature,
                        showCheckmark: false,
                        onSelected: (_) => onSelected(signature),
                      ),
                    )
                    .toList(),
              ),
              AppSizes.space12.sbHeight,
              Text('Flats', style: Theme.of(context).textTheme.titleSmall),
              AppSizes.space8.sbHeight,
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: flatKeys
                    .map(
                      (signature) => ChoiceChip(
                        label: Text(signature.label),
                        selected: signature == selectedKeySignature,
                        showCheckmark: false,
                        onSelected: (_) => onSelected(signature),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
