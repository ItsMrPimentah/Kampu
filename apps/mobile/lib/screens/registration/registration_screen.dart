import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:showtime_mobile/core/eligibility/eligibility.dart';
import 'package:showtime_mobile/core/registration/registration_models.dart';
import 'package:showtime_mobile/shared/ui/ui.dart';

import 'registration_controller.dart';

class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({
    super.key,
    required this.onContinue,
    this.onBack,
    this.onHelp,
    this.onLogin,
    this.onRegister,
  });

  final FutureOr<void> Function(RegistrationSubmission submission) onContinue;
  final Future<bool> Function(RegistrationSubmission submission)? onRegister;
  final VoidCallback? onBack;
  final VoidCallback? onHelp;
  final VoidCallback? onLogin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullName = useTextEditingController();
    final dateOfBirth = useTextEditingController();
    final phone = useTextEditingController();
    final email = useTextEditingController();
    final password = useTextEditingController();
    final countryCode = useState('+351');
    final acceptedTerms = useState(false);
    final obscurePassword = useState(true);
    final state = ref.watch(registrationControllerProvider);
    final controller = ref.read(registrationControllerProvider.notifier);
    return _RegistrationView(
      context: context,
      widget: this,
      controller: controller,
      state: state,
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      phone: phone,
      email: email,
      password: password,
      countryCode: countryCode,
      acceptedTerms: acceptedTerms,
      obscurePassword: obscurePassword,
    ).build();
  }
}

class _RegistrationView {
  _RegistrationView({
    required this.context,
    required this.widget,
    required this.controller,
    required this.state,
    required TextEditingController fullName,
    required TextEditingController dateOfBirth,
    required TextEditingController phone,
    required TextEditingController email,
    required TextEditingController password,
    required this.countryCode,
    required this.acceptedTerms,
    required this.obscurePassword,
  }) : _fullNameController = fullName,
       _dateOfBirthController = dateOfBirth,
       _phoneController = phone,
       _emailController = email,
       _passwordController = password;

  final BuildContext context;
  final RegisterScreen widget;
  final RegistrationController controller;
  final RegistrationState state;
  final TextEditingController _fullNameController,
      _dateOfBirthController,
      _phoneController,
      _emailController,
      _passwordController;
  final ValueNotifier<String> countryCode;
  final ValueNotifier<bool> acceptedTerms, obscurePassword;

  RegistrationInput get _input => RegistrationInput(
    fullName: _fullNameController.text,
    dateOfBirth: _dateOfBirthController.text,
    phone: _phoneController.text,
    email: _emailController.text,
    password: _passwordController.text,
    countryCode: countryCode.value,
    acceptedTerms: acceptedTerms.value,
  );

  void _onFieldChanged({bool dateOfBirth = false}) =>
      controller.fieldsChanged(_input);

  Future<void> _submit() => controller.submit(_input, (submission) async {
    final register = widget.onRegister;
    if (register != null) return register(submission);
    await widget.onContinue(submission);
    return true;
  });

  void _goBack() {
    if (widget.onBack case final onBack?) {
      onBack();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _showHelp() {
    if (widget.onHelp case final onHelp?) {
      onHelp();
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Player pass help'),
        content: const Text(
          'Create your player pass to join local matches and squads.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget build() {
    return Builder(
      builder: (context) {
        final t = context.midnight;
        return Scaffold(
          backgroundColor: t.voidColor,
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(onBack: _goBack, onHelp: _showHelp, t: t),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      t.pageMargin,
                      24,
                      t.pageMargin,
                      32,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: _buildContent(context, t),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, MidnightTheme t) {
    final validation = state.validation;
    final strength = state.strength;
    final eligibility = validation?.eligibility;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _hero(t),
        SizedBox(height: t.gaps.small),
        _roleSection(t),
        SizedBox(height: t.gaps.medium),
        _field(
          t,
          key: const ValueKey('registration-full-name'),
          label: 'FULL NAME',
          controller: _fullNameController,
          hintText: 'e.g. Leo Messi',
          icon: Icons.badge_outlined,
          field: RegistrationField.fullName,
        ),
        const SizedBox(height: 12),
        _field(
          t,
          key: const ValueKey('registration-date-of-birth'),
          label: 'DATE OF BIRTH',
          controller: _dateOfBirthController,
          hintText: 'DD / MM / YYYY',
          icon: Icons.calendar_today_outlined,
          field: RegistrationField.dateOfBirth,
          keyboardType: TextInputType.datetime,
          suffixLabel: 'DD / MM / YYYY',
        ),
        if (eligibility != null &&
            eligibility.category == EligibilityCategory.youth)
          _statusNotice(
            t,
            label: 'Age: ${eligibility.age} · Youth account',
            detail: 'Your date of birth has been recorded.',
          ),
        const SizedBox(height: 12),
        _phoneField(t),
        const SizedBox(height: 12),
        _field(
          t,
          key: const ValueKey('registration-email'),
          label: 'EMAIL ADDRESS',
          controller: _emailController,
          hintText: 'player@example.com',
          icon: Icons.mail_outline,
          field: RegistrationField.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _passwordField(t, strength),
        const SizedBox(height: 12),
        _safetyNotice(t),
        const SizedBox(height: 12),
        _terms(t),
        if (state.error case final error?) ...[
          const SizedBox(height: 12),
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        _continueButton(t),
        const SizedBox(height: 32),
        _loginHandoff(t),
      ],
    );
  }

  Widget _hero(MidnightTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 6,
              decoration: BoxDecoration(
                color: t.periwinkle,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _label('PLAYER IDENTITY SETUP', t.periwinkle)),
          ],
        ),
        const SizedBox(height: 6),
        Text('CREATE YOUR PLAYER PASS', style: _headline(t, 24)),
        const SizedBox(height: 4),
        Text(
          'Join local 5v5, 7v7 leagues and build your squad.',
          style: _body(t),
        ),
      ],
    );
  }

  Widget _roleSection(MidnightTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _label('SELECT SQUAD ROLE', t.textPrimary)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Primary Match Permission',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: _captionStyle(t.periwinkle),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final role in RegistrationRole.values) ...[
          _RoleCard(
            role: role,
            selected: role == state.role,
            t: t,
            onTap: () => controller.selectRole(role),
          ),
          if (role != RegistrationRole.values.last) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _field(
    MidnightTheme t, {
    required Key key,
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required RegistrationField field,
    TextInputType? keyboardType,
    String? suffixLabel,
  }) {
    final error = state.validation?.errors[field];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: _label(label, t.textPrimary)),
            if (suffixLabel != null) ...[
              const SizedBox(width: 8),
              Flexible(child: _caption(suffixLabel, t.periwinkle)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: error == null ? t.controlHeight : null,
          child: TextField(
            key: key,
            controller: controller,
            onChanged: (_) => _onFieldChanged(
              dateOfBirth: field == RegistrationField.dateOfBirth,
            ),
            keyboardType: keyboardType,
            style: _body(t),
            decoration: _inputDecoration(t, hintText, icon, error),
          ),
        ),
      ],
    );
  }

  Widget _phoneField(MidnightTheme t) {
    final error = state.validation?.errors[RegistrationField.phone];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('MOBILE PHONE', t.textPrimary),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: t.controlHeight,
              width: 96,
              decoration: BoxDecoration(
                color: t.voidColor,
                border: Border.all(color: t.gunmetal),
                borderRadius: BorderRadius.circular(t.cardRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: countryCode.value,
                  isExpanded: true,
                  dropdownColor: t.carbon,
                  style: _body(t),
                  items: const [
                    DropdownMenuItem(value: '+49', child: Text('🇩🇪 +49')),
                    DropdownMenuItem(value: '+351', child: Text('🇵🇹 +351')),
                    DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      countryCode.value = value;
                      controller.fieldsChanged(_input);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                key: const ValueKey('registration-phone'),
                controller: _phoneController,
                onChanged: (_) => _onFieldChanged(),
                keyboardType: TextInputType.phone,
                style: _body(t),
                decoration: _inputDecoration(
                  t,
                  '151 2345 6789',
                  Icons.phone_android,
                  error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _passwordField(MidnightTheme t, PasswordStrength strength) {
    final error = state.validation?.errors[RegistrationField.password];
    final strengthLabel = switch (strength) {
      PasswordStrength.empty => 'Required',
      PasswordStrength.weak => 'Weak',
      PasswordStrength.medium => 'Good',
      PasswordStrength.strong => 'Strong',
    };
    final strengthColor = switch (strength) {
      PasswordStrength.empty ||
      PasswordStrength.weak => const Color(0xFFFFB4AB),
      PasswordStrength.medium => const Color(0xFFFBBF24),
      PasswordStrength.strong => t.periwinkle,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: _label('SECURE PASSWORD', t.textPrimary)),
            const SizedBox(width: 8),
            Flexible(child: _label(strengthLabel.toUpperCase(), strengthColor)),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: error == null ? t.controlHeight : null,
          child: TextField(
            key: const ValueKey('registration-password'),
            controller: _passwordController,
            onChanged: (_) => _onFieldChanged(),
            obscureText: obscurePassword.value,
            style: _body(t),
            decoration:
                _inputDecoration(
                  t,
                  'Create a secure password',
                  Icons.visibility_outlined,
                  error,
                ).copyWith(
                  suffixIcon: IconButton(
                    tooltip: obscurePassword.value
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () =>
                        obscurePassword.value = !obscurePassword.value,
                    icon: Icon(
                      obscurePassword.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: t.periwinkle,
                    ),
                  ),
                ),
          ),
        ),
        const SizedBox(height: 8),
        _strengthMeter(t, strength),
      ],
    );
  }

  Widget _strengthMeter(MidnightTheme t, PasswordStrength strength) {
    final filled = switch (strength) {
      PasswordStrength.empty => 0,
      PasswordStrength.weak => 1,
      PasswordStrength.medium => 2,
      PasswordStrength.strong => 3,
    };
    return Semantics(
      label: 'Password strength: ${strength.name}',
      child: Row(
        children: List.generate(
          3,
          (index) => Expanded(
            child: Container(
              key: ValueKey('password-strength-$index'),
              height: 6,
              margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
              decoration: BoxDecoration(
                color: index < filled
                    ? (index == 2 ? t.periwinkle : t.iris)
                    : t.gunmetal,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusNotice(
    MidnightTheme t, {
    required String label,
    required String detail,
  }) {
    return Container(
      key: const ValueKey('youth-protection-status'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: t.carbon,
        border: Border.all(color: t.gunmetal),
        borderRadius: BorderRadius.circular(t.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: t.periwinkle,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$label\n$detail', style: _captionStyle(t.periwinkle)),
          ),
        ],
      ),
    );
  }

  Widget _safetyNotice(MidnightTheme t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.carbon,
        border: Border.all(color: t.gunmetal),
        borderRadius: BorderRadius.circular(t.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: t.periwinkle, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Players aged 13 and over can join. Phone verification is required.',
              style: _captionStyle(t.frost),
            ),
          ),
        ],
      ),
    );
  }

  Widget _terms(MidnightTheme t) {
    final error = state.validation?.errors[RegistrationField.terms];
    return Semantics(
      checked: acceptedTerms.value,
      label: 'I agree to the Community Code of Conduct and Privacy Policy',
      child: CheckboxListTile(
        key: const ValueKey('registration-terms'),
        value: acceptedTerms.value,
        onChanged: (value) {
          acceptedTerms.value = value ?? false;
          controller.fieldsChanged(_input);
        },
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: t.iris,
        checkColor: t.textPrimary,
        title: Text.rich(
          TextSpan(
            text: 'I agree to the ',
            style: _captionStyle(t.frost),
            children: [
              TextSpan(
                text: 'Community Code of Conduct',
                style: TextStyle(
                  color: t.periwinkle,
                  decoration: TextDecoration.underline,
                ),
              ),
              const TextSpan(text: ' & '),
              TextSpan(
                text: 'Privacy Policy',
                style: TextStyle(
                  color: t.periwinkle,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        subtitle: error == null
            ? null
            : Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
      ),
    );
  }

  Widget _continueButton(MidnightTheme t) {
    final enabled = !state.submitting && !state.submitted;
    return Semantics(
      button: true,
      label: 'Continue to verify',
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: t.controlHeight),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: enabled ? t.ctaGradient : null,
            color: enabled ? null : t.gunmetal,
            borderRadius: BorderRadius.circular(99),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: t.iris.withValues(alpha: .35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            key: const ValueKey('registration-continue'),
            onPressed: enabled ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: t.periwinkle.withValues(alpha: .5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    state.submitting ? 'VERIFYING…' : 'CONTINUE TO VERIFY',
                    textAlign: TextAlign.center,
                    style: _labelStyle(t, Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginHandoff(MidnightTheme t) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text(
            'Already have a player pass? ',
            style: _body(t, color: t.periwinkle),
          ),
          TextButton(
            key: const ValueKey('registration-login'),
            onPressed: widget.onLogin,
            child: Text(
              'Log In',
              style: _labelStyle(
                t,
                t.periwinkle,
              ).copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    MidnightTheme t,
    String hint,
    IconData icon,
    String? error,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _body(t, color: t.periwinkle),
      errorText: error,
      errorMaxLines: 2,
      filled: true,
      fillColor: t.voidColor,
      suffixIcon: Icon(icon, color: t.periwinkle, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.cardRadius),
        borderSide: BorderSide(color: t.gunmetal),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.cardRadius),
        borderSide: BorderSide(color: t.periwinkle),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.cardRadius),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(t.cardRadius),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  TextStyle _headline(MidnightTheme t, double size) => TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: const ['sans-serif'],
    fontSize: size,
    height: 1.33,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * size,
    color: t.textPrimary,
  );

  TextStyle _body(MidnightTheme t, {Color? color}) => TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: const ['sans-serif'],
    fontSize: 14,
    height: 1.43,
    color: color ?? t.frost,
  );

  TextStyle _labelStyle(MidnightTheme t, Color color) => TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: const ['sans-serif'],
    fontSize: 13,
    height: 1.23,
    fontWeight: FontWeight.w700,
    letterSpacing: .52,
    color: color,
  );

  Widget _label(String text, Color color) =>
      Text(text, style: _labelStyle(MidnightTheme.defaults, color));

  TextStyle _captionStyle(Color color) => TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: const ['sans-serif'],
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: .8,
    color: color,
  );

  Widget _caption(String text, Color color) =>
      Text(text, style: _captionStyle(color));
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onHelp, required this.t});

  final VoidCallback onBack;
  final VoidCallback onHelp;
  final MidnightTheme t;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: t.voidColor.withValues(alpha: .95),
        border: Border(bottom: BorderSide(color: t.gunmetal)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('registration-back'),
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onBack,
                  tooltip: 'Go back',
                  icon: Icon(Icons.arrow_back, color: t.textPrimary),
                ),
                Flexible(
                  child: Text(
                    'ShowTime',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: t.carbon,
              border: Border.all(color: t.gunmetal),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'STEP 1 OF 2',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .8,
                  color: t.periwinkle,
                ),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('registration-help'),
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            padding: EdgeInsets.zero,
            onPressed: onHelp,
            tooltip: 'Help and info',
            icon: Icon(Icons.help_outline, color: t.periwinkle),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.t,
    required this.onTap,
  });

  final RegistrationRole role;
  final bool selected;
  final MidnightTheme t;
  final VoidCallback onTap;

  IconData get _icon => switch (role) {
    RegistrationRole.player => Icons.sports_soccer,
    RegistrationRole.squadCaptain => Icons.military_tech,
    RegistrationRole.guardian => Icons.verified_user,
  };

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? t.periwinkle : t.gunmetal;
    return Semantics(
      container: true,
      button: true,
      checked: selected,
      inMutuallyExclusiveGroup: true,
      label:
          '${role.label}. ${role.description}. ${selected ? 'Selected' : 'Not selected'}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('role-${role.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(t.cardRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.carbon,
              borderRadius: BorderRadius.circular(t.cardRadius),
              border: Border.all(color: borderColor),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: t.periwinkle.withValues(alpha: .20),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: t.voidColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.gunmetal),
                  ),
                  child: Icon(
                    _icon,
                    color: selected ? t.periwinkle : t.periwinkle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              role.label,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                color: t.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? t.iris.withValues(alpha: .20)
                                  : t.gunmetal,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              role.badge,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .8,
                                color: selected ? t.periwinkle : t.frost,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role.description,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: t.frost,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  key: ValueKey(
                    'role-indicator-${role.name}-${selected ? 'selected' : 'unselected'}',
                  ),
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: t.periwinkle,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
