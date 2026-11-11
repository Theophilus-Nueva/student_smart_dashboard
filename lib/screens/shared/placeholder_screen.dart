import 'package:flutter/material.dart';

import '../../widgets/common.dart';

/// Stand-in for a screen or tab that this lab week doesn't include yet
/// (Week 1 allows placeholder pages for the bottom-nav tabs).
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.showAppBar = true,
    this.message = 'This screen is coming in a later lab week.',
  });

  final String title;
  final bool showAppBar;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(title: Text(title), automaticallyImplyLeading: true)
          : null,
      body: StateMessage(
        icon: Icons.construction,
        title: title,
        message: message,
      ),
    );
  }
}
