import 'package:flutter/material.dart';

import '../core/auth/auth_repository.dart';
import '../theme/midnight_theme.dart';
import '../theme/stitch_components.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });
  final Future<AuthResult> Function(String identifier, String password) onLogin;
  final VoidCallback onRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _phone = true;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (_identifier.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter your phone or email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.onLogin(
      _identifier.text.trim(),
      _password.text,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.when(
        val: (_) {},
        err: (_) =>
            _error = 'Unable to sign in. Check your details and connection.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.midnight;
    return Scaffold(
      appBar: const StitchTopBar(
        title: 'ShowTime',
        subtitle: 'MATCHDAY ACCESS',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Icon(
                    Icons.sports_soccer_outlined,
                    size: 56,
                    color: t.periwinkle,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'WELCOME BACK, BALLER',
                    textAlign: TextAlign.center,
                    style: t.displayStyle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find matches, manage squads, and play together.',
                    textAlign: TextAlign.center,
                    style: t.bodyStyle,
                  ),
                  const SizedBox(height: 28),
                  StitchCard(
                    color: t.carbon,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: true,
                              label: Text('Phone Number'),
                              icon: Icon(Icons.phone_android),
                            ),
                            ButtonSegment(
                              value: false,
                              label: Text('Email Address'),
                              icon: Icon(Icons.alternate_email),
                            ),
                          ],
                          selected: {_phone},
                          onSelectionChanged: (value) => setState(() {
                            _phone = value.first;
                            _identifier.clear();
                          }),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          key: const ValueKey('login-identifier'),
                          controller: _identifier,
                          keyboardType: _phone
                              ? TextInputType.phone
                              : TextInputType.emailAddress,
                          autofillHints: [
                            _phone
                                ? AutofillHints.telephoneNumber
                                : AutofillHints.email,
                          ],
                          decoration: InputDecoration(
                            labelText: _phone
                                ? 'Mobile number'
                                : 'Email address',
                            hintText: _phone
                                ? '+351 912 345 678'
                                : 'player@example.com',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const ValueKey('login-password'),
                          controller: _password,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              tooltip: _obscure
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        StitchGradientButton(
                          label: _loading ? 'SIGNING IN…' : 'SIGN IN & PLAY',
                          onPressed: _loading ? null : _submit,
                          icon: Icons.arrow_forward,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: widget.onRegister,
                    child: const Text('Create your player pass'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
