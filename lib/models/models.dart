// ============================================================
// FILE 1: lib/models/models.dart  (UPDATED — Multilingual)
// ============================================================

// ==================== SUPPORTED LANGUAGES ====================
enum AppLanguage { english, hindi, punjabi, tamil, telugu, bengali }

extension AppLanguageExt on AppLanguage {
  // Language code used in SharedPreferences
  String get code {
    switch (this) {
      case AppLanguage.english:  return 'en';
      case AppLanguage.hindi:    return 'hi';
      case AppLanguage.punjabi:  return 'pa';
      case AppLanguage.tamil:    return 'ta';
      case AppLanguage.telugu:   return 'te';
      case AppLanguage.bengali:  return 'bn';
    }
  }

  // BCP-47 locale code for TTS + STT
  String get localeCode {
    switch (this) {
      case AppLanguage.english:  return 'en-IN';
      case AppLanguage.hindi:    return 'hi-IN';
      case AppLanguage.punjabi:  return 'pa-IN';
      case AppLanguage.tamil:    return 'ta-IN';
      case AppLanguage.telugu:   return 'te-IN';
      case AppLanguage.bengali:  return 'bn-IN';
    }
  }

  // Display name shown in UI switcher
  String get displayName {
    switch (this) {
      case AppLanguage.english:  return 'English';
      case AppLanguage.hindi:    return 'हिंदी';
      case AppLanguage.punjabi:  return 'ਪੰਜਾਬੀ';
      case AppLanguage.tamil:    return 'தமிழ்';
      case AppLanguage.telugu:   return 'తెలుగు';
      case AppLanguage.bengali:  return 'বাংলা';
    }
  }

  // Native flag emoji
  String get flag {
    switch (this) {
      case AppLanguage.english:  return '🇬🇧';
      case AppLanguage.hindi:    return '🇮🇳';
      case AppLanguage.punjabi:  return '🇮🇳';
      case AppLanguage.tamil:    return '🇮🇳';
      case AppLanguage.telugu:   return '🇮🇳';
      case AppLanguage.bengali:  return '🇮🇳';
    }
  }

  // Parse from stored code string
  static AppLanguage fromCode(String code) {
    switch (code) {
      case 'en': return AppLanguage.english;
      case 'pa': return AppLanguage.punjabi;
      case 'ta': return AppLanguage.tamil;
      case 'te': return AppLanguage.telugu;
      case 'bn': return AppLanguage.bengali;
      default:   return AppLanguage.hindi;
    }
  }
}

// ==================== USER MODEL ====================
class UserModel {
  final String id;
  final String phone;
  final String? name;
  final String? profilePhoto;
  final String vehicleType;
  final String? vehicleReg;
  final double ratingAvg;
  final int totalHelps;
  final double walletBalance;
  final String language;           // 'en','hi','pa','ta','te','bn'
  final bool isVerified;
  final String status;

  UserModel({
    required this.id,
    required this.phone,
    this.name,
    this.profilePhoto,
    this.vehicleType = 'car',
    this.vehicleReg,
    this.ratingAvg = 0.0,
    this.totalHelps = 0,
    this.walletBalance = 0.0,
    this.language = 'en',          // Default: Hindi
    this.isVerified = false,
    this.status = 'active',
  });

  // Convenience getter → AppLanguage enum
  AppLanguage get appLanguage => AppLanguageExt.fromCode(language);

  // copyWith to update language without recreating whole object
  UserModel copyWith({String? language}) => UserModel(
    id: id, phone: phone, name: name,
    profilePhoto: profilePhoto, vehicleType: vehicleType,
    vehicleReg: vehicleReg, ratingAvg: ratingAvg,
    totalHelps: totalHelps, walletBalance: walletBalance,
    language: language ?? this.language,
    isVerified: isVerified, status: status,
  );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    phone: json['phone'],
    name: json['name'],
    profilePhoto: json['profile_photo'],
    vehicleType: json['vehicle_type'] ?? 'car',
    vehicleReg: json['vehicle_reg'],
    ratingAvg: (json['rating_avg'] ?? 0.0).toDouble(),
    totalHelps: json['total_helps'] ?? 0,
    walletBalance: (json['wallet_balance'] ?? 0.0).toDouble(),
    language: json['language'] ?? 'en',
    isVerified: json['is_verified'] ?? false,
    status: json['status'] ?? 'active',
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'phone': phone, 'name': name,
    'profile_photo': profilePhoto, 'vehicle_type': vehicleType,
    'vehicle_reg': vehicleReg, 'rating_avg': ratingAvg,
    'total_helps': totalHelps, 'wallet_balance': walletBalance,
    'language': language, 'is_verified': isVerified, 'status': status,
  };
}

// ==================== JOB MODEL ====================
enum JobStatus { pending, matched, inProgress, completed, cancelled }

class HelpJob {
  final String id;
  final String requesterId;
  final String? helperId;
  final JobStatus status;
  final String problemType;
  final String? problemDesc;
  final double reqLat;
  final double reqLng;
  final String? highwayName;
  final double rewardAmount;
  final String? helperOtp;
  final DateTime createdAt;
  final UserModel? requester;
  final UserModel? helper;
  final double? distanceKm;
  final int? estimatedEta;

  HelpJob({
    required this.id, required this.requesterId, this.helperId,
    required this.status, required this.problemType, this.problemDesc,
    required this.reqLat, required this.reqLng, this.highwayName,
    required this.rewardAmount, this.helperOtp, required this.createdAt,
    this.requester, this.helper, this.distanceKm, this.estimatedEta,
  });

  factory HelpJob.fromJson(Map<String, dynamic> json) {
    final statusMap = {
      'pending': JobStatus.pending, 'matched': JobStatus.matched,
      'in_progress': JobStatus.inProgress, 'completed': JobStatus.completed,
      'cancelled': JobStatus.cancelled,
    };
    return HelpJob(
      id: json['id'], requesterId: json['requester_id'],
      helperId: json['helper_id'],
      status: statusMap[json['status']] ?? JobStatus.pending,
      problemType: json['problem_type'], problemDesc: json['problem_desc'],
      reqLat: (json['req_lat']).toDouble(), reqLng: (json['req_lng']).toDouble(),
      highwayName: json['highway_name'],
      rewardAmount: (json['reward_amount']).toDouble(),
      helperOtp: json['helper_otp'],
      createdAt: DateTime.parse(json['created_at']),
      requester: json['requester'] != null ? UserModel.fromJson(json['requester']) : null,
      helper: json['helper'] != null ? UserModel.fromJson(json['helper']) : null,
      distanceKm: json['distance_km']?.toDouble(),
      estimatedEta: json['estimated_eta'],
    );
  }
}

// ==================== MECHANIC MODEL ====================
class MechanicModel {
  final String id; final String userId; final String shopName;
  final String shopAddress; final double lat; final double lng;
  final List<String> specializations; final List<String> vehicleTypes;
  final bool isMobile; final String subscriptionTier;
  final bool isVerified; final double ratingAvg;
  final int totalJobs; final bool isOpen;
  final String? phone; final double? distanceKm;

  MechanicModel({
    required this.id, required this.userId, required this.shopName,
    required this.shopAddress, required this.lat, required this.lng,
    this.specializations = const [], this.vehicleTypes = const [],
    this.isMobile = false, this.subscriptionTier = 'free',
    this.isVerified = false, this.ratingAvg = 0.0,
    this.totalJobs = 0, this.isOpen = false, this.phone, this.distanceKm,
  });

  factory MechanicModel.fromJson(Map<String, dynamic> json) => MechanicModel(
    id: json['id'], userId: json['user_id'],
    shopName: json['shop_name'], shopAddress: json['shop_address'],
    lat: (json['lat']).toDouble(), lng: (json['lng']).toDouble(),
    specializations: List<String>.from(json['specializations'] ?? []),
    vehicleTypes: List<String>.from(json['vehicle_types'] ?? []),
    isMobile: json['is_mobile'] ?? false,
    subscriptionTier: json['subscription_tier'] ?? 'free',
    isVerified: json['is_verified'] ?? false,
    ratingAvg: (json['rating_avg'] ?? 0.0).toDouble(),
    totalJobs: json['total_jobs'] ?? 0,
    isOpen: json['is_open'] ?? false,
    phone: json['phone'], distanceKm: json['distance_km']?.toDouble(),
  );
}

// ==================== CHAT MESSAGE ====================
class ChatMessage {
  final String id;
  final String role;   // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final bool isVoice;

  ChatMessage({
    required this.id, required this.role,
    required this.content, required this.timestamp,
    this.isVoice = false,
  });
}

// ==================== PROBLEM TYPES (MULTILINGUAL) ====================
class ProblemType {
  final String id;
  final String label;           // English
  final String labelHindi;      // हिंदी
  final String labelPunjabi;    // ਪੰਜਾਬੀ
  final String labelTamil;      // தமிழ்
  final String labelTelugu;     // తెలుగు
  final String labelBengali;    // বাংলা
  final String icon;
  final double suggestedReward;

  const ProblemType({
    required this.id,
    required this.label,
    required this.labelHindi,
    required this.labelPunjabi,
    required this.labelTamil,
    required this.labelTelugu,
    required this.labelBengali,
    required this.icon,
    required this.suggestedReward,
  });

  // Get label for any AppLanguage
  String labelFor(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.hindi:   return labelHindi;
      case AppLanguage.punjabi: return labelPunjabi;
      case AppLanguage.tamil:   return labelTamil;
      case AppLanguage.telugu:  return labelTelugu;
      case AppLanguage.bengali: return labelBengali;
      default:                  return label;
    }
  }

  static const List<ProblemType> all = [
    ProblemType(
      id: 'puncture', icon: '🔧', suggestedReward: 150,
      label: 'Puncture',        labelHindi: 'पंचर',
      labelPunjabi: 'ਪੰਕਚਰ',   labelTamil: 'பஞ்சர்',
      labelTelugu: 'పంక్చర్',  labelBengali: 'পাংচার',
    ),
    ProblemType(
      id: 'fuel', icon: '⛽', suggestedReward: 200,
      label: 'No Fuel',         labelHindi: 'पेट्रोल खत्म',
      labelPunjabi: 'ਤੇਲ ਖਤਮ', labelTamil: 'எண்ணெய் இல்லை',
      labelTelugu: 'ఇంధనం లేదు', labelBengali: 'জ্বালানি নেই',
    ),
    ProblemType(
      id: 'breakdown', icon: '🚗', suggestedReward: 300,
      label: 'Breakdown',         labelHindi: 'गाड़ी बंद',
      labelPunjabi: 'ਗੱਡੀ ਬੰਦ', labelTamil: 'வண்டி நின்றது',
      labelTelugu: 'వాహనం ఆగింది', labelBengali: 'গাড়ি বন্ধ',
    ),
    ProblemType(
      id: 'battery', icon: '🔋', suggestedReward: 200,
      label: 'Dead Battery',        labelHindi: 'बैटरी डाउन',
      labelPunjabi: 'ਬੈਟਰੀ ਡਾਊਨ', labelTamil: 'பேட்டரி டவுன்',
      labelTelugu: 'బ్యాటరీ డౌన్', labelBengali: 'ব্যাটারি ডাউন',
    ),
    ProblemType(
      id: 'accident', icon: '⚠️', suggestedReward: 500,
      label: 'Accident',             labelHindi: 'एक्सीडेंट',
      labelPunjabi: 'ਹਾਦਸਾ',        labelTamil: 'விபத்து',
      labelTelugu: 'ప్రమాదం',       labelBengali: 'দুর্ঘটনা',
    ),
    ProblemType(
      id: 'towing', icon: '🚛', suggestedReward: 400,
      label: 'Need Towing',          labelHindi: 'टोइंग चाहिए',
      labelPunjabi: 'ਟੋਇੰਗ ਚਾਹੀਦਾ', labelTamil: 'இழுவை வேண்டும்',
      labelTelugu: 'టోయింగ్ కావాలి', labelBengali: 'টোয়িং দরকার',
    ),
    ProblemType(
      id: 'other', icon: '❓', suggestedReward: 200,
      label: 'Other',          labelHindi: 'अन्य',
      labelPunjabi: 'ਹੋਰ',    labelTamil: 'மற்றவை',
      labelTelugu: 'ఇతర',     labelBengali: 'অন্যান্য',
    ),
  ];
}

// ==================== SHOP MODELS ====================

enum OrderStatus { pending, confirmed, packed, shipped, delivered, cancelled }

class ProductCategory {
  final String id;
  final String name;
  final String icon;
  const ProductCategory({required this.id, required this.name, required this.icon});

  static const List<ProductCategory> all = [
    ProductCategory(id: 'cleaning', name: 'Car Cleaning', icon: '🧹'),
    ProductCategory(id: 'accessories', name: 'Accessories', icon: '🔧'),
    ProductCategory(id: 'tyres', name: 'Tyres & Tubes', icon: '🛞'),
    ProductCategory(id: 'electrical', name: 'Electrical', icon: '⚡'),
    ProductCategory(id: 'oils', name: 'Oils & Fluids', icon: '🛢️'),
    ProductCategory(id: 'safety', name: 'Safety', icon: '⛑️'),
  ];
}

class Product {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final double price;
  final double? discountPrice;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final String brand;

  // ── Affiliate fields ──────────────────────────────────
  final String amazonUrl;      // Amazon affiliate link (tag=raahi-21)
  final String? flipkartUrl;   // Flipkart affiliate link (optional)
  final String source;         // 'amazon' | 'flipkart' | 'both'

  const Product({
    required this.id, required this.name, required this.description,
    required this.categoryId, required this.price, this.discountPrice,
    required this.imageUrl, this.rating = 0.0, this.reviewCount = 0,
    this.inStock = true, required this.brand,
    required this.amazonUrl, this.flipkartUrl, this.source = 'amazon',
  });

  double get finalPrice => discountPrice ?? price;
  int get discountPercent => discountPrice != null
      ? ((price - discountPrice!) / price * 100).round() : 0;

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'], name: j['name'], description: j['description'],
    categoryId: j['category_id'], price: (j['price']).toDouble(),
    discountPrice: j['discount_price']?.toDouble(),
    imageUrl: j['image_url'] ?? '',
    rating: (j['rating'] ?? 0.0).toDouble(),
    reviewCount: j['review_count'] ?? 0,
    inStock: j['in_stock'] ?? true,
    brand: j['brand'] ?? '',
    amazonUrl: j['amazon_url'] ?? '',
    flipkartUrl: j['flipkart_url'],
    source: j['source'] ?? 'amazon',
  );
}

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});

  double get total => product.finalPrice * quantity;
}

class ShopOrder {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final OrderStatus status;
  final String paymentMethod; // 'cod' or 'online'
  final String? paymentId;
  final String deliveryAddress;
  final DateTime createdAt;

  ShopOrder({
    required this.id, required this.items, required this.totalAmount,
    required this.status, required this.paymentMethod, this.paymentId,
    required this.deliveryAddress, required this.createdAt,
  });

  factory ShopOrder.fromJson(Map<String, dynamic> j) => ShopOrder(
    id: j['id'],
    items: [],
    totalAmount: (j['total_amount']).toDouble(),
    status: OrderStatus.values.firstWhere(
      (s) => s.name == j['status'], orElse: () => OrderStatus.pending),
    paymentMethod: j['payment_method'],
    paymentId: j['payment_id'],
    deliveryAddress: j['delivery_address'],
    createdAt: DateTime.parse(j['created_at']),
  );
}
