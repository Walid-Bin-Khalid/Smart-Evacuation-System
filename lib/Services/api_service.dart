import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ── Base URL ──────────────────────────────────────────────
  // Android emulator:  http://10.0.2.2:3001/v1
  // Real device:       http://192.168.1.X:3001/v1
  // Production:        https://your-domain.com/v1
  static const String _baseUrl = 'http://10.0.2.2:3001/v1';

  // ── Singleton ────────────────────────────────────────────
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _setupDio();
  }

  // ── Dio instance ─────────────────────────────────────────
  late final Dio _dio;

  // ── Stored JWT token ─────────────────────────────────────
  String? _token;
  String? get token => _token;

  // ── Dio setup with interceptors ──────────────────────────
  void _setupDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // ── Request interceptor: har request pe token attach ──
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // 401 = token expired → auto logout
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
  //  Token = SINGLE source of truth. isLoggedIn hata diya.
  // ══════════════════════════════════════════════════════════

  /// App start pe token load karo
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  /// Token save karo
  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Token clear karo (logout)
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('employeeId');
    await prefs.remove('fullName');
    await prefs.remove('role');
    await prefs.remove('mongoId');
    // NOTE: isLoggedIn REMOVED — token hi auth state hai
  }

  // ══════════════════════════════════════════════════════════
  //  AUTH
  // ══════════════════════════════════════════════════════════

  /// POST /v1/employees/signup
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

  /// POST /v1/employees/login
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

        // User info save karo SharedPrefs mein
        final user = body['user'] as Map<String, dynamic>? ?? {};
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('employeeId', user['employeeId'] ?? '');
        await prefs.setString('fullName', user['name'] ?? '');
        await prefs.setString('role', user['role'] ?? 'Employee');
        await prefs.setString('mongoId', user['_id'] ?? '');
        // isLoggedIn NAHI likhte — token hi sab kuch hai
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

  /// GET /v1/employees
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

  /// GET /v1/employees/stats/overview
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

  /// PATCH /v1/employees/:id/location
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

  /// POST /v1/sos/alert
  /// [imageFile] optional — multipart upload hoga agar diya
  /// severity auto-calculate hogi hazardType se
  Future<ApiResult> createSosAlert({
    required String hazardType,
    required String floor,
    required String areaType,
    String? roomNumber, // null bhejo agar nahi hai
    required String reportedBy,
    required String reportedByName,
    required String message,
    File? imageFile, // ✅ actual File object
    String? severity, // null = auto-calculate
  }) async {
    try {
      // ── Severity auto-calculate ──────────────────────────
      final resolvedSeverity = severity ?? _calculateSeverity(hazardType);

      // ── Multipart form data banao ────────────────────────
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

        // ── Image attach karo agar hai ──
        if (imageFile != null)
          'photo': await MultipartFile.fromFile(
            imageFile.path,
            filename: 'sos_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
      });

      final res = await _dio.post(
        '/sos/alert',
        data: formData,
        options: Options(
          // Multipart ke liye Content-Type override karo
          contentType: 'multipart/form-data',
        ),
      );

      return ApiResult.success(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return ApiResult.error('Error: $e');
    }
  }

  /// GET /v1/sos/alerts/active
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

  /// GET /v1/sos/alerts
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

  /// PATCH /v1/sos/alerts/:id/resolve
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

  /// Hazard type se severity calculate karo
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
    // obstruction, spill, etc.
    return 'low';
  }

  /// Dio error ko ApiResult mein convert karo
  ApiResult _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiResult.error('Server se connect nahi ho saka. Timeout.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiResult.error('Internet connection check karo.');
    }
    // Server ne error response diya
    final msg = e.response?.data?['message'] as String?;
    return ApiResult.error(msg ?? 'Server error: ${e.response?.statusCode}');
  }
}

// ══════════════════════════════════════════════════════════════
//  ApiResult — clean success/error wrapper (same as before)
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

