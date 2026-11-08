import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import '../../services/app_settings.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../theme/app_assets.dart';

/// Shared / Login and Shared / Biometric Login (Week 6).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Settings › Fingerprint Login: prompt straight away for the last account.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final services = AppScope.of(context);
      if (!services.settings.get(AppSettings.fingerprintLogin)) return;
      if (services.session.rememberedUser == null) return;
      if (!await services.biometric.isAvailable() || !mounted) return;
      await _fingerprint();
    });
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await AppScope.of(context).session
        .signIn(_username.text, _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  Future<void> _fingerprint() async {
    final session = AppScope.of(context).session;
    final error = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (_) => _BiometricSheet(onScan: session.signInWithFingerprint),
    );
    if (error != null && mounted) showAppSnack(context, error, error: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(AppAssets.logo, height: 120),
                    const SizedBox(height: 16),
                    const Text(
                      'Smart Campus Tour Guide',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text('Username / Email'),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('login.username'),
                      controller: _username,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    const Text('Password'),
                    const SizedBox(height: 6),
                    TextField(
                      key: const Key('login.password'),
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _signIn(),
                      decoration: InputDecoration(
                        errorText: _error,
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _busy ? null : _signIn,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _fingerprint,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Sign in with fingerprint'),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your role (Student or Faculty) comes from your LPU account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Fingerprint Required" sheet. Pops with an error message, or null on success.
class _BiometricSheet extends StatefulWidget {
  const _BiometricSheet({required this.onScan});

  final Future<String?> Function() onScan;

  @override
  State<_BiometricSheet> createState() => _BiometricSheetState();
}

class _BiometricSheetState extends State<_BiometricSheet> {
  bool _scanning = false;

  Future<void> _scan() async {
    setState(() => _scanning = true);
    final error = await widget.onScan();
    if (mounted) Navigator.of(context).pop(error);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Fingerprint Required',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Place your finger on the sensor to open Smart Campus Tour Guide.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          IconButton(
            iconSize: 72,
            tooltip: 'Scan fingerprint',
            onPressed: _scanning ? null : _scan,
            icon: const Icon(Icons.fingerprint, color: AppColors.brand),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Use password instead'),
          ),
        ],
      ),
    );
  }
}
