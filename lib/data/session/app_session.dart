import '../api/api_client.dart';
import '../api/api_base_url.dart';

class AppSession {
  AppSession._();

  static final ApiClient apiClient = ApiClient(
    baseUrl: resolveApiBaseUrl(),
  );
}
