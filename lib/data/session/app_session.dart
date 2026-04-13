import '../api/api_client.dart';

class AppSession {
  AppSession._();

  static final ApiClient apiClient = ApiClient(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8081',
    ),
  );
}
