import 'package:flutter/material.dart';

import '../../widgets/common.dart';

/// Stand-in for a screen that a later build step fills in.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.showAppBar = true,
  });

  final String title;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title)) : null,
      body: StateMessage(
        icon: Icons.construction,
        title: title,
        message: 'This screen is coming in a later build step.',
      ),
    );
  }
}
