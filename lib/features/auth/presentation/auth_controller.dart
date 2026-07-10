import 'package:get/get.dart';

import '../../../domain/entities/auth_user.dart';
import '../../../domain/repositories/auth_repository.dart';

class AuthController extends GetxController {
  AuthController(this._auth);
  final AuthRepository _auth;

  final loading = false.obs;
  final error = RxnString();
  final Rxn<AuthUser> user = Rxn<AuthUser>();

  bool get isAvailable => _auth.isAvailable;

  @override
  void onInit() {
    super.onInit();
    user.value = _auth.currentUser;
    _auth.authState().listen(user.call);
  }

  Future<void> signInWithGoogle() async {
    error.value = null;
    loading.value = true;
    final result = await _auth.signInWithGoogle();
    loading.value = false;
    result.fold(
      (_) => Get.back(),
      (failure) => error.value = failure.message,
    );
  }

  Future<void> continueAsGuest() async {
    error.value = null;
    loading.value = true;
    final result = await _auth.signInAnonymously();
    loading.value = false;
    result.fold(
      (_) => Get.back(),
      (f) => error.value = f.message,
    );
  }

  Future<void> signOut() => _auth.signOut();
}
