import '../../core/utils/result.dart';
import '../entities/user_profile.dart';

abstract interface class ProfileRepository {
  Future<Result<UserProfile>> get();
  Future<Result<void>> save(UserProfile profile);
  Stream<UserProfile> watch();
}
