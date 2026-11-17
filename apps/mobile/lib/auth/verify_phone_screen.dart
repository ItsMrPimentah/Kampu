import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/auth/auth_repository.dart';
import '../theme/midnight_theme.dart';
import '../theme/stitch_components.dart';

class VerifyPhoneScreen extends StatefulWidget {
  const VerifyPhoneScreen({
    super.key,
    required this.phone,
    required this.smsSent,
    required this.onVerify,
    required this.onResend,
    required this.onSignOut,
  });
  final String phone;
  final bool smsSent;
  final Future<AuthResult> Function(String code) onVerify;
  final Future<AuthResult> Function() onResend;
  final Future<AuthResult> Function() onSignOut;
  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _message;
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<AuthResult> Function() action, {
    String? success,
  }) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    final result = await action();
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.when(
        val: (_) => _message = success,
        err: (_) => _message = 'Unable to complete verification. Check the code or request a new SMS.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.midnight;
    return Scaffold(
      appBar: const StitchTopBar(
        title: 'ShowTime',
        subtitle: 'PHONE VERIFICATION',
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
                    Icons.phonelink_lock_outlined,
                    size: 64,
                    color: t.periwinkle,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'VERIFY YOUR PHONE',
                    textAlign: TextAlign.center,
                    style: t.displayStyle,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.smsSent
                        ? 'Enter the 6-digit code sent to ${widget.phone}.'
                        : 'We could not send the SMS. Request a new code.',
                    textAlign: TextAlign.center,
                    style: t.bodyStyle,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    key: const ValueKey('verification-code'),
                    controller: _code,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    textAlign: TextAlign.center,
                    style: t.displayStyle.copyWith(letterSpacing: 8),
                    decoration: const InputDecoration(
                      labelText: '6-digit code',
                      hintText: '••••••',
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    Text(_message!, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 20),
                  StitchGradientButton(
                    label: _loading ? 'PLEASE WAIT…' : 'CONFIRM & ENTER',
                    onPressed: _loading
                        ? null
                        : () => _run(() => widget.onVerify(_code.text)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => _run(
                            widget.onResend,
                            success: 'A new code has been requested.',
                          ),
                    child: const Text('Resend SMS'),
                  ),
                  TextButton(
                    onPressed: _loading ? null : () => _run(widget.onSignOut),
                    child: const Text('Use another account'),
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
