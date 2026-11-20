import 'package:flutter/material.dart';

/// Slide-up sheet used on the Device tab (compass, accelerometer). It
/// rebuilds whenever [listenable] changes so live sensor values update
/// while it is open.
///
/// - Full screen width: Material 3 caps sheets at 640 px and centres them,
///   so in landscape a tap beside the sheet closed it. The sheet sits in an
///   Align, so without a minimum width it shrinks to its content; minWidth
///   infinity is clamped to the screen width.
/// - Closes only from the drag handle or a tap outside; see
///   [DeviceSheetBody].
Future<void> showDeviceSheet(
  BuildContext context, {
  required Listenable listenable,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(minWidth: double.infinity),
    backgroundColor: Colors.white,
    builder: (context) => ListenableBuilder(
      listenable: listenable,
      builder: (c, _) => builder(c),
    ),
  );
}

/// Scrolling content of a [showDeviceSheet] sheet, kept clear of the notch
/// and the home indicator. With [height] the sheet stays that tall and the
/// content scrolls inside it; without it the sheet fits its content (up to
/// the screen).
class DeviceSheetBody extends StatelessWidget {
  const DeviceSheetBody({super.key, required this.children, this.height});

  final List<Widget> children;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final body = SingleChildScrollView(
      // Drags on the content always scroll it, even when it fits, so they
      // never pull the sheet closed. Only the drag handle or a tap outside
      // closes it.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        24 + insets.left,
        0,
        24 + insets.right,
        32 + insets.bottom,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
    return height == null ? body : SizedBox(height: height, child: body);
  }
}

/// Title at the top of a device sheet.
class DeviceSheetTitle extends StatelessWidget {
  const DeviceSheetTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
  );
}
