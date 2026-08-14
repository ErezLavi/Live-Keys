import 'package:flutter/material.dart';

/// Presents [content] as a dropdown menu on wide layouts and as a modal bottom
/// sheet on compact layouts, sharing a single [trigger].
///
/// [trigger] receives an `open` callback — wire it to the trigger's
/// `onTap`/`onPressed` and the content is revealed in whichever form matches
/// the current layout.
class AdaptiveMenu extends StatelessWidget {
  const AdaptiveMenu({
    super.key,
    required this.isCompact,
    required this.trigger,
    required this.content,
    this.alignmentOffset = const Offset(0, 8),
  });

  final bool isCompact;
  final Widget Function(BuildContext context, VoidCallback open) trigger;
  final Widget content;
  final Offset alignmentOffset;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return trigger(context, () => _openSheet(context));
    }
    return MenuAnchor(
      alignmentOffset: alignmentOffset,
      builder: (context, controller, _) => trigger(context, () {
        if (controller.isOpen) {
          controller.close();
        } else {
          controller.open();
        }
      }),
      menuChildren: [content],
    );
  }

  Future<void> _openSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 450),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}
