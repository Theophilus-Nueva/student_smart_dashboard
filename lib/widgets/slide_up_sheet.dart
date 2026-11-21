import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The app's one slide-up style, taken from the Map screen: a white panel
/// with rounded top corners, a soft shadow and a gray drag handle. It can
/// be dragged from anywhere on it, not just the handle.
///
/// Used directly by the Map screen (inside its own DraggableScrollableSheet)
/// and by every modal sheet through [showSlideUpSheet].
class SlideUpPanel extends StatelessWidget {
  const SlideUpPanel({
    super.key,
    required this.children,
    this.controller,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;

  /// From a DraggableScrollableSheet, so dragging the content moves the
  /// panel; null for a sheet that just fits its content.
  final ScrollController? controller;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 12)],
      ),
      child: SingleChildScrollView(
        controller: controller,
        // Clear of the notch (landscape) and the home indicator.
        padding: EdgeInsets.fromLTRB(
          16 + insets.left,
          0,
          16 + insets.right,
          16 + insets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxisAlignment,
          children: [const SlideUpHandle(), ...children],
        ),
      ),
    );
  }
}

/// Gray drag handle at the top of a [SlideUpPanel].
class SlideUpHandle extends StatelessWidget {
  const SlideUpHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        key: const Key('slideUp.handle'),
        margin: const EdgeInsets.symmetric(vertical: 10),
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Title at the top of a slide-up sheet.
class SlideUpTitle extends StatelessWidget {
  const SlideUpTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
  );
}

/// Opens a modal [SlideUpPanel] over the current screen. Tapping outside
/// closes it; so does dragging it down (from anywhere on it) far enough or
/// with a flick. A small drag springs back.
///
/// - Without [peekHeight] the sheet fits its content.
/// - With [peekHeight] (px of content shown when it opens, worked out from
///   the sheet's own context so it follows rotation) it works like
///   the Map panel: drag it up to expand to the full screen and it snaps
///   between the two. It only expands while [canExpand] is true.
///
/// It rebuilds whenever [listenable] changes, so live values update while
/// it is open. Full screen width: Material 3 caps sheets at 640 px and
/// centres them, so in landscape a tap beside a sheet closed it; minWidth
/// infinity (clamped to the screen) makes it span the width.
Future<T?> showSlideUpSheet<T>(
  BuildContext context, {
  required List<Widget> Function(BuildContext context) children,
  Listenable? listenable,
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.stretch,
  double Function(BuildContext context)? peekHeight,
  bool Function()? canExpand,
}) {
  Widget panel(BuildContext context, [ScrollController? controller]) =>
      SlideUpPanel(
        controller: controller,
        crossAxisAlignment: crossAxisAlignment,
        children: children(context),
      );

  // Live values refresh only the panel's content, never the sheet around
  // it: rebuilding the sheet mid-drag made it jump (see _ExpandableSheet).
  Widget live(BuildContext context, [ScrollController? controller]) =>
      listenable == null
      ? panel(context, controller)
      : ListenableBuilder(
          listenable: listenable,
          builder: (context, _) => panel(context, controller),
        );

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    constraints: const BoxConstraints(minWidth: double.infinity),
    builder: (context) {
      if (peekHeight == null) {
        final size = MediaQuery.sizeOf(context);
        final insets = MediaQuery.paddingOf(context);
        // Never taller than the screen below the status bar.
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: size.height - insets.top),
          child: live(context),
        );
      }
      return _ExpandableSheet(
        peekHeight: peekHeight,
        canExpand: canExpand,
        listenable: listenable,
        builder: live,
      );
    },
  );
}

/// Map-style sheet: opens at [peekHeight], drags up to the full screen and
/// snaps between the two; dragging it to the bottom closes it.
///
/// It must not rebuild while it is being dragged: DraggableScrollableSheet
/// compares its snap sizes by identity, so every rebuild with a new list
/// fired a snap mid-drag. Sensor updates therefore refresh only the content
/// ([builder] adds its own listener); this widget rebuilds only when
/// [canExpand] actually changes, and keeps the same snap-size list.
class _ExpandableSheet extends StatefulWidget {
  const _ExpandableSheet({
    required this.peekHeight,
    required this.canExpand,
    required this.listenable,
    required this.builder,
  });

  final double Function(BuildContext context) peekHeight;
  final bool Function()? canExpand;
  final Listenable? listenable;
  final ScrollableWidgetBuilder builder;

  @override
  State<_ExpandableSheet> createState() => _ExpandableSheetState();
}

class _ExpandableSheetState extends State<_ExpandableSheet> {
  /// Handle plus its margins, above the content.
  static const _handle = 24.0;

  late bool _canExpand = widget.canExpand?.call() ?? true;
  List<double> _snapSizes = const [];

  @override
  void initState() {
    super.initState();
    widget.listenable?.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.listenable?.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final canExpand = widget.canExpand?.call() ?? true;
    if (canExpand != _canExpand) setState(() => _canExpand = canExpand);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.paddingOf(context);
    final full = (size.height - insets.top) / size.height;
    final peek =
        ((widget.peekHeight(context) + _handle + 16 + insets.bottom) /
                size.height)
            .clamp(0.2, full);
    final max = _canExpand ? full : peek;
    final min = math.min(0.1, peek);
    final snapSizes = [if (peek > min && peek < max) peek];
    if (!listEquals(snapSizes, _snapSizes)) _snapSizes = snapSizes;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: peek,
      minChildSize: min,
      maxChildSize: max,
      snap: true,
      snapSizes: _snapSizes,
      builder: widget.builder,
    );
  }
}
