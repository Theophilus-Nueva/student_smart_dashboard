import 'dart:math' as math;

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
  Widget sheet(BuildContext context) {
    if (peekHeight == null) {
      final size = MediaQuery.sizeOf(context);
      final insets = MediaQuery.paddingOf(context);
      // Never taller than the screen below the status bar.
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: size.height - insets.top),
        child: SlideUpPanel(
          crossAxisAlignment: crossAxisAlignment,
          children: children(context),
        ),
      );
    }
    return _ExpandableSheet(
      peekHeight: peekHeight(context),
      canExpand: canExpand?.call() ?? true,
      builder: (context, controller) => SlideUpPanel(
        controller: controller,
        crossAxisAlignment: crossAxisAlignment,
        children: children(context),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    constraints: const BoxConstraints(minWidth: double.infinity),
    builder: (context) => listenable == null
        ? sheet(context)
        : ListenableBuilder(
            listenable: listenable,
            builder: (context, _) => sheet(context),
          ),
  );
}

/// Map-style sheet: opens at [peekHeight], drags up to the full screen and
/// snaps between the two; dragging it to the bottom closes it.
class _ExpandableSheet extends StatelessWidget {
  const _ExpandableSheet({
    required this.peekHeight,
    required this.canExpand,
    required this.builder,
  });

  final double peekHeight;
  final bool canExpand;
  final ScrollableWidgetBuilder builder;

  /// Handle plus its margins, above the content.
  static const _handle = 24.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final insets = MediaQuery.paddingOf(context);
    final full = (size.height - insets.top) / size.height;
    final peek = ((peekHeight + _handle + 16 + insets.bottom) / size.height)
        .clamp(0.2, full);
    final max = canExpand ? full : peek;
    final min = math.min(0.1, peek);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: peek,
      minChildSize: min,
      maxChildSize: max,
      snap: true,
      snapSizes: [if (peek > min && peek < max) peek],
      builder: builder,
    );
  }
}
