import '../../../models/user.dart';
import '../../api/api_client.dart';
import '../user_repository.dart';

class ApiUserRepository implements UserRepository {
  ApiUserRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<User>> list({String? role, String? search}) async {
    final query = <String, dynamic>{};
    if (role != null) query['role'] = role;
    if (search != null) query['search'] = search;
    final data = await _client.get('/api/users', query: query);
    final rows = (data as Map<String, dynamic>)['rows'] as List<dynamic>? ?? [];
    return rows
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<User> create({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    final data = await _client.post('/api/users', body: {
      'email': email,
      'password': password,
      'fullName': fullName,
      'phone': phone,
      'role': role,
    });
    return User.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<User> setRole(String id, String role) async {
    final data = await _client.patch('/api/users/$id/role', body: {'role': role});
    return User.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<User> setActive(String id, bool isActive) async {
    final data = await _client.patch('/api/users/$id/active', body: {'isActive': isActive});
    return User.fromJson(data as Map<String, dynamic>);
  }
}
