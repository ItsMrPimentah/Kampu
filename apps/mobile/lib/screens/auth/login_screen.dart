import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

import 'login_controller.dart';

/// Sign-in screen for the app authentication flow.
class LoginScreen extends HookConsumerWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
  });

  final LoginAction onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identifier = useTextEditingController();
    final password = useTextEditingController();
    final phone = useState(true);
    final obscure = useState(true);
    final state = ref.watch(loginControllerProvider(onLogin));
    final controller = ref.read(loginControllerProvider(onLogin).notifier);
    final t = context.midnight;
    final identifierLabel = phone.value ? 'Mobile number' : 'Email address';

    return Scaffold(
      backgroundColor: t.voidColor,
      appBar: null,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter(t.gunmetal)),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [t.iris.withValues(alpha: 0.15), Colors.transparent],
                  stops: const [0, 0.65],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _LoginHero(),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: t.carbon,
                          border: Border.all(color: t.gunmetal),
                          borderRadius: t.cardBorderRadius,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _MethodSelector(
                              phone: phone.value,
                              onChanged: (value) {
                                if (phone.value != value) {
                                  phone.value = value;
                                  identifier.clear();
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                            _FieldLabel(identifierLabel),
                            const SizedBox(height: 6),
                            Semantics(
                              label: identifierLabel,
                              hint: phone.value
                                  ? 'Include country code, e.g. +351.'
                                  : null,
                              child: TextField(
                                key: const ValueKey('login-identifier'),
                                controller: identifier,
                                keyboardType: phone.value
                                    ? TextInputType.phone
                                    : TextInputType.emailAddress,
                                autofillHints: [
                                  phone.value
                                      ? AutofillHints.telephoneNumber
                                      : AutofillHints.email,
                                ],
                                decoration: _inputDecoration(
                                  context,
                                  hint: phone.value
                                      ? '+351 912 345 678'
                                      : 'player@example.com',
                                  icon: phone.value
                                      ? Icons.phone_android
                                      : Icons.mail_outline,
                                ),
                              ),
                            ),
                            if (phone.value) ...[
                              const SizedBox(height: 6),
                              ExcludeSemantics(
                                child: Text(
                                  'Include country code, e.g. +351.',
                                  style: t.bodyStyle.copyWith(
                                    fontSize: 12,
                                    color: t.steelLight,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            const _FieldLabel('Password'),
                            const SizedBox(height: 6),
                            Semantics(
                              label: 'Password',
                              child: TextField(
                                key: const ValueKey('login-password'),
                                controller: password,
                                obscureText: obscure.value,
                                autofillHints: const [AutofillHints.password],
                                decoration: _inputDecoration(
                                  context,
                                  hint: '••••••••••••',
                                  icon: Icons.lock_outline,
                                  suffix: IconButton(
                                    tooltip: obscure.value
                                        ? 'Show password'
                                        : 'Hide password',
                                    onPressed: () =>
                                        obscure.value = !obscure.value,
                                    icon: Icon(
                                      obscure.value
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: t.steelLight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (state.error case final error?) ...[
                              const SizedBox(height: 12),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  error,
                                  style: TextStyle(color: t.danger),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            _LoginButton(
                              loading: state.loading,
                              onPressed: () => controller.submit(
                                identifier.text,
                                password.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) => Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: t.bodyStyle.copyWith(
                                fontSize: 12,
                                color: t.steelLight,
                              ),
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth,
                              ),
                              child: TextButton(
                                onPressed: onRegister,
                                style: TextButton.styleFrom(
                                  foregroundColor: t.periwinkle,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: const Size(0, 48),
                                ),
                                child: const Text(
                                  'Create your player pass',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(
  BuildContext context, {
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  final t = context.midnight;
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );
  return InputDecoration(
    filled: true,
    fillColor: const Color(0xFF0E0F17),
    hintText: hint,
    hintStyle: TextStyle(color: t.steelLight, fontSize: 14),
    prefixIcon: Icon(icon, size: 20, color: t.steelLight),
    suffixIcon: suffix,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    enabledBorder: border(t.gunmetal),
    focusedBorder: border(t.periwinkle),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Text(
      label.toUpperCase(),
      style: context.midnight.labelStyle.copyWith(
        color: context.midnight.steelLight,
      ),
    ),
  );
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    final t = context.midnight;
    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: t.carbon,
                  border: Border.all(color: t.gunmetal),
                  borderRadius: t.cardBorderRadius,
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      t.iris.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(32, 32),
                    painter: _EmblemPainter(t.periwinkle),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: _Beacon(color: t.iris, size: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            'WELCOME BACK, BALLER',
            textAlign: TextAlign.center,
            style: t.displayStyle.copyWith(fontSize: 24, height: 1.2),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF181B2A),
            border: Border.all(color: t.gunmetal),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Beacon(color: t.periwinkle, size: 6),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'MATCHDAY ACCESS',
                  style: t.labelStyle.copyWith(color: t.periwinkle),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            'Find matches, manage squads, and play together.',
            textAlign: TextAlign.center,
            style: t.bodyStyle.copyWith(
              fontSize: 12,
              height: 1.5,
              color: t.steelLight,
            ),
          ),
        ),
      ],
    );
  }
}

class _Beacon extends StatelessWidget {
  const _Beacon({required this.color, this.size = 8});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 8),
        ],
      ),
    ),
  );
}

class _MethodSelector extends StatelessWidget {
  const _MethodSelector({required this.phone, required this.onChanged});
  final bool phone;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.midnight;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0C14),
        border: Border.all(color: t.gunmetal),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MethodButton(
              label: 'Phone Number',
              icon: Icons.phone_android,
              selected: phone,
              onPressed: () => onChanged(true),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _MethodButton(
              label: 'Email Address',
              icon: Icons.alternate_email,
              selected: !phone,
              onPressed: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.midnight;
    return MergeSemantics(
      child: Semantics(
        selected: selected,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            foregroundColor: selected ? t.periwinkle : t.steelLight,
            backgroundColor: selected ? t.carbon : Colors.transparent,
            side: BorderSide(color: selected ? t.gunmetal : Colors.transparent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.midnight;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        // Keep white action text legible across the full Midnight gradient.
        gradient: loading
            ? null
            : LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [t.iris, Color.lerp(t.iris, t.periwinkle, 0.25)!],
              ),
        color: loading ? t.gunmetal : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: loading
            ? null
            : [
                BoxShadow(
                  color: t.iris.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: TextButton(
        onPressed: loading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          disabledForegroundColor: t.steelLight,
          minimumSize: const Size.fromHeight(48),
          shape: shape,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                loading ? 'SIGNING IN…' : 'SIGN IN & PLAY',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => oldDelegate.color != color;
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.save();
    canvas.scale(scale);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final outline = Path()
      ..moveTo(12, 2)
      ..lineTo(2, 7)
      ..lineTo(2, 17)
      ..lineTo(12, 22)
      ..lineTo(22, 17)
      ..lineTo(22, 7)
      ..close();
    canvas.drawPath(outline, paint);
    canvas.drawLine(const Offset(2, 7), const Offset(12, 12), paint);
    canvas.drawLine(const Offset(22, 7), const Offset(12, 12), paint);
    canvas.drawLine(const Offset(12, 12), const Offset(12, 22), paint);
    canvas.drawCircle(const Offset(12, 12), 2.5, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EmblemPainter oldDelegate) => oldDelegate.color != color;
}
