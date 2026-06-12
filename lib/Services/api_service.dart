//  lib/Services/api_service.dart  (UPDATED — AppConfig use karta hai)
//  Change: hardcoded IP hata diya → AppConfig.baseUrl
//  Ab sirf app_config.dart mein IP badlo, yahan kuch nahi.

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Core/Config/app_config.dart';

class ApiService {
  // ── Singleton ────────────────────────────────────────────
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _setupDio();
  }

  late final Dio _dio;
  String? _token;
  String? get token => _token;

  void _setupDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl, // ← AppConfig se
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await clearToken();
          }
          return handler.next(e);
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  //  TOKEN MANAGEMENT
  // ══════════════════════════════════════════════════════════

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('employeeId');
    await prefs.remove('fullName');
    await prefs.remove('role');
    await prefs.remove('mongoId');
  }

  // ══════════════════════════════════════════════════════════
  //  AUTH
  // ══════════════════════════════════════════════════════════

  Future<ApiResult> signup({
    required String employeeId,
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String department,
    String role = 'Employee',
  }) async {
    try {
      final res = await _dio.post(
        '/employees/signup',
        data: {
          'employeeId': employeeId,
          'name': name,
          'email': email,
          'password': password,
          'confirmPassword': confirmPassword,
          'department': department,
          'role': role,
        },
      );
      return ApiResult.success(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResult.error('Error: $e');
    }
  }

  Future<ApiResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _dio.post(
        '/employees/login',
        data: {'email': email, 'password': password},
      );

      final body = res.data as Map<String, dynamic>;

      if (body['token'] != null) {
        await _saveToken(body['token'] as String);

        final user = body['user'] as Map<String, dynamic>? ?? {};
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('employeeId', user['employeeId'] ?? '');
        await prefs.setString('fullName', user['name'] ?? '');
        await prefs.setString('role', user['role'] ?? 'Employee');
        await prefs.setString('mongoId', user['_id'] ?? '');
      }

      return ApiResult.success(body);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResult.error('Error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════
  //  EMPLOYEES
  // ══════════════════════════════════════════════════════════

  Future<ApiResult> getEmployees() async {
    try {
      final res = await _dio.get('/employees');
      return ApiResult.success(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResult.error('Error: $e');
    }
  }

  Future<ApiResult> getStats() async {
    try {
      final res = await _dio.get('/employees/stats/overview');
      return ApiResult.success(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResult.error('Error: $e');
    }
  }

  Future<ApiResult> updateLocation({
    required String mongoId,
    required double slamX,
    required double slamY,
    required String floor,
    required String areaType,
    String roomNumber = '',
    String status = 'online',
  }) async {
    try {
      final res = await _dio.patch(
        '/employees/$mongoId/location',
        data: {
          'slamX': slamX,
          'slamY': slamY,
          'floor': floor,
          'areaType': areaType,
          'roomNumber': roomNumber,
          'status': status,
        },
      );
      return ApiResult.success(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResult.error('Error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════
  //  SOS ALERTS
  // ══════════════════════════════════════════════════════════

  Future<ApiResult> createSosAlert({
    required String hazardType,
    required String floor,
    required String areaType,
    String? roomNumber,
    required String reportedBy,
    required String reportedByName,
    required String message,
    File? imageFile,
    String? severity,
  }) async {
    try {
      final resolvedSeverity = severity ?? _calculateSeverity(hazardType);

      final formData = FormData.fromMap({
        'hazardType': hazardType,
        'floor': floor,
        'areaType': areaType,
        if (roomNumber != null && roomNumber.isNotEmpty)
          'roomNumber': roomNumber,
        'reportedBy': reportedBy,
        'reportedByName': reportedByName,
        'message': message,
        'severity': resolvedSeverity,
        if (imageFile != null)
          'photo': await MultipartFile.fromFile(
            imageFile.path,
            filename: 'sos_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
      });

      final res = await _dio.post(
        '/sos/alert',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      return ApiResult.success(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResult.error('Error: $e');
    }
  }

  Future<ApiResult> getActiveAlerts() async {
    try {
      final res = await _dio.get('/sos/alerts/active');
      return ApiResult.success(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResult.error('Error: $e');
    }
  }

  Future<ApiResult> getAllAlerts() async {
    try {
      final res = await _dio.get('/sos/alerts');
      return ApiResult.success(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResult.error('Error: $e');
    }
  }

  Future<ApiResult> resolveAlert(String alertMongoId) async {
    try {
      final res = await _dio.patch('/sos/alerts/$alertMongoId/resolve');
      return ApiResult.success(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResult.error('Error: $e');
    }
  }

  // ══════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════

  String _calculateSeverity(String hazardType) {
    final h = hazardType.toLowerCase().trim();
    if ([
      'fire',
      'explosion',
      'blast',
      'chemical',
      'gas leak',
    ].any(h.contains)) {
      return 'high';
    }
    if (['smoke', 'flood', 'collapse', 'injury'].any(h.contains)) {
      return 'medium';
    }
    return 'low';
  }

  ApiResult _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiResult.error('Server timeout. Backend chal raha hai?');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiResult.error(
        'Connect nahi ho saka.\n'
        'Check karo:\n'
        '1. Backend chal raha hai? (npm run start:dev)\n'
        '2. Phone aur laptop same WiFi pe?\n'
        '3. app_config.dart mein IP sahi hai? (${AppConfig.baseUrl})',
      );
    }
    final msg = e.response?.data?['message'] as String?;
    return ApiResult.error(msg ?? 'Server error: ${e.response?.statusCode}');
  }
}

// ══════════════════════════════════════════════════════════════
//  ApiResult
// ══════════════════════════════════════════════════════════════
class ApiResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;

  const ApiResult._({required this.success, this.data, this.error});

  factory ApiResult.success(Map<String, dynamic> data) =>
      ApiResult._(success: true, data: data);

  factory ApiResult.error(String message) =>
      ApiResult._(success: false, error: message);
}
