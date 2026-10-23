import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomeScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeScreen({super.key, required this.navigationShell});

  void _onItemTapped(BuildContext context, int index) {
    HapticFeedback.lightImpact();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = navigationShell.currentIndex;

    final gradientColors = isDark
        ? [
            const Color(0xFF28282D).withValues(alpha: 0.88),
            const Color(0xFF141416).withValues(alpha: 0.86),
          ]
        : [
            Colors.white.withValues(alpha: 0.92),
            const Color(0xFFF6F7F9).withValues(alpha: 0.84),
            const Color(0xFFECEEF2).withValues(alpha: 0.88),
          ];

    final borderColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.12)
        : const Color(0xFF000000).withValues(alpha: 0.08);
    final activeColor = isDark ? Colors.white : Colors.black;
    final inactiveColor = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
    final surfaceColor = theme.scaffoldBackgroundColor;
    final isStatementPreview = GoRouterState.of(context).uri.path == '/statements/preview';

    return Scaffold(
      
      extendBody: true,
      body: navigationShell,
        bottomNavigationBar: isStatementPreview
          ? null
          : SafeArea(
        child: SizedBox(
          height: 90,
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          surfaceColor.withValues(alpha: 0.0),
                          surfaceColor.withValues(alpha: 0.72),
                          surfaceColor,
                        ],
                        
                        stops: const [0.0, 0.52, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, -2),
                        ),
                      ]
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: Container(
                    height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(color: borderColor, width: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                      blurRadius: 32,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                  child: Row(
                  children: [
                    // Tab 0: Home / Dashboard
                    Expanded(
                      child: _NavButton(
                        inactiveIcon: LucideIcons.house,
                        activeIcon: LucideIcons.house,
                        label: 'Home',
                        isSelected: currentIndex == 0,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        onTap: () => _onItemTapped(context, 0),
                      ),
                    ),

                    // Tab 1: Log
                    Expanded(
                      child: _NavButton(
                        inactiveIcon: LucideIcons.clipboardList,
                        activeIcon: LucideIcons.clipboardCheck,
                        label: 'Log',
                        isSelected: currentIndex == 1,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        onTap: () => _onItemTapped(context, 1),
                      ),
                    ),

                    // Center Action Button: Add Transaction
                    Expanded(
                      child: _CenterAddButton(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.push('/add-transaction');
                        },
                      ),
                    ),

                    // Tab 2: Statements
                    Expanded(
                      child: _NavButton(
                        inactiveIcon: LucideIcons.fileText,
                        activeIcon: LucideIcons.fileText,
                        label: 'Statements',
                        isSelected: currentIndex == 2,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        onTap: () => _onItemTapped(context, 2),
                      ),
                    ),

                    // Tab 3: Settings / Profile
                    Expanded(
                      child: _NavButton(
                        inactiveIcon: LucideIcons.userRound,
                        activeIcon: LucideIcons.userRound,
                        label: 'Profile',
                        isSelected: currentIndex == 3,
                        activeColor: activeColor,
                        inactiveColor: inactiveColor,
                        onTap: () => _onItemTapped(context, 3),
                      ),
                    ),
                  ],
                    ),
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

class _NavButton extends StatelessWidget {
  final IconData inactiveIcon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;
  final IconData activeIcon;

  const _NavButton({
    required this.inactiveIcon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;
    final icon = isSelected ? activeIcon : inactiveIcon; // You can change the icon if needed for selected state
    return Material(
      color: Colors.transparent,
      child: 
      InkWell(
        onTap: onTap,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: color,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                  letterSpacing: 0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CenterAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final buttonBg = isDark ? Colors.white : Colors.black;
    final buttonFg = isDark ? Colors.black : Colors.white;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: buttonBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: buttonBg.withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              LucideIcons.plus,
              size: 24,
              color: buttonFg,
            ),
          ),
        ),
      ),
    );
  }
}
