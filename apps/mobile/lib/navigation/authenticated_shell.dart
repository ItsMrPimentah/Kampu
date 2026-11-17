import 'package:flutter/material.dart';

import '../core/auth/auth_repository.dart';
import '../theme/midnight_theme.dart';
import '../theme/stitch_assets.dart';
import 'navigation_controller.dart';

class AuthenticatedShell extends StatelessWidget {
  const AuthenticatedShell({
    super.key,
    required this.child,
    required this.navigation,
    this.onSignOut,
  });

  final Widget child;
  final NavigationController navigation;
  final Future<AuthResult> Function()? onSignOut;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: navigation,
    builder: (context, _) => Scaffold(
      body: SafeArea(bottom: false, child: child),
      floatingActionButton: onSignOut == null
          ? null
          : Semantics(
              label: 'Sign out',
              child: FloatingActionButton.small(
                tooltip: 'Sign out',
                onPressed: () async {
                  final result = await onSignOut?.call();
                  if (!context.mounted) return;
                  result?.when(
                    val: (_) {},
                    err: (_) => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to sign out. Please try again.'),
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.logout),
              ),
            ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: _StitchNavigationDock(navigation: navigation),
      ),
    ),
  );
}

class _StitchNavigationDock extends StatelessWidget {
  const _StitchNavigationDock({required this.navigation});

  final NavigationController navigation;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    const labels = ['Discover', 'Challenges', 'Pitches', 'Squad'];
    const icons = [
      StitchAssets.discoverIcon,
      StitchAssets.challengesIcon,
      StitchAssets.pitchesIcon,
      StitchAssets.squadIcon,
    ];
    return Material(
      color: Colors.transparent,
      child: Container(
        key: const ValueKey('stitch-navigation-dock'),
        height: 68,
        constraints: const BoxConstraints(maxWidth: 430),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: tokens.carbon.withValues(alpha: 0.97),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: tokens.borderSubtle),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(
            labels.length,
            (index) => Expanded(
              child: _DockDestination(
                label: labels[index],
                icon: icons[index],
                selected: navigation.selectedIndex == index,
                onTap: () => navigation.goToDestination(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockDestination extends StatelessWidget {
  const _DockDestination({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.midnight;
    final color = selected ? Colors.white : tokens.steelLight;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: selected
                ? BoxDecoration(
                    gradient: tokens.ctaGradient,
                    borderRadius: BorderRadius.circular(999),
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: selected ? Colors.white : color),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (selected)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
