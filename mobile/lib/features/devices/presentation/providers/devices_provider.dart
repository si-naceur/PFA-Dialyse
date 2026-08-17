import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/repositories/devices_repository_impl.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/repositories/devices_repository.dart';

final devicesRepositoryProvider = Provider<DevicesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DevicesRepositoryImpl.fromClient(apiClient);
});

class DevicesNotifier extends AsyncNotifier<DevicesResult> {
  @override
  Future<DevicesResult> build() {
    return ref.read(devicesRepositoryProvider).getDevices();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(devicesRepositoryProvider).getDevices(),
    );
  }
}

final devicesProvider =
    AsyncNotifierProvider<DevicesNotifier, DevicesResult>(DevicesNotifier.new);