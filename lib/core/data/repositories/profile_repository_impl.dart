import 'dart:async';

import '../../../domain/entities/user_profile.dart';
import '../../../domain/repositories/profile_repository.dart';
import '../../firebase/remote_mirror.dart';
import '../../utils/result.dart';
import '../local_store.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._store, this._mirror);
  final LocalStore _store;
  final RemoteMirror _mirror;
  static const _key = 'profile';

  UserProfile _read() {
    final raw = _store.singletons.get(_key);
    if (raw == null) return const UserProfile(id: 'me');
    return UserProfile.fromMap(LocalStore.normalize(raw));
  }

  @override
  Future<Result<UserProfile>> get() async {
    try {
      return Success(_read());
    } catch (e) {
      return Err(Failure.cache(e));
    }
  }

  @override
  Future<Result<void>> save(UserProfile profile) async {
    try {
      final map = profile.toMap();
      await _store.singletons.put(_key, map);
      unawaited(_mirror.setSingleton(_key, map));
      return const Success(null);
    } catch (e) {
      return Err(Failure.cache(e));
    }
  }

  @override
  Stream<UserProfile> watch() async* {
    yield _read();
    yield* _store.singletons
        .watch(key: _key)
        .map((_) => _read());
  }
}
