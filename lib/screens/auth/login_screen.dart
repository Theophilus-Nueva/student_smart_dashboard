import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import '../../services/app_settings.dart';
import '../../services/biometric_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../theme/app_assets.dart';
import '../../config/lab_week.dart';

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

  /// The phone's biometric, once known; shown only after it is turned on
  /// in Settings › Security Center.
  BiometricKind? _biometric;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !Feature.biometricLogin.on) return;
      final services = AppScope.of(context);
      if (!services.settings.get(AppSettings.biometricLogin)) return;
      final kind = await services.biometric.detect();
      if (!mounted || !kind.available) return;
      // Only offered: the user picks password or Face ID each time.
      setState(() => _biometric = kind);
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

  /// Goes straight to the phone's own prompt (e.g. Face ID); on failure or
  /// cancel, says why and leaves the password form ready.
  Future<void> _biometricSignIn() async {
    final kind = _biometric;
    if (kind == null) return;
    setState(() => _busy = true);
    final error = await AppScope.of(context).session.signInWithBiometric(kind);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) showAppSnack(context, error, error: true);
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
                    Text(
                      LabWeek.appName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                    // Biometric login is Week 6; shown once it is set up in
                    // Settings and only for what this phone has.
                    if (_biometric case final kind?) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: const Key('login.biometric'),
                        onPressed: _busy ? null : _biometricSignIn,
                        icon: Icon(kind.icon),
                        label: Text('Sign in with ${kind.label}'),
                      ),
                    ],
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
