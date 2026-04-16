import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:io';
import 'auth_service.dart';

class SupportApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      // baseUrl: "https://playzoone.com/api",
      baseUrl: "https://playzoone.com/api",
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  static Future<String?> _token() => AuthService.getToken();

  // ─── جلب التذاكر ──────────────────────────────────────────────────────────
  static Future<List<dynamic>> getTickets() async {
    final token = await _token();
    if (token == null) throw Exception("لا يوجد توكن");

    final res = await _dio.get(
      '/tickets',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (res.data is Map && res.data['data'] != null) {
      return res.data['data'] as List<dynamic>;
    }
    return res.data as List<dynamic>;
  }

  // ─── إنشاء تذكرة (مع أو بدون ملف) ──────────────────────────────────────
  static Future<void> createTicket({
    required String subject,
    required String message,
    File? attachment,
  }) async {
    final token = await _token();
    if (token == null) throw Exception("لا يوجد توكن");

    final formData = FormData.fromMap({
      'subject': subject,
      'message': message,
      if (attachment != null) 'attachment': await _buildMultipart(attachment),
    });

    await _dio.post(
      '/tickets',
      data: formData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // ─── إرسال رسالة (مع أو بدون ملف) ───────────────────────────────────────
  static Future<void> sendMessage({
    required int ticketId,
    String? message,
    File? attachment,
  }) async {
    final token = await _token();
    if (token == null) throw Exception("لا يوجد توكن");

    final formData = FormData.fromMap({
      if (message != null && message.isNotEmpty) 'message': message,
      if (attachment != null) 'attachment': await _buildMultipart(attachment),
    });

    await _dio.post(
      '/tickets/$ticketId/message',
      data: formData,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // ─── Helper: بناء MultipartFile مع MIME صحيح ─────────────────────────────
  static Future<MultipartFile> _buildMultipart(File file) async {
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
    final parts = mimeType.split('/');
    return MultipartFile.fromFile(
      file.path,
      filename: file.path.split('/').last,
      contentType: MediaType(parts[0], parts[1]),
    );
  }

  // ─── طلب حذف الحساب (مع تأكيد كلمة المرور) ──────────────────────────────
  static Future<void> requestAccountDeletion({
    required String password,
    String? reason,
  }) async {
    final token = await _token();
    if (token == null) throw Exception("لا يوجد توكن");

    await _dio.post(
      '/account/delete-request',
      data: {
        'password': password,
        'reason':
            reason?.trim().isNotEmpty == true ? reason!.trim() : 'لم يذكر سبب',
      },
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }

  // ─── URL كامل للملف من السيرفر ────────────────────────────────────────────
  static String fileUrl(String path) {
    // يحوّل storage path لـ public URL
    // مثال: tickets/attachments/abc.jpg → https://playzoone.com/storage/tickets/attachments/abc.jpg
    final base = "https://playzoone.com/storage/";
    return "$base$path";
  }
}
