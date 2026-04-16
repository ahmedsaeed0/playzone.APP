import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token") != null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    const url = 'https://playzoone.com/api/profile';

    print('===== GET PROFILE START =====');
    print('URL: $url');
    print('TOKEN: $token');

    try {
      final response = await Dio().get(
        url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE DATA: ${response.data}');
      print('===== GET PROFILE END =====');

      return response.data['user'] ?? {};
    } on DioException catch (e) {
      print('===== GET PROFILE ERROR =====');
      print('MESSAGE: ${e.message}');
      print('TYPE: ${e.type}');
      print('STATUS CODE: ${e.response?.statusCode}');
      print('RESPONSE DATA: ${e.response?.data}');
      print('REQUEST URL: ${e.requestOptions.uri}');
      print('REQUEST HEADERS: ${e.requestOptions.headers}');
      print('===== GET PROFILE ERROR END =====');
      rethrow;
    } catch (e) {
      print('===== UNKNOWN ERROR =====');
      print(e);
      print('===== UNKNOWN ERROR END =====');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final response = await Dio().get(
      'https://playzoone.com/api/notifications',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );
    return response.data;
  }

  static Future<void> markNotificationRead(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    await Dio().post(
      'https://playzoone.com/api/notifications/$id/read',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );
  }

  static Future<void> markAllNotificationsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    await Dio().post(
      'https://playzoone.com/api/notifications/read-all',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final token = await getToken();
    await Dio().post(
      'https://playzoone.com/api/auth/change-password',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );
  }
}