import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomeScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget>? children;

  const HomeScreen({
    super.key,
    required this.navigationShell,
    this.children,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.navigationShell.currentIndex,
    );
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
        widget.navigationShell.currentIndex) {
      final targetPage = widget.navigationShell.currentIndex;
      if (_pageController.hasClients &&
          (_pageController.page?.round() ?? -1) != targetPage) {
        _animateOrJumpToPage(targetPage);
      }
    }
  }

  void _animateOrJumpToPage(int index) {
    if (!_pageController.hasClients) return;
    if ((_pageController.page?.round() ?? -1) == index) return;

    if ((index - widget.navigationShell.currentIndex).abs() <= 1) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _pageController.jumpToPage(index);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    final isCurrent = index == widget.navigationShell.currentIndex;
    widget.navigationShell.goBranch(
      index,
      initialLocation: isCurrent,
    );
    if (!isCurrent) {
      _animateOrJumpToPage(index);
    }
  }

  void _onPageChanged(int index) {
    if (index != widget.navigationShell.currentIndex) {
      HapticFeedback.selectionClick();
      widget.navigationShell.goBranch(
        index,
        initialLocation: false,
      );
    }
  }

  void _goToNextTab() {
    final nextIndex = widget.navigationShell.currentIndex + 1;
    final totalPages = widget.children?.length ?? 4;
    if (nextIndex < totalPages) {
      _onItemTapped(nextIndex);
    }
  }

  void _goToPrevTab() {
    final prevIndex = widget.navigationShell.currentIndex - 1;
    if (prevIndex >= 0) {
      _onItemTapped(prevIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = widget.navigationShell.currentIndex;

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
    final inactiveColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF8E8E93);
    final surfaceColor = theme.scaffoldBackgroundColor;
    final location = GoRouterState.of(context).uri.path;
    final isStatementPreview = location == '/statements/preview';

    // Disable tab swiping when in nested detail/editing routes
    final isRootTab = location == '/home' ||
        location == '/transactions' ||
        location == '/statements' ||
        location == '/settings';

    final Widget bodyContent;
    if (widget.children != null && widget.children!.isNotEmpty) {
      bodyContent = PageView(
        controller: _pageController,
        physics: isRootTab
            ? const PageScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        onPageChanged: _onPageChanged,
        children: widget.children!
            .map((child) => _KeepAlivePage(child: child))
            .toList(),
      );
    } else {
      bodyContent = widget.navigationShell;
    }

    return Scaffold(
      extendBody: true,
      body: bodyContent,
      bottomNavigationBar: isStatementPreview
          ? null
          : SafeArea(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  final vx = details.primaryVelocity ?? 0;
                  if (vx < -200) {
                    _goToNextTab();
                  } else if (vx > 200) {
                    _goToPrevTab();
                  }
                },
                child: SizedBox(
                  height: 80,
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
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.45 : 0.08,
                                ),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: gradientColors,
                            ),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: borderColor, width: 0.9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.45 : 0.08,
                                ),
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
                                  onTap: () => _onItemTapped(0),
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
                                  onTap: () => _onItemTapped(1),
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
                                  onTap: () => _onItemTapped(2),
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
                                  onTap: () => _onItemTapped(3),
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
    final icon = isSelected ? activeIcon : inactiveIcon;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: isSelected ? 1.08 : 1, end: 1),
                duration: isSelected
                    ? const Duration(milliseconds: 220)
                    : Duration.zero,
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  child: child,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                    fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
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
            child: Icon(LucideIcons.plus, size: 24, color: buttonFg),
          ),
        ),
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
