import 'package:go_router/go_router.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

class AppRouter {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String patients = '/patients';
  static const String machines = '/machines';
  static const String monitoring = '/monitoring';
  static const String alerts = '/alerts';
  static const String sessions = '/sessions';
  static const String profile = '/profile';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(path: login, builder: (context, state) => const LoginPage()),
      GoRoute(path: profile, builder: (context, state) => const ProfilePage()),
      GoRoute(
        path: dashboard,
        builder: (context, state) =>
            const ProfilePage(), // Temporary fallback until Dashboard is added in Phase 3
      ),
      GoRoute(path: patients, builder: (context, state) => const ProfilePage()),
      GoRoute(path: machines, builder: (context, state) => const ProfilePage()),
      GoRoute(
        path: monitoring,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(path: alerts, builder: (context, state) => const ProfilePage()),
      GoRoute(path: sessions, builder: (context, state) => const ProfilePage()),
    ],
  );
}
