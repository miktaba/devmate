import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user.dart';
import '../../../profile/data/repositories/user_repository.dart';
import '../../../profile/data/providers/user_repository_provider.dart';

class UserNotifier extends Notifier<User?> {
  late final UserRepository _repository;

  @override
  User? build() {
    _repository = ref.read(userRepositoryProvider);
    final users = _repository.getAllUsers();
    if (users.isNotEmpty) {
      return users.first;
    }
    return null;
  }

  Future<void> setUser(User user) async {
    state = user;
    await _repository.saveUser(user);
  }

  void loadUserById(String id) {
    final user = _repository.getUser(id);
    state = user;
  }

  Future<void> logout() async {
    if (state != null) {
      await _repository.deleteUser(state!.id);
    }
    state = null;
  }
}

final userProvider = NotifierProvider<UserNotifier, User?>(
  () => UserNotifier(),
);
