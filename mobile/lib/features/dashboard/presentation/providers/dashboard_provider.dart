import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/dashboard_kpis.dart';
import '../../domain/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardRepositoryImpl(DashboardRemoteDatasource(apiClient));
});

/// Backed by GET /api/dashboard/. Polls every 5 seconds like the
/// Monitoring/Surveillance notifiers so the KPI cards (active sessions,
/// available machines, active alerts…) reflect the real-time state. The last
/// payload is kept on each tick; errors are only surfaced when there is
/// nothing to show yet.
class DashboardNotifier extends AsyncNotifier<DashboardKpis> {
  Timer? _timer;
  bool _fetching = false;
  bool _disposed = false;

  @override
  Future<DashboardKpis> build() {
    _disposed = false;

    ref.onDispose(() {
      _disposed = true;
      _stopPolling();
    });

    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        _startPolling();
      } else {
        _stopPolling();
      }
    });

    if (ref.read(authStateProvider) is! AuthAuthenticated) {
      return Future.error(StateError('Not authenticated'));
    }

    _startPolling();
    return _fetch();
  }

  Future<DashboardKpis> _fetch() async {
    final repository = ref.read(dashboardRepositoryProvider);
    return repository.fetchKpis();
  }

  void _startPolling() {
    if (_timer != null || _disposed) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_fetching || _disposed) return;
      if (ref.read(authStateProvider) is! AuthAuthenticated) return;
      _fetching = true;
      try {
        final data = await _fetch();
        if (!_disposed) state = AsyncValue.data(data);
      } catch (err, stack) {
        if (!_disposed && state is! AsyncData) {
          state = AsyncValue.error(err, stack);
        }
      } finally {
        _fetching = false;
      }
    });
  }

  void _stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  /// Full reload used by pull-to-refresh.
  Future<void> refresh() async {
    if (ref.read(authStateProvider) is! AuthAuthenticated) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final dashboardKpisProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardKpis>(
      DashboardNotifier.new,
    );
