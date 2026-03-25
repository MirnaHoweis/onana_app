import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/projects/projects_screen.dart';
import '../../features/projects/project_detail_screen.dart';
import '../../features/units/unit_detail_screen.dart';
import '../../features/requests/requests_screen.dart';
import '../../features/requests/request_detail_screen.dart';
import '../../features/installations/installation_detail_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/email/email_screen.dart';
import '../../features/ai_assistant/ai_screen.dart';
import '../../features/installations/installations_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../layout/mobile_shell.dart';
import '../layout/web_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  refreshListenable: routerRefreshNotifier,
  redirect: (context, state) {
    final authStatus = _currentAuthStatus();
    final isLoginRoute = state.matchedLocation == '/login';

    // Still initializing — stay put
    if (authStatus == AuthStatus.unknown) return null;

    // Not authenticated → send to login
    if (authStatus == AuthStatus.unauthenticated && !isLoginRoute) {
      return '/login';
    }

    // Authenticated and on login → send to dashboard
    if (authStatus == AuthStatus.authenticated && isLoginRoute) {
      return '/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    if (kIsWeb) _webShellRoute else _mobileShellRoute,
  ],
);

/// Reads the latest auth status synchronously from the notifier value.
/// The value is incremented every time auth state changes, so the router
/// re-evaluates redirect after each change.
AuthStatus _currentAuthStatus() {
  // We derive status from SharedPreferences indirectly — the notifier
  // increments on every auth state change, but we need the actual status.
  // We store it in a global that AuthNotifier updates.
  return _lastKnownAuthStatus;
}

AuthStatus _lastKnownAuthStatus = AuthStatus.unknown;

/// Called by AuthNotifier to keep the router's view of auth in sync.
void updateRouterAuthStatus(AuthStatus status) {
  _lastKnownAuthStatus = status;
}

final _mobileShellRoute = ShellRoute(
  builder: (context, state, child) => MobileShell(child: child),
  routes: _mobileRoutes,
);

final _webShellRoute = ShellRoute(
  builder: (context, state, child) => WebShell(child: child),
  routes: [..._mobileRoutes, ..._webOnlyRoutes],
);

final _mobileRoutes = [
  GoRoute(
    path: '/dashboard',
    builder: (context, state) => const DashboardScreen(),
  ),
  GoRoute(
    path: '/projects',
    builder: (context, state) => const ProjectsScreen(),
    routes: [
      GoRoute(
        path: ':projectId',
        builder: (context, state) => ProjectDetailScreen(
          projectId: state.pathParameters['projectId']!,
        ),
        routes: [
          GoRoute(
            path: 'units/:unitId',
            builder: (context, state) => UnitDetailScreen(
              projectId: state.pathParameters['projectId']!,
              unitId: state.pathParameters['unitId']!,
            ),
          ),
        ],
      ),
    ],
  ),
  GoRoute(
    path: '/requests',
    builder: (context, state) => const RequestsScreen(),
    routes: [
      GoRoute(
        path: ':requestId',
        builder: (context, state) => RequestDetailScreen(
          requestId: state.pathParameters['requestId']!,
        ),
      ),
    ],
  ),
  GoRoute(
    path: '/notes',
    builder: (context, state) => const NotesScreen(),
  ),
  GoRoute(
    path: '/notifications',
    builder: (context, state) => const NotificationsScreen(),
  ),
  GoRoute(
    path: '/profile',
    builder: (context, state) => const ProfileScreen(),
  ),
];

final _webOnlyRoutes = [
  GoRoute(
    path: '/pipeline',
    builder: (context, state) => const RequestsScreen(),
  ),
  GoRoute(
    path: '/installations',
    builder: (context, state) => const InstallationsScreen(),
    routes: [
      GoRoute(
        path: ':installationId',
        builder: (context, state) => InstallationDetailScreen(
          installationId: state.pathParameters['installationId']!,
        ),
      ),
    ],
  ),
  GoRoute(
    path: '/email',
    builder: (context, state) => const EmailScreen(),
  ),
  GoRoute(
    path: '/ai',
    builder: (context, state) => const AiScreen(),
  ),
  GoRoute(
    path: '/settings',
    builder: (context, state) => const SettingsScreen(),
  ),
];
