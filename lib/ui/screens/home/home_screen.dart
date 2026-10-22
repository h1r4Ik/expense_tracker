import 'dart:ui';
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

    final navBackground = isDark
        ? const Color(0xFF121212).withValues(alpha: 0.72)
        : Colors.white.withValues(alpha: 0.78);
    final borderColor = isDark
        ? const Color(0xFFFFFFFF).withValues(alpha: 0.12)
        : const Color(0xFF000000).withValues(alpha: 0.08);
    final activeColor = isDark ? Colors.white : Colors.black;
    final inactiveColor = isDark ? const Color(0xFF7E7E7E) : const Color(0xFF8E8E93);

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: navBackground,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                      blurRadius: 28,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Tab 0: Home
                    Expanded(
                      child: _NavButton(
                        icon: LucideIcons.house,
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
                        icon: LucideIcons.clipboardList,
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
                        icon: LucideIcons.fileText,
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
                        icon: LucideIcons.user,
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
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
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
            width: 44,
            height: 44,
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
              size: 22,
              color: buttonFg,
            ),
          ),
        ),
      ),
    );
  }
}
