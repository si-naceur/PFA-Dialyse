import 'package:go_router/go_router.dart';
import 'package:pfa_dialyse/features/auth/presentation/login_page.dart';
import 'package:pfa_dialyse/features/dashboard/presentation/dashboard_page.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/dashboard', builder: (context, state) => const DashboardPage()),
  ],
);
