import 'package:flutter/material.dart';
import 'package:piano_app/common/app_sizes.dart';
import 'package:piano_app/common/constants.dart';
import 'package:piano_app/domain/key_signature_reference.dart';

typedef OnScaleSelected = void Function(int rootPc, String scaleType);
typedef OnScaleCleared = void Function();

class ScalesGrid extends StatefulWidget {
  final OnScaleSelected? onScaleSelected;
  final OnScaleCleared? onScaleCleared;
  final int initialRootPc;
  final String initialScaleType;
  final KeySignatureReference? keySignature;
  final bool useFlats;

  const ScalesGrid({
    super.key,
    this.onScaleSelected,
    this.onScaleCleared,
    this.initialRootPc = 0,
    this.initialScaleType = 'major',
    this.keySignature,
    this.useFlats = false,
  });

  @override
  State<ScalesGrid> createState() => _ScalesGridState();
}

class _ScalesGridState extends State<ScalesGrid> {
  late int _rootPc;
  late String _scaleType;

  @override
  void initState() {
    super.initState();
    _rootPc = widget.initialRootPc;
    _scaleType = widget.initialScaleType;
  }

  @override
  void didUpdateWidget(covariant ScalesGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRootPc != widget.initialRootPc ||
        oldWidget.initialScaleType != widget.initialScaleType) {
      _rootPc = widget.initialRootPc;
      _scaleType = widget.initialScaleType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rootNames = List<int>.generate(12, (index) => index)
        .map(
          (pc) => Constants.noteName(
            pc,
            useFlats: widget.useFlats,
            keySignature: widget.keySignature,
          ),
        )
        .toList();
    final scaleTypes = Constants.scaleDB.keys.toList();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppSizes.radiusL),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.space8,
          horizontal: AppSizes.space12,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSizes.space8.sbWidth,
              Row(
                children: [
                  Spacer(),
                  TextButton.icon(
                    onPressed: _clearSelection,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              Text('Root', style: Theme.of(context).textTheme.titleSmall),
              AppSizes.space8.sbHeight,
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(rootNames.length, (index) {
                  final selected = _rootPc == index;
                  return ChoiceChip(
                    label: Text(rootNames[index]),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => _selectRoot(index),
                  );
                }),
              ),
              AppSizes.space12.sbHeight,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Scale', style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
              AppSizes.space8.sbHeight,
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: scaleTypes.map((type) {
                  final selected = _scaleType == type;
                  return ChoiceChip(
                    label: Text(_labelForScaleType(type)),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => _selectType(type),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectRoot(int rootPc) {
    setState(() {
      _rootPc = rootPc;
    });
    widget.onScaleSelected?.call(_rootPc, _scaleType);
  }

  void _selectType(String scaleType) {
    setState(() {
      _scaleType = scaleType;
    });
    widget.onScaleSelected?.call(_rootPc, _scaleType);
  }

  void _clearSelection() {
    setState(() {
      _rootPc = 0;
      _scaleType = 'major';
    });
    widget.onScaleCleared?.call();
  }

  String _labelForScaleType(String type) {
    return type
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }
}
