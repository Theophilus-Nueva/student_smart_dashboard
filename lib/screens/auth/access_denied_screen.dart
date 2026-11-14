import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import '../../theme/app_colors.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key, required this.screenName});

  final String screenName;

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).session.user;
    final role = user == null ? 'signed out' : 'signed in as a Student';
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: AppColors.offlineBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    size: 40,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Faculty access only',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '$screenName is only available to faculty accounts. '
                  "You're $role.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 15),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
