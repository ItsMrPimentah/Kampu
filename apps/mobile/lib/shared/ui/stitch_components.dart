import 'package:flutter/material.dart';

import 'midnight_theme.dart';

class StitchTopBar extends StatelessWidget implements PreferredSizeWidget {
  const StitchTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: onBack != null,
    leading: onBack == null
        ? null
        : IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
    titleSpacing: onBack == null ? 16 : 0,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(
              color: context.midnight.textMuted,
              fontFamily: 'JetBrains Mono',
              fontSize: 10,
            ),
          ),
      ],
    ),
    actions: actions,
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class StitchCard extends StatelessWidget {
  const StitchCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    final content = Padding(padding: padding, child: child);
    final decorated = DecoratedBox(
      decoration: tokens.cardDecoration(color: color),
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: tokens.cardBorderRadius,
              child: content,
            ),
    );
    return Material(color: Colors.transparent, child: decorated);
  }
}

enum StitchStatusTone { neutral, active, success, warning, danger }

class StitchStatusPill extends StatelessWidget {
  const StitchStatusPill({
    super.key,
    required this.label,
    this.tone = StitchStatusTone.neutral,
    this.icon,
  });

  final String label;
  final StitchStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    final color = switch (tone) {
      StitchStatusTone.neutral => tokens.steelLight,
      StitchStatusTone.active => tokens.periwinkle,
      StitchStatusTone.success => tokens.emerald,
      StitchStatusTone.warning => tokens.amber,
      StitchStatusTone.danger => tokens.danger,
    };
    return Semantics(
      container: true,
      label: label,
      child: Container(
        constraints: const BoxConstraints(minHeight: 24),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final labelText = Text(
              label,
              maxLines: constraints.hasBoundedWidth ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            );
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 13, color: color),
                  const SizedBox(width: 4),
                ],
                if (constraints.hasBoundedWidth)
                  Flexible(child: labelText)
                else
                  labelText,
              ],
            );
          },
        ),
      ),
    );
  }
}

class StitchTelemetryBanner extends StatelessWidget {
  const StitchTelemetryBanner({
    super.key,
    required this.title,
    required this.detail,
    this.onRetry,
  });

  final String title;
  final String detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    return StitchCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      color: tokens.carbon,
      child: Row(
        children: [
          Icon(Icons.wifi_off_outlined, size: 16, color: tokens.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                Text(
                  detail,
                  style: tokens.monoStyle.copyWith(
                    color: tokens.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'Retry',
                style: TextStyle(color: tokens.amber, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}

class StitchFilterChip extends StatelessWidget {
  const StitchFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ChoiceChip(
        label: Text(label),
        avatar: icon == null ? null : Icon(icon, size: 15),
        selected: selected,
        onSelected: onSelected,
        selectedColor: tokens.iris,
        backgroundColor: tokens.carbon,
        side: BorderSide(
          color: selected ? tokens.periwinkle : tokens.borderSubtle,
        ),
        labelStyle: TextStyle(
          color: selected ? tokens.textPrimary : tokens.frost,
          fontSize: 12,
        ),
      ),
    );
  }
}

class StitchGradientButton extends StatelessWidget {
  const StitchGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: onPressed == null ? null : tokens.ctaGradient,
            color: onPressed == null ? tokens.gunmetal : null,
            borderRadius: BorderRadius.circular(999),
            boxShadow: onPressed == null
                ? null
                : [
                    BoxShadow(
                      color: tokens.iris.withValues(alpha: 0.32),
                      blurRadius: 18,
                    ),
                  ],
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: onPressed == null
                          ? tokens.textMuted
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      icon,
                      size: 18,
                      color: onPressed == null
                          ? tokens.textMuted
                          : Colors.white,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StitchGhostButton extends StatelessWidget {
  const StitchGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: label,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 16),
      label: Text(label),
      style: context.midnight.secondaryButtonStyle.copyWith(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(44)),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
      ),
    ),
  );
}

class StitchImageFrame extends StatelessWidget {
  const StitchImageFrame({
    super.key,
    required this.assetPath,
    this.height = 96,
    this.label,
  });

  final String assetPath;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    return Semantics(
      image: true,
      label: label ?? 'Local image',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          assetPath,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: height,
            color: tokens.voidColor,
            alignment: Alignment.center,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: tokens.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
