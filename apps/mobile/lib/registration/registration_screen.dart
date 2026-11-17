import 'dart:async';

import 'package:flutter/material.dart';

import '../core/auth/auth_repository.dart';
import '../onboarding/eligibility.dart';
import 'pitch_pulse_theme.dart';
import 'registration_models.dart';
import 'registration_validation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.onContinue,
    this.onBack,
    this.onHelp,
    this.onLogin,
    this.onRegister,
  });

  final FutureOr<void> Function(RegistrationSubmission submission) onContinue;
  final Future<AuthResult> Function(RegistrationSubmission submission)?
  onRegister;
  final VoidCallback? onBack;
  final VoidCallback? onHelp;
  final VoidCallback? onLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  RegistrationRole _role = RegistrationRole.player;
  String _countryCode = '+351';
  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _hasSubmitted = false;
  bool _submitting = false;
  bool _submitted = false;
  String? _submitError;
  RegistrationValidationResult? _validation;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _selectRole(RegistrationRole role) {
    setState(() => _role = role);
  }

  RegistrationValidationResult _validate() {
    final result = validateRegistration(
      fullName: _fullNameController.text,
      dateOfBirth: _dateOfBirthController.text,
      phone: '$_countryCode ${_phoneController.text}',
      email: _emailController.text,
      password: _passwordController.text,
      acceptedTerms: _acceptedTerms,
    );
    _validation = result;
    return result;
  }

  void _updateEligibilityPreview() {
    final normalizedDate = normalizeDateOfBirth(_dateOfBirthController.text);
    if (normalizedDate == null) {
      if (_validation?.eligibility != null) {
        setState(() => _validation = null);
      }
      return;
    }

    try {
      final eligibility = evaluateEligibility(normalizedDate);
      setState(() {
        _validation = RegistrationValidationResult(
          errors: _validation?.errors ?? const {},
          passwordStrength: passwordStrength(_passwordController.text),
          eligibility: eligibility,
        );
      });
    } on EligibilityValidationException {
      if (_validation?.eligibility != null) setState(() => _validation = null);
    }
  }

  void _onFieldChanged({bool dateOfBirth = false}) {
    if (dateOfBirth) _updateEligibilityPreview();
    if (_hasSubmitted) setState(_validate);
  }

  Future<void> _submit() async {
    if (_submitting || _submitted) return;

    setState(() {
      _hasSubmitted = true;
      _submitError = null;
    });
    final result = _validate();
    if (!result.isValid) {
      setState(() {});
      return;
    }

    final normalizedDate = normalizeDateOfBirth(_dateOfBirthController.text);
    final eligibility = result.eligibility;
    if (normalizedDate == null || eligibility == null) return;
    final submission = RegistrationSubmission(
      role: _role,
      fullName: _fullNameController.text.trim(),
      dateOfBirth: normalizedDate,
      phone: '$_countryCode ${_phoneController.text.trim()}',
      email: _emailController.text.trim(),
      password: _passwordController.text,
      eligibility: eligibility,
    );

    setState(() {
      _submitting = true;
      _submitted = true;
    });
    try {
      final onRegister = widget.onRegister;
      if (onRegister == null) {
        await widget.onContinue(submission);
      } else {
        final response = await onRegister(submission);
        if (!mounted) return;
        response.when(
          val: (_) {},
          err: (_) => setState(() {
            _submitted = false;
            _submitError = 'We could not continue. Please try again.';
          }),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitted = false;
          _submitError = 'We could not continue. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _goBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _showHelp() {
    if (widget.onHelp != null) {
      widget.onHelp!();
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

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: PitchPulseThemeData.apply(Theme.of(context)),
      child: Builder(
        builder: (context) {
          final tokens = Theme.of(context).extension<PitchPulseTheme>()!;
          return Scaffold(
            backgroundColor: tokens.voidColor,
            body: SafeArea(
              child: Column(
                children: [
                  _TopBar(onBack: _goBack, onHelp: _showHelp, tokens: tokens),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        tokens.pageMargin,
                        24,
                        tokens.pageMargin,
                        32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 430),
                          child: _buildContent(context, tokens),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PitchPulseTheme tokens) {
    final validation = _validation;
    final strength =
        validation?.passwordStrength ??
        passwordStrength(_passwordController.text);
    final eligibility = validation?.eligibility;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _hero(tokens),
        SizedBox(height: tokens.sectionGap),
        _roleSection(tokens),
        SizedBox(height: tokens.sectionGap),
        _field(
          tokens,
          key: const ValueKey('registration-full-name'),
          label: 'FULL NAME',
          controller: _fullNameController,
          hintText: 'e.g. Leo Messi',
          icon: Icons.badge_outlined,
          field: RegistrationField.fullName,
        ),
        const SizedBox(height: 12),
        _field(
          tokens,
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
            tokens,
            label: 'Age: ${eligibility.age} · Youth account',
            detail: 'Your date of birth has been recorded.',
          ),
        const SizedBox(height: 12),
        _phoneField(tokens),
        const SizedBox(height: 12),
        _field(
          tokens,
          key: const ValueKey('registration-email'),
          label: 'EMAIL ADDRESS',
          controller: _emailController,
          hintText: 'player@pitchpulse.fc',
          icon: Icons.mail_outline,
          field: RegistrationField.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _passwordField(tokens, strength),
        const SizedBox(height: 12),
        _safetyNotice(tokens),
        const SizedBox(height: 12),
        _terms(tokens),
        if (_submitError != null) ...[
          const SizedBox(height: 12),
          Text(
            _submitError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        _continueButton(tokens),
        const SizedBox(height: 32),
        _loginHandoff(tokens),
      ],
    );
  }

  Widget _hero(PitchPulseTheme tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 6,
              decoration: BoxDecoration(
                color: tokens.periwinkle,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 8),
            _label('PLAYER IDENTITY SETUP', tokens.mutedSteel),
          ],
        ),
        const SizedBox(height: 6),
        Text('CREATE YOUR PLAYER PASS', style: _headline(tokens, 24)),
        const SizedBox(height: 4),
        Text(
          'Join local 5v5, 7v7 leagues and build your squad.',
          style: _body(tokens),
        ),
      ],
    );
  }

  Widget _roleSection(PitchPulseTheme tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _label('SELECT SQUAD ROLE', tokens.textPrimary)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Primary Match Permission',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: _captionStyle(tokens.mutedSteel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final role in RegistrationRole.values) ...[
          _RoleCard(
            role: role,
            selected: role == _role,
            tokens: tokens,
            onTap: () => _selectRole(role),
          ),
          if (role != RegistrationRole.values.last) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _field(
    PitchPulseTheme tokens, {
    required Key key,
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required RegistrationField field,
    TextInputType? keyboardType,
    String? suffixLabel,
  }) {
    final error = _validation?.errors[field];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label(label, tokens.textPrimary),
            if (suffixLabel != null) _caption(suffixLabel, tokens.mutedSteel),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: error == null ? tokens.controlHeight : null,
          child: TextField(
            key: key,
            controller: controller,
            onChanged: (_) => _onFieldChanged(
              dateOfBirth: field == RegistrationField.dateOfBirth,
            ),
            keyboardType: keyboardType,
            style: _body(tokens),
            decoration: _inputDecoration(tokens, hintText, icon, error),
          ),
        ),
      ],
    );
  }

  Widget _phoneField(PitchPulseTheme tokens) {
    final error = _validation?.errors[RegistrationField.phone];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('MOBILE PHONE', tokens.textPrimary),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: tokens.controlHeight,
              width: 96,
              decoration: BoxDecoration(
                color: tokens.voidColor,
                border: Border.all(color: tokens.gunmetal),
                borderRadius: BorderRadius.circular(tokens.fieldRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _countryCode,
                  isExpanded: true,
                  dropdownColor: tokens.carbon,
                  style: _body(tokens),
                  items: const [
                    DropdownMenuItem(value: '+49', child: Text('🇩🇪 +49')),
                    DropdownMenuItem(value: '+351', child: Text('🇵🇹 +351')),
                    DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _countryCode = value);
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
                style: _body(tokens),
                decoration: _inputDecoration(
                  tokens,
                  '151 2345 6789',
                  Icons.check_circle_outline,
                  error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _passwordField(PitchPulseTheme tokens, PasswordStrength strength) {
    final error = _validation?.errors[RegistrationField.password];
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
      PasswordStrength.strong => tokens.periwinkle,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label('SECURE PASSWORD', tokens.textPrimary),
            _label(strengthLabel.toUpperCase(), strengthColor),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: error == null ? tokens.controlHeight : null,
          child: TextField(
            key: const ValueKey('registration-password'),
            controller: _passwordController,
            onChanged: (_) => _onFieldChanged(),
            obscureText: _obscurePassword,
            style: _body(tokens),
            decoration:
                _inputDecoration(
                  tokens,
                  'Create a secure password',
                  Icons.visibility_outlined,
                  error,
                ).copyWith(
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: tokens.mutedSteel,
                    ),
                  ),
                ),
          ),
        ),
        const SizedBox(height: 8),
        _strengthMeter(tokens, strength),
      ],
    );
  }

  Widget _strengthMeter(PitchPulseTheme tokens, PasswordStrength strength) {
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
                    ? (index == 2 ? tokens.periwinkle : tokens.iris)
                    : tokens.gunmetal,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusNotice(
    PitchPulseTheme tokens, {
    required String label,
    required String detail,
  }) {
    return Container(
      key: const ValueKey('youth-protection-status'),
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: tokens.carbon,
        border: Border.all(color: tokens.gunmetal),
        borderRadius: BorderRadius.circular(tokens.fieldRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: tokens.periwinkle,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label\n$detail',
              style: _captionStyle(tokens.periwinkle),
            ),
          ),
        ],
      ),
    );
  }

  Widget _safetyNotice(PitchPulseTheme tokens) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.carbon,
        border: Border.all(color: tokens.gunmetal),
        borderRadius: BorderRadius.circular(tokens.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: tokens.periwinkle, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Players aged 13 and over can join. Phone verification is required.',
              style: _captionStyle(tokens.frost),
            ),
          ),
        ],
      ),
    );
  }

  Widget _terms(PitchPulseTheme tokens) {
    final error = _validation?.errors[RegistrationField.terms];
    return Semantics(
      checked: _acceptedTerms,
      label: 'I agree to the Community Code of Conduct and Privacy Policy',
      child: CheckboxListTile(
        key: const ValueKey('registration-terms'),
        value: _acceptedTerms,
        onChanged: (value) {
          setState(() {
            _acceptedTerms = value ?? false;
            if (_hasSubmitted) _validate();
          });
        },
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: tokens.iris,
        checkColor: tokens.textPrimary,
        title: Text.rich(
          TextSpan(
            text: 'I agree to the ',
            style: _captionStyle(tokens.frost),
            children: [
              TextSpan(
                text: 'Community Code of Conduct',
                style: TextStyle(
                  color: tokens.periwinkle,
                  decoration: TextDecoration.underline,
                ),
              ),
              const TextSpan(text: ' & '),
              TextSpan(
                text: 'Privacy Policy',
                style: TextStyle(
                  color: tokens.periwinkle,
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

  Widget _continueButton(PitchPulseTheme tokens) {
    final enabled = !_submitting && !_submitted;
    return Semantics(
      button: true,
      label: 'Continue to verify',
      child: SizedBox(
        height: tokens.controlHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: enabled ? tokens.ctaGradient : null,
            color: enabled ? null : tokens.gunmetal,
            borderRadius: BorderRadius.circular(99),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: tokens.iris.withValues(alpha: .35),
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
              disabledForegroundColor: tokens.mutedSteel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _submitting ? 'VERIFYING…' : 'CONTINUE TO VERIFY',
                  style: _labelStyle(tokens, Colors.white),
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

  Widget _loginHandoff(PitchPulseTheme tokens) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          Text(
            'Already have a player pass? ',
            style: _body(tokens, color: tokens.mutedSteel),
          ),
          GestureDetector(
            key: const ValueKey('registration-login'),
            onTap: widget.onLogin,
            child: Text(
              'Log In',
              style: _labelStyle(
                tokens,
                tokens.periwinkle,
              ).copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    PitchPulseTheme tokens,
    String hint,
    IconData icon,
    String? error,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _body(tokens, color: tokens.mutedSteel),
      errorText: error,
      errorMaxLines: 2,
      filled: true,
      fillColor: tokens.voidColor,
      suffixIcon: Icon(icon, color: tokens.mutedSteel, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.fieldRadius),
        borderSide: BorderSide(color: tokens.gunmetal),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.fieldRadius),
        borderSide: BorderSide(color: tokens.periwinkle),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.fieldRadius),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.fieldRadius),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  TextStyle _headline(PitchPulseTheme tokens, double size) => TextStyle(
    fontFamily: 'Space Grotesk',
    fontFamilyFallback: const ['Inter', 'sans-serif'],
    fontSize: size,
    height: 1.33,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * size,
    color: tokens.textPrimary,
  );

  TextStyle _body(PitchPulseTheme tokens, {Color? color}) => TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: const ['sans-serif'],
    fontSize: 14,
    height: 1.43,
    color: color ?? tokens.frost,
  );

  TextStyle _labelStyle(PitchPulseTheme tokens, Color color) => TextStyle(
    fontFamily: 'Space Grotesk',
    fontFamilyFallback: const ['Inter', 'sans-serif'],
    fontSize: 13,
    height: 1.23,
    fontWeight: FontWeight.w700,
    letterSpacing: .52,
    color: color,
  );

  Widget _label(String text, Color color) =>
      Text(text, style: _labelStyle(PitchPulseTheme.defaults, color));

  TextStyle _captionStyle(Color color) => TextStyle(
    fontFamily: 'Space Grotesk',
    fontFamilyFallback: const ['Inter', 'sans-serif'],
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
  const _TopBar({
    required this.onBack,
    required this.onHelp,
    required this.tokens,
  });

  final VoidCallback onBack;
  final VoidCallback onHelp;
  final PitchPulseTheme tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: tokens.voidColor.withValues(alpha: .95),
        border: Border(bottom: BorderSide(color: tokens.gunmetal)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  key: const ValueKey('registration-back'),
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: onBack,
                  tooltip: 'Go back',
                  icon: Icon(Icons.arrow_back, color: tokens.textPrimary),
                ),
                Flexible(
                  child: Text(
                    'Pitch Pulse',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
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
              color: tokens.carbon,
              border: Border.all(color: tokens.gunmetal),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'STEP 1 OF 2',
                style: TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .8,
                  color: tokens.periwinkle,
                ),
              ),
            ),
          ),
          IconButton(
            key: const ValueKey('registration-help'),
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            padding: EdgeInsets.zero,
            onPressed: onHelp,
            tooltip: 'Help and info',
            icon: Icon(Icons.help_outline, color: tokens.mutedSteel),
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
    required this.tokens,
    required this.onTap,
  });

  final RegistrationRole role;
  final bool selected;
  final PitchPulseTheme tokens;
  final VoidCallback onTap;

  IconData get _icon => switch (role) {
    RegistrationRole.player => Icons.sports_soccer,
    RegistrationRole.squadCaptain => Icons.military_tech,
    RegistrationRole.guardian => Icons.verified_user,
  };

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? tokens.periwinkle : tokens.gunmetal;
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
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.carbon,
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              border: Border.all(color: borderColor),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: tokens.periwinkle.withValues(alpha: .20),
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
                    color: tokens.voidColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: tokens.gunmetal),
                  ),
                  child: Icon(
                    _icon,
                    color: selected ? tokens.periwinkle : tokens.mutedSteel,
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
                                color: tokens.textPrimary,
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
                                  ? tokens.iris.withValues(alpha: .20)
                                  : tokens.gunmetal,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              role.badge,
                              style: TextStyle(
                                fontFamily: 'Space Grotesk',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .8,
                                color: selected
                                    ? tokens.periwinkle
                                    : tokens.frost,
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
                          color: tokens.frost,
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
                              color: tokens.periwinkle,
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
