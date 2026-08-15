import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ProfileRemoteDatasource(ref.watch(apiClientProvider)));
});

final profileProvider = FutureProvider<ProfileEntity>((ref) {
  return ref.watch(profileRepositoryProvider).getProfile();
});
