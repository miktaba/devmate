import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/skills/presentation/pages/skills_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/github/presentation/pages/github_repositories_page.dart';
import '../../features/github/presentation/pages/github_repository_details_page.dart';
import '../../features/github/presentation/pages/github_all_todos_page.dart';
import '../../features/github/presentation/pages/github_auth_page.dart';
import '../../features/github/presentation/pages/github_user_info_page.dart';

/// Route names
class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String welcome = '/welcome';
  static const String profile = '/profile';
  static const String skills = '/skills';
  static const String settings = '/settings';
  static const String githubRepositories = '/github/repositories';
  static const String githubRepositoryDetails =
      '/github/repositories/:owner/:name';
  // static const String githubRepositoryTodos =
  //     '/github/repositories/:owner/:name/todos';
  static const String githubAllTodos = '/github/todos';
  static const String githubAuth = '/github/auth';
  static const String githubProfile = '/github/profile';
}

/// Router configuration
final appRouter = GoRouter(
  initialLocation: AppRoutes.welcome,
  debugLogDiagnostics: true,

  // Redirecttfunctionrforcprotectingoroutes
  redirect: (context, state) {
    // Get theccurrentaauthenticationtstate
    final authState = ProviderScope.containerOf(context).read(authProvider);

    // Determine if the user is authorized and is on the login or welcome page
    final isAuth = authState.value != null;
    final isLoginRoute = state.matchedLocation == AppRoutes.login;
    final isWelcomeRoute = state.matchedLocation == AppRoutes.welcome;
    final isPublicRoute = isLoginRoute || isWelcomeRoute;

    if (kDebugMode) {
      print('GoRouter redirect:');
      print('  - Current path: ${state.matchedLocation}');
      print('  - User is authorized: $isAuth');
      print('  - Is on login page: $isLoginRoute');
      print('  - Is on welcome page: $isWelcomeRoute');
      print('  - Auth state: $authState');
      print('  - Auth value: ${authState.value?.email}');
    }

    // If the user is not authorized and tries to access a protected route
    if (!isAuth && !isPublicRoute) {
      if (kDebugMode) {
        print('Redirecting to welcome (user not authorized)');
      }
      return AppRoutes.welcome;
    }

    // If the user is authorized, but is on the login or welcome page
    if (isAuth && isPublicRoute) {
      if (kDebugMode) {
        print('Redirecting to home (user already authorized)');
      }
      return AppRoutes.home;
    }

    // In all other cases, do not change the route
    if (kDebugMode) {
      print('No redirect');
    }
    return null;
  },

  // Determining the application routes
  routes: [
    // Welcome page (public)
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomePage(),
    ),

    // Main page (protected, requires authorization)
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomePage(),
    ),

    // Login/registration page
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),

    // Profile page (protected)
    GoRoute(
      path: AppRoutes.profile,
      builder:
          (context, state) => CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(
              middle: Text('Profile'),
            ),
            child: const Center(child: Text('Profile page')),
          ),
    ),

    // Skills page (protected)
    GoRoute(
      path: AppRoutes.skills,
      builder: (context, state) => const SkillsPage(),
    ),

    // Settings page (protected)
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),

    // GitHub repositories page (protected)
    GoRoute(
      path: AppRoutes.githubRepositories,
      builder: (context, state) => const GithubRepositoriesPage(),
    ),

    // GitHub repository details page (protected)
    GoRoute(
      path: AppRoutes.githubRepositoryDetails,
      builder: (context, state) {
        final owner = state.pathParameters['owner'] ?? '';
        final name = state.pathParameters['name'] ?? '';
        final tabParam = state.uri.queryParameters['tab'];
        final initialTabIndex =
            tabParam != null ? int.tryParse(tabParam) ?? 0 : 0;
        return GithubRepositoryDetailsPage(
          owner: owner,
          name: name,
          initialTabIndex: initialTabIndex,
        );
      },
    ),

    // GitHub all todos page
    GoRoute(
      path: AppRoutes.githubAllTodos,
      builder: (context, state) => const GithubAllTodosPage(),
    ),

    // GitHub auth page
    GoRoute(
      path: AppRoutes.githubAuth,
      builder: (context, state) => const GitHubAuthPage(),
    ),

    // GitHub profile page
    GoRoute(
      path: AppRoutes.githubProfile,
      builder: (context, state) => const GitHubUserInfoPage(),
    ),
  ],

  // Error handling for routing
  errorBuilder: (context, state) {
    if (kDebugMode) {
      print('Routing error: ${state.error}');
    }
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Routing error'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              size: 64,
              color: CupertinoColors.systemYellow,
            ),
            const SizedBox(height: 16),
            const Text(
              'Page not found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Route: ${state.matchedLocation}',
              style: const TextStyle(color: CupertinoColors.systemGrey),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Return to main'),
            ),
          ],
        ),
      ),
    );
  },
);
