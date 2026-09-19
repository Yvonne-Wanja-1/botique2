import 'api_client.dart';

/// Base URL for the Queens' Touch API backend.
/// Override with --dart-define=API_BASE_URL=... at build time.
const String kApiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://botique2-production.up.railway.app');

ApiClient createApiClient() => ApiClient(baseUrl: kApiBaseUrl);
