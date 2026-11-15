import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

import 'verify_phone_controller.dart';

/// Phone verification screen for the app authentication flow.
class VerifyPhoneScreen extends HookConsumerWidget {
  const VerifyPhoneScreen({
    super.key,
    required this.phone,
    required this.smsSent,
    required this.onVerify,
    required this.onResend,
    required this.onSignOut,
  });
  final String phone;
  final bool? smsSent;
  final Future<bool> Function(String code) onVerify;
  final VerificationAction onResend;
  final VerificationAction onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = useTextEditingController();
    final state = ref.watch(verifyPhoneControllerProvider);
    final controller = ref.read(verifyPhoneControllerProvider.notifier);
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
                    switch (smsSent) {
                      true => 'Enter the 6-digit code sent to $phone.',
                      false => 'We could not send the SMS. Request a new code.',
                      null => 'Enter your 6-digit code, or request a new SMS.',
                    },
                    textAlign: TextAlign.center,
                    style: t.bodyStyle,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    key: const ValueKey('verification-code'),
                    controller: code,
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
                  if (state.message case final message?) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(message, textAlign: TextAlign.center),
                    ),
                  ],
                  const SizedBox(height: 20),
                  StitchGradientButton(
                    label: state.loading ? 'PLEASE WAIT…' : 'CONFIRM & ENTER',
                    onPressed: state.loading
                        ? null
                        : () => controller.verify(code.text, onVerify),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: state.loading
                        ? null
                        : () => controller.resend(onResend),
                    child: const Text('Resend SMS'),
                  ),
                  TextButton(
                    onPressed: state.loading
                        ? null
                        : () => controller.signOut(onSignOut),
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
