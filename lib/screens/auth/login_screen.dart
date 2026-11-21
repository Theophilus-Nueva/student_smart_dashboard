import 'package:flutter/material.dart';

import '../../services/app_services.dart';
import '../../services/app_settings.dart';
import '../../services/biometric_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/slide_up_sheet.dart';
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
      setState(() => _biometric = kind);
      // Prompt straight away for the last account.
      if (services.session.rememberedUser != null) await _biometricSignIn();
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

  Future<void> _biometricSignIn() async {
    final kind = _biometric;
    if (kind == null) return;
    final session = AppScope.of(context).session;
    final error = await showSlideUpSheet<String?>(
      context,
      children: (_) => [
        _BiometricSheet(
          kind: kind,
          onScan: () => session.signInWithBiometric(kind),
        ),
      ],
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

/// "Face ID Required" / "Fingerprint Required" sheet. Pops with an error
/// message, or null on success.
class _BiometricSheet extends StatefulWidget {
  const _BiometricSheet({required this.kind, required this.onScan});

  final BiometricKind kind;
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
    final kind = widget.kind;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${kind.label} Required',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '${kind.instruction} to open ${LabWeek.appName}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          IconButton(
            iconSize: 72,
            tooltip: 'Use ${kind.label}',
            onPressed: _scanning ? null : _scan,
            icon: Icon(kind.icon, color: AppColors.brand),
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
