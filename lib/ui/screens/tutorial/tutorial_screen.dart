import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/providers/auth_provider.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_TutorialPageData> _pages = const [
    _TutorialPageData(
      icon: LucideIcons.wallet,
      title: 'Welcome to Expense Tracker',
      description:
          'Track every rupee with clarity, elegance, and complete privacy on your device.',
    ),
    _TutorialPageData(
      icon: LucideIcons.circlePlus,
      title: 'Quick & Seamless',
      description:
          'Log expenses and incomes effortlessly with smart categories and payment tagging.',
    ),
    _TutorialPageData(
      icon: LucideIcons.clipboardList,
      title: 'Analyze & Organize',
      description:
          'View transactions grouped by day, week, month, or year with instant subtotals.',
    ),
    _TutorialPageData(
      icon: LucideIcons.fileText,
      title: 'Export Statements',
      description:
          'Generate and preview clean, professional PDF statements for any customized date range.',
    ),
    _TutorialPageData(
      icon: LucideIcons.users,
      title: 'Group Sharing',
      description:
          'Collaborate on shared expenses with offline-first synchronization across members.',
    ),
    _TutorialPageData(
      icon: LucideIcons.circleCheck,
      title: "You're All Set",
      description:
          'Start managing your finances with confidence and complete control.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishTutorial() async {
    final auth = context.read<AuthProvider>();
    await auth.completeTutorial();
    if (mounted) {
      context.go('/home');
    }
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishTutorial();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (!isLastPage)
            TextButton(
              onPressed: _finishTutorial,
              child: Text(
                'Skip',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.lightSurfaceVariant,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            page.icon,
                            size: 64,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          page.title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicator Dots & Next Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) {
                        final isSelected = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isSelected ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isSelected
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      child: Text(isLastPage ? 'Get Started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialPageData {
  final IconData icon;
  final String title;
  final String description;

  const _TutorialPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
