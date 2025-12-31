import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/tab_main_screen.dart';
import '../ui/tab_swipe_screen.dart';
import '../ui/tab_history_screen.dart';
import '../ui/artwork_detail_screen.dart';
import '../model/artwork.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/search',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(index),
            selectedItemColor: const Color(0xFF409EFF),
            unselectedItemColor: const Color(0xFF666666),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
              BottomNavigationBarItem(icon: Icon(Icons.swipe), label: 'Swipe'),
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            ],
          ),
        );
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKey,
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const TabMainScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/swipe',
              builder: (context, state) => const TabSwipeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const TabHistoryScreen(),
            ),
          ],
        ),
      ],
    ),
    // 详情页在 ShellRoute 之外，可以全屏覆盖
    GoRoute(
      path: '/detail',
      parentNavigatorKey: _rootNavigatorKey, // 确保覆盖底部 TabBar
      builder: (context, state) {
        final artwork = state.extra as Artwork;
        return ArtworkDetailScreen(artwork: artwork);
      },
    ),
  ],
);