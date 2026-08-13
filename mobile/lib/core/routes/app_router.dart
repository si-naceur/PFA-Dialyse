import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts_history/presentation/pages/alerts_history_page.dart';
import '../../features/authentication/domain/entities/user_entity.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/machines/presentation/pages/machine_detail_page.dart';
import '../../features/machines/presentation/pages/machines_page.dart';
import '../../features/monitoring/presentation/pages/monitoring_page.dart';
import '../../features/patients/presentation/pages/patient_detail_page.dart';
import '../../features/patients/presentation/pages/patient_edit_page.dart';
import '../../features/patients/presentation/pages/patients_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/seances/presentation/pages/post_session_page.dart';
import '../../features/seances/presentation/pages/pre_session_page.dart';
import '../../features/seances/presentation/pages/seances_page.dart';
import '../../features/seances/presentation/pages/session_detail_page.dart';
import '../../features/seances_history/presentation/pages/seances_history_page.dart';
import '../../features/surveillance/presentation/pages/surveillance_page.dart';

/// Shared authentication state consumed by the GoRouter redirect guard.
class AppRouterAuth extends ChangeNotifier {
  bool _isLoggedIn = false;
  UserEntity? _user;

  bool get isLoggedIn => _isLoggedIn;
  UserEntity? get user => _user;

  void update({
    required bool isLoggedIn,
    UserEntity? user,
  }) {
    _isLoggedIn = isLoggedIn;
    _user = user;
    notifyListeners();
  }
}

class AppRouter {
  static const String login = '/login';
  static const String dashboard = '/dashboard';

  static const String adminDashboard = '/admin-dashboard';
  static const String doctorDashboard = '/doctor-dashboard';
  static const String nurseDashboard = '/nurse-dashboard';

  static const String patients = '/patients';
  static const String machines = '/machines';
  static const String monitoring = '/monitoring';
  static const String surveillance = '/surveillance';
  static const String alertsHistory = '/alerts-history';
  static const String seancesHistory = '/seances-history';
  static const String seances = '/seances';

  static const String doctors = '/doctors';
  static const String nurses = '/nurses';
  static const String devices = '/devices';

  static const String profile = '/profile';

  /// Router-level authentication state.
  static final AppRouterAuth auth = AppRouterAuth();

  // ---------------------------------------------------------------------------
  // Patients routes
  // ---------------------------------------------------------------------------

  /// /patients/<id>
  static String patientDetailRoute(int patientId) {
    return '$patients/$patientId';
  }

  /// /patients/<id>/edit
  static String patientEditRoute(int patientId) {
    return '$patients/$patientId/edit';
  }

  // ---------------------------------------------------------------------------
  // Machines routes
  // ---------------------------------------------------------------------------

  /// /machines/<id>
  static String machineDetailRoute(int machineId) {
    return '$machines/$machineId';
  }

  // ---------------------------------------------------------------------------
  // Sessions routes
  // ---------------------------------------------------------------------------

  /// /seances/detail/<id>
  static String sessionDetailRoute(String sessionId) {
    return '$seances/detail/$sessionId';
  }

  /// /seances/<id>/pre
  static String preSessionRoute(String sessionId) {
    return '$seances/$sessionId/pre';
  }

  /// /seances/<id>/post
  static String postSessionRoute(String sessionId) {
    return '$seances/$sessionId/post';
  }

  // ---------------------------------------------------------------------------
  // Dashboard
  // ---------------------------------------------------------------------------

  static String getDashboardRouteForUser(UserEntity user) {
    if (user.isAdmin) {
      return adminDashboard;
    }

    if (user.isDoctor) {
      return doctorDashboard;
    }

    if (user.isNurse) {
      return nurseDashboard;
    }

    return dashboard;
  }

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  /// Mirrors Django accounts.views.login_view.
  static String postLoginRoute(UserEntity? user) {
    if (user?.firstLogin == true) {
      return profile;
    }

    return surveillance;
  }

  // ---------------------------------------------------------------------------
  // GoRouter
  // ---------------------------------------------------------------------------

  static final GoRouter router = GoRouter(
    initialLocation: login,
    refreshListenable: auth,

    redirect: (context, state) {
      final isLoggedIn = auth.isLoggedIn;
      final location = state.matchedLocation;
      final isAtLogin = location == login;
      final user = auth.user;

      // User not authenticated.
      if (!isLoggedIn) {
        return isAtLogin ? null : login;
      }

      // Already authenticated but trying to access login.
      if (isAtLogin) {
        return postLoginRoute(user);
      }

      return null;
    },

    routes: [
      // -----------------------------------------------------------------------
      // Authentication
      // -----------------------------------------------------------------------

      GoRoute(
        path: login,
        builder: (context, state) {
          return const LoginPage();
        },
      ),

      // -----------------------------------------------------------------------
      // Profile
      // -----------------------------------------------------------------------

      GoRoute(
        path: profile,
        builder: (context, state) {
          return const ProfilePage();
        },
      ),

      // -----------------------------------------------------------------------
      // Dashboard
      // -----------------------------------------------------------------------

      GoRoute(
        path: dashboard,
        builder: (context, state) {
          return const DashboardPage();
        },
      ),

      GoRoute(
        path: adminDashboard,
        builder: (context, state) {
          return const AdminDashboardPage();
        },
      ),

      GoRoute(
        path: doctorDashboard,
        builder: (context, state) {
          return const DoctorDashboardPage();
        },
      ),

      GoRoute(
        path: nurseDashboard,
        builder: (context, state) {
          return const NurseDashboardPage();
        },
      ),

      // -----------------------------------------------------------------------
      // Patients
      // -----------------------------------------------------------------------

      GoRoute(
        path: patients,
        builder: (context, state) {
          return const PatientsPage();
        },
      ),

      // Patient detail:
      // /patients/:id
      GoRoute(
        path: '$patients/:id',
        builder: (context, state) {
          final patientId = int.tryParse(
                state.pathParameters['id'] ?? '',
              ) ??
              -1;

          return PatientDetailPage(
            patientId: patientId,
          );
        },
      ),

      // Patient edit:
      // /patients/:id/edit
      GoRoute(
        path: '$patients/:id/edit',
        builder: (context, state) {
          final patientId = int.tryParse(
                state.pathParameters['id'] ?? '',
              ) ??
              -1;

          return PatientEditPage(
            patientId: patientId,
          );
        },
      ),

      // -----------------------------------------------------------------------
      // Machines
      // -----------------------------------------------------------------------

      GoRoute(
        path: machines,
        builder: (context, state) {
          return const MachinesPage();
        },
      ),

      GoRoute(
        path: '$machines/:id',
        builder: (context, state) {
          final machineId = int.tryParse(
                state.pathParameters['id'] ?? '',
              ) ??
              -1;

          return MachineDetailPage(
            machineId: machineId,
          );
        },
      ),

      // -----------------------------------------------------------------------
      // Monitoring
      // -----------------------------------------------------------------------

      GoRoute(
        path: monitoring,
        builder: (context, state) {
          return const MonitoringPage();
        },
      ),

      // -----------------------------------------------------------------------
      // Surveillance
      // -----------------------------------------------------------------------

      GoRoute(
        path: surveillance,
        builder: (context, state) {
          return const SurveillancePage();
        },
      ),

      // -----------------------------------------------------------------------
      // Alerts history
      // -----------------------------------------------------------------------

      GoRoute(
        path: alertsHistory,
        builder: (context, state) {
          return const AlertsHistoryPage();
        },
      ),

      // -----------------------------------------------------------------------
      // Seances
      // -----------------------------------------------------------------------

      GoRoute(
        path: seances,
        builder: (context, state) {
          return const SeancesPage();
        },
      ),

      // Session detail:
      // /seances/detail/:id
      GoRoute(
        path: '$seances/detail/:id',
        builder: (context, state) {
          final sessionId = state.pathParameters['id'] ?? '';

          return SessionDetailPage(
            sessionId: sessionId,
          );
        },
      ),

      // Pre-session:
      // /seances/:id/pre
      GoRoute(
        path: '$seances/:id/pre',
        builder: (context, state) {
          final sessionId = state.pathParameters['id'] ?? '';

          return PreSessionPage(
            sessionId: sessionId,
          );
        },
      ),

      // Post-session:
      // /seances/:id/post
      GoRoute(
        path: '$seances/:id/post',
        builder: (context, state) {
          final sessionId = state.pathParameters['id'] ?? '';

          return PostSessionPage(
            sessionId: sessionId,
          );
        },
      ),

      // -----------------------------------------------------------------------
      // Seances history
      // -----------------------------------------------------------------------

      GoRoute(
        path: seancesHistory,
        builder: (context, state) {
          return const SeancesHistoryPage();
        },
      ),
    ],
  );
}