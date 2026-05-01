import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tabs/home_tab.dart';
import 'tabs/analytics_tab.dart';

/// Extremely lightweight shell for the main application entry point.
/// Manages Bottom Navigation and the core background ambiance.
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _pages = const [
    HomeTab(key: PageStorageKey('home_tab')),
    AnalyticsTab(key: PageStorageKey('analytics_tab')),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _updateTab(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          // --- AMBIENT GLOW SYSTEM (GPU OPTIMIZED) ---
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withAlpha(45), // Luminous center
                    theme.colorScheme.primary.withAlpha(0), // Fades to nothing
                  ],
                  stops: const [0.2, 1.0],
                ),
              ),
            ),
          ),

          // --- TAB VIEWS ---
          PageView(
            controller: _pageController,
            physics:
                const NeverScrollableScrollPhysics(), // Prevents swipe-to-change
            children: _pages,
          ),
        ],
      ),

      // --- NAVIGATION BAR ---
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: theme.colorScheme.surface,
        elevation: 8,
        shadowColor: Colors.black,
        indicatorColor: theme.colorScheme.primary.withAlpha(38),
        onDestinationSelected: _updateTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}
