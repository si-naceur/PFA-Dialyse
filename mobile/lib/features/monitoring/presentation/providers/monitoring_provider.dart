import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/datasources/monitoring_remote_datasource.dart';
import '../../data/repositories/monitoring_repository_impl.dart';
import '../../domain/entities/monitoring_dashboard_entity.dart';
import '../../domain/repositories/monitoring_repository.dart';

final monitoringRepositoryProvider = Provider<MonitoringRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MonitoringRepositoryImpl(MonitoringRemoteDatasource(apiClient));
});

/// Filters of the "Historique login / logout" section. Values match the web
/// dashboard table filters (day / q / role / sort / status=ongoing).
class MonitoringFilters {
  final String day;
  final String q;
  final String role;
  final String sort;
  final String status;

  const MonitoringFilters({
    this.day = '',
    this.q = '',
    this.role = '',
    this.sort = '-login_at',
    this.status = '',
  });

  Map<String, dynamic> toQuery() {
    return {'day': day, 'q': q, 'role': role, 'sort': sort, 'status': status};
  }

  MonitoringFilters copyWith({
    String? day,
    String? q,
    String? role,
    String? sort,
    String? status,
  }) {
    return MonitoringFilters(
      day: day ?? this.day,
      q: q ?? this.q,
      role: role ?? this.role,
      sort: sort ?? this.sort,
      status: status ?? this.status,
    );
  }
}

/// Backed by GET /api/monitoring/. The dashboard polls every 5 seconds so the
/// live measurement block and the alert cards stay up to date without showing
/// a loading spinner on each tick (the last data is kept until a new payload
/// arrives). Pull-to-refresh always reloads explicitly.
class MonitoringNotifier extends AsyncNotifier<MonitoringDashboardEntity> {
  MonitoringFilters _filters = const MonitoringFilters();
  Timer? _timer;
  bool _fetching = false;
  bool _disposed = false;

  @override
  Future<MonitoringDashboardEntity> build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
    });
    _startPolling();
    return _fetch();
  }

  MonitoringFilters get filters => _filters;

  Future<MonitoringDashboardEntity> _fetch() async {
    final repository = ref.read(monitoringRepositoryProvider);
    return repository.getMonitoringDashboard(
      day: _filters.day,
      q: _filters.q,
      role: _filters.role,
      sort: _filters.sort,
      status: _filters.status,
    );
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_fetching || _disposed) return;
      _fetching = true;
      try {
        final data = await _fetch();
        if (!_disposed) state = AsyncValue.data(data);
      } catch (err, stack) {
        // Keep the previously loaded payload; surface an error only when there
        // is nothing to show yet.
        if (!_disposed && state is! AsyncData) {
          state = AsyncValue.error(err, stack);
        }
      } finally {
        _fetching = false;
      }
    });
  }

  /// Update the history filters (day/q/role/sort/status) and reload.
  Future<void> setFilters(MonitoringFilters filters) async {
    _filters = filters;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Full reload used by pull-to-refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final monitoringDashboardProvider =
    AsyncNotifierProvider<MonitoringNotifier, MonitoringDashboardEntity>(
      MonitoringNotifier.new,
    );
