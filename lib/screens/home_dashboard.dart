import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/ambient_glow.dart';
import 'tabs/home_tab.dart';
import 'tabs/analytics_tab.dart';

/// Main application shell hosting the two top-level tabs.
///
/// Layer: UI. Owns the bottom [NavigationBar] and the [PageView] that swaps
/// between [HomeTab] and [AnalyticsTab], plus the shared ambient background.
/// Collaborators: [HomeTab], [AnalyticsTab], [AmbientGlow].
class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  // Currently visible tab index (0 = Home, 1 = Analytics).
  int _currentIndex = 0;
  late PageController _pageController;

  // The two top-level pages. PageStorageKeys preserve each tab's scroll
  // position when the user switches back and forth.
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

  /// Switches to the tab at [index], animating the [PageView] to match.
  void _updateTab(int index) {
    // No-op when tapping the already-selected tab (avoids a redundant animation).
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      // Matches the NavigationBar's own selection transition feel.
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Decorative background halo, offset off the top-right corner so only
          // its lower-left quarter bleeds into view.
          AmbientGlow(
            top: -150,
            right: -100,
            size: 500,
            color: theme.colorScheme.primary,
            centerAlpha: 45,
          ),

          // Tab content. Swipe physics are disabled so the only way to change
          // tabs is the bottom navigation bar (keeps gestures free for content).
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _pages,
          ),
        ],
      ),

      // Bottom navigation. Styling is inherited from AppTheme.navigationBarTheme.
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _updateTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}
