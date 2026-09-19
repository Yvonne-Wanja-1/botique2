import '../../models/user.dart';

abstract class UserRepository {
  Future<List<User>> list({String? role, String? search});
  Future<User> create({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  });
  Future<User> setRole(String id, String role);
  Future<User> setActive(String id, bool isActive);
}
