import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/models.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  String? _authToken;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired → redirect to login
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> setToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  // ── AUTH ──────────────────────────────────────────────
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final res = await _dio.post('/auth/otp/send', data: {'phone': phone});
    return res.data;
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String idToken) async {
    final res = await _dio.post('/auth/otp/verify',
        data: {'phone': phone, 'id_token': idToken});
    return res.data;
  }

  // ── USER ──────────────────────────────────────────────
  Future<UserModel> getProfile() async {
    final res = await _dio.get('/users/profile');
    return UserModel.fromJson(res.data['user']);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.post('/users/profile', data: data);
    return UserModel.fromJson(res.data['user']);
  }

  Future<void> updateLocation(double lat, double lng, bool isAvailable) async {
    await _dio.patch('/users/location', data: {
      'lat': lat,
      'lng': lng,
      'is_available': isAvailable,
    });
  }

  // ── JOBS (P2P) ────────────────────────────────────────
  Future<HelpJob> createJob({
    required double lat,
    required double lng,
    required String problemType,
    String? problemDesc,
    required double rewardAmount,
  }) async {
    final res = await _dio.post('/jobs', data: {
      'req_lat': lat,
      'req_lng': lng,
      'problem_type': problemType,
      'problem_desc': problemDesc,
      'reward_amount': rewardAmount,
    });
    return HelpJob.fromJson(res.data['job']);
  }

  Future<HelpJob> getJob(String jobId) async {
    final res = await _dio.get('/jobs/$jobId');
    return HelpJob.fromJson(res.data['job']);
  }

  Future<HelpJob> acceptJob(String jobId) async {
    final res = await _dio.post('/jobs/$jobId/accept');
    return HelpJob.fromJson(res.data['job']);
  }

  Future<HelpJob> verifyArrival(String jobId, String otp) async {
    final res = await _dio.post('/jobs/$jobId/arrive', data: {'otp': otp});
    return HelpJob.fromJson(res.data['job']);
  }

  Future<HelpJob> completeJob(String jobId) async {
    final res = await _dio.post('/jobs/$jobId/complete');
    return HelpJob.fromJson(res.data['job']);
  }

  Future<List<HelpJob>> getMyJobs() async {
    final res = await _dio.get('/jobs/my');
    return (res.data['jobs'] as List).map((j) => HelpJob.fromJson(j)).toList();
  }

  // ── MECHANICS ─────────────────────────────────────────
  Future<List<MechanicModel>> getNearbyMechanics({
    required double lat,
    required double lng,
    double radius = 20,
    String? specialization,
  }) async {
    final res = await _dio.get('/mechanics/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
      if (specialization != null) 'specialization': specialization,
    });
    return (res.data['mechanics'] as List).map((m) => MechanicModel.fromJson(m)).toList();
  }

  // ── AI MECHANIC ───────────────────────────────────────
  Future<String> sendAiMessage({
    required String sessionId,
    required String message,
    required List<Map<String, String>> history,
    required String vehicleType,
    String languageCode = 'hi',   // ← NEW: 'hi','pa','ta','te','bn','en'
  }) async {
    final res = await _dio.post('/ai/chat', data: {
      'session_id': sessionId,
      'message': message,
      'history': history,
      'vehicle_type': vehicleType,
      'language': languageCode,  // ← Backend AI replies in this language
    });
    return res.data['reply'] as String;
  }


  // ── GOOGLE AUTH ───────────────────────────────────────
  /// Called after Firebase Google sign-in — backend returns our JWT
  Future<Map<String, dynamic>> googleSignIn({
    required String firebaseToken,
    required String email,
    required String name,
    required String photoUrl,
    required String googleId,
  }) async {
    final res = await _dio.post('/auth/google', data: {
      'firebase_token': firebaseToken,
      'email': email,
      'name': name,
      'photo_url': photoUrl,
      'google_id': googleId,
    });
    // Response: { token: "jwt...", is_new_user: bool, user: {...} }
    return res.data;
  }

  /// Clear stored JWT (logout)
  Future<void> clearToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ── RATINGS ───────────────────────────────────────────
  Future<void> submitRating({
    required String jobId,
    required String ratedId,
    required int rating,
    String? review,
    List<String>? tags,
  }) async {
    await _dio.post('/ratings', data: {
      'job_id': jobId,
      'rated_id': ratedId,
      'rating': rating,
      'review': review,
      'tags': tags,
    });
  }

  // ── SOS ───────────────────────────────────────────────
  Future<Map<String, dynamic>> triggerSos({
    required double lat,
    required double lng,
  }) async {
    final res = await _dio.post('/sos', data: {'lat': lat, 'lng': lng});
    return res.data;
  }


  // ── SHOP ──────────────────────────────────────────────
  Future<List<Product>> getProducts({String? category, String? search}) async {
    final res = await _dio.get('/shop/products', queryParameters: {
      if (category != null) 'category': category,
      if (search != null) 'search': search,
    });
    return (res.data['products'] as List)
        .map((p) => Product.fromJson(p))
        .toList();
  }

  Future<Product> getProduct(String id) async {
    final res = await _dio.get('/shop/products/$id');
    return Product.fromJson(res.data['product']);
  }

  Future<Map<String, dynamic>> placeOrder({
    required List<CartItem> items,
    required double totalAmount,
    required String paymentMethod,
    String? paymentId,
    required String deliveryAddress,
  }) async {
    final res = await _dio.post('/shop/orders', data: {
      'items': items.map((i) => {
        'product_id': i.product.id,
        'quantity': i.quantity,
        'price': i.product.finalPrice,
      }).toList(),
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'payment_id': paymentId,
      'delivery_address': deliveryAddress,
    });
    return res.data;
  }

  Future<List<ShopOrder>> getMyOrders() async {
    final res = await _dio.get('/shop/orders/mine');
    return (res.data['orders'] as List)
        .map((o) => ShopOrder.fromJson(o))
        .toList();
  }

  // ── Generic methods (daily features + selfie use karte hain) ──

  Future<Map<String, dynamic>> get(String path) async {
    final res = await _dio.get(path);
    return res.data;
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    final res = await _dio.post(path, data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> data) async {
    final res = await _dio.put(path, data: data);
    return res.data;
  }

  // ── Admin methods (x-admin-secret header ke saath) ────────────

  Future<Map<String, dynamic>> getWithAdminSecret(String path, String secret) async {
    final res = await _dio.get(path,
        options: Options(headers: {'x-admin-secret': secret}));
    return res.data;
  }

  Future<Map<String, dynamic>> putWithAdminSecret(
      String path, String secret, Map<String, dynamic> data) async {
    final res = await _dio.put(path,
        data: data,
        options: Options(headers: {'x-admin-secret': secret}));
    return res.data;
  }
}
