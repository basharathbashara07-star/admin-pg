import '../services/api_service.dart';

class ApiConfig {
  static String get baseUrl => '${ApiService.baseUrl}/api/tenant';
  static String get socketUrl => ApiService.baseUrl;
}