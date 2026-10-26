import 'package:flutter/material.dart';

class SummaryPageBody extends StatelessWidget {
  const SummaryPageBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Summary Page Screen",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
