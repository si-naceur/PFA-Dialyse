import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/datasources/devices_remote_datasource.dart';
import '../../domain/entities/device_entity.dart';

final devicesDatasourceProvider = Provider<DevicesRemoteDatasource>((ref) {
  return DevicesRemoteDatasource(ref.watch(apiClientProvider));
});

class DevicesNotifier extends AsyncNotifier<DevicesResult> {
  @override
  Future<DevicesResult> build() {
    return ref.read(devicesDatasourceProvider).getDevices();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(devicesDatasourceProvider).getDevices(),
    );
  }
}

final devicesProvider =
    AsyncNotifierProvider<DevicesNotifier, DevicesResult>(DevicesNotifier.new);
