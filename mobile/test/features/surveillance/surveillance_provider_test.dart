import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/authentication/domain/entities/user_entity.dart';
import 'package:mobile/features/authentication/domain/repositories/auth_repository.dart';
import 'package:mobile/features/authentication/presentation/providers/auth_provider.dart';
import 'package:mobile/features/surveillance/domain/entities/live_monitoring_entity.dart';
import 'package:mobile/features/surveillance/domain/repositories/surveillance_repository.dart';
import 'package:mobile/features/surveillance/presentation/providers/surveillance_provider.dart';

class _CountingSurveillanceRepository implements SurveillanceRepository {
  int calls = 0;

  @override
  Future<SurveillanceLiveEntity> getLiveMonitoring() async {
    calls++;
    return const SurveillanceLiveEntity(sessions: [], alerts: []);
  }

  @override
  Future<void> ackAlert(String alertId) async {}
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<UserEntity?> checkAutoLogin() async =>
      const UserEntity(id: 1, username: 'nurse', role: 'infirmier');

  @override
  Future<UserEntity> login(String username, String password) async =>
      const UserEntity(id: 1, username: 'nurse', role: 'infirmier');

  @override
  Future<void> logout() async {}

  @override
  Future<void> markFirstLoginDone() async {}

  @override
  Future<void> requestPasswordReset(String email) async {}
}

/// Auth already authenticated before the Surveillance page opens.
class _AuthenticatedAuthNotifier extends AuthNotifier {
  _AuthenticatedAuthNotifier()
      : super(_FakeAuthRepository()) {
    state = const AuthAuthenticated(
      UserEntity(id: 1, username: 'nurse', role: 'infirmier'),
    );
  }
}

void main() {
  test('polls every 3s while listened, stops after dispose, restarts on re-listen',
      () {
    fakeAsync((async) {
      final repo = _CountingSurveillanceRepository();

      final container = ProviderContainer(
        overrides: [
          surveillanceRepositoryProvider.overrideWithValue(repo),
          authStateProvider.overrideWith((ref) => _AuthenticatedAuthNotifier()),
        ],
      );
      addTearDown(container.dispose);

      // Auto-login completes before the Surveillance page is opened (same as
      // the real app: auth is already done at startup).
      async.flushMicrotasks();
      expect(container.read(authStateProvider), isA<AuthAuthenticated>());

      final sub = container.listen<AsyncValue<SurveillanceLiveEntity>>(
        surveillanceLiveProvider,
        (_, _) {},
      );
      async.flushMicrotasks();

      // Initial fetch on first listen.
      expect(repo.calls, 1);
      expect(container.read(surveillanceLiveProvider).value, isNotNull);

      // One tick every 3s while the page is open.
      async.elapse(const Duration(seconds: 3));
      async.flushMicrotasks();
      expect(repo.calls, 2);

      async.elapse(const Duration(seconds: 9));
      async.flushMicrotasks();
      expect(repo.calls, 5);

      // Leaving the page drops the listener => autoDispose cancels the timer.
      sub.close();
      async.flushMicrotasks();
      final callsAfterLeave = repo.calls;

      async.elapse(const Duration(seconds: 12));
      async.flushMicrotasks();
      expect(repo.calls, callsAfterLeave, reason: 'timer must stop after dispose');

      // Returning re-subscribes and restarts polling.
      container.listen<AsyncValue<SurveillanceLiveEntity>>(
        surveillanceLiveProvider,
        (_, _) {},
      );
      async.flushMicrotasks();
      expect(repo.calls, callsAfterLeave + 1);

      async.elapse(const Duration(seconds: 6));
      async.flushMicrotasks();
      expect(repo.calls, callsAfterLeave + 3);

      // No pending periodic timer must survive after disposal.
      container.dispose();
      async.flushMicrotasks();
    });
  });

  test('stops polling immediately when auth is lost', () {
    fakeAsync((async) {
      final repo = _CountingSurveillanceRepository();

      final container = ProviderContainer(
        overrides: [
          surveillanceRepositoryProvider.overrideWithValue(repo),
          authStateProvider.overrideWith((ref) => _AuthenticatedAuthNotifier()),
        ],
      );
      addTearDown(container.dispose);

      async.flushMicrotasks();
      expect(container.read(authStateProvider), isA<AuthAuthenticated>());

      container.listen<AsyncValue<SurveillanceLiveEntity>>(
        surveillanceLiveProvider,
        (_, _) {},
      );
      async.flushMicrotasks();
      expect(repo.calls, 1);

      // Logout: auth flips to unauthenticated => polling must stop.
      container.read(authStateProvider.notifier).logout();
      async.flushMicrotasks();
      final callsAfterLogout = repo.calls;

      async.elapse(const Duration(seconds: 12));
      async.flushMicrotasks();
      expect(repo.calls, callsAfterLogout, reason: 'timer must stop after logout');

      container.dispose();
      async.flushMicrotasks();
    });
  });
}