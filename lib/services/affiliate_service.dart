// ============================================================
// lib/services/affiliate_service.dart  (UPDATED)
// ============================================================
// NEW: Google Sheets se products automatically load hote hain
//
// Flow:
//   Google Sheet (tera phone se manage karo)
//       ↓
//   App start hote hi sheet fetch karta hai
//       ↓
//   Products show hote hain with affiliate links
//       ↓
//   Naya product add karna = sirf sheet mein ek row add karo
// ============================================================

import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';

class AffiliateService {
  static final AffiliateService _i = AffiliateService._();
  factory AffiliateService() => _i;
  AffiliateService._();

  // ── Config ─────────────────────────────────────────────
  // ⚠️ Apna Amazon Associates tag yahan daalo
  static const String _amazonTag = 'raahi-21';

  // ⚠️ Google Sheet ka published CSV URL yahan daalo
  // (Neeche setup guide mein bataya hai kaise banate hain)
  static const String _sheetCsvUrl =
      'YOUR_GOOGLE_SHEET_CSV_URL_HERE';

  // Cache — baar baar sheet fetch na ho
  List<Product> _cachedProducts = [];
  DateTime? _lastFetched;
  static const _cacheMinutes = 30; // 30 min cache

  // ── Load Products from Google Sheet ───────────────────
  Future<List<Product>> loadProducts({
    String? category,
    String? search,
    bool forceRefresh = false,
  }) async {
    // Use cache if fresh enough
    final now = DateTime.now();
    final cacheValid = _lastFetched != null &&
        now.difference(_lastFetched!).inMinutes < _cacheMinutes;

    if (!forceRefresh && cacheValid && _cachedProducts.isNotEmpty) {
      return _filterProducts(_cachedProducts, category, search);
    }

    try {
      final dio = Dio();
      final response = await dio.get(
        _sheetCsvUrl,
        options: Options(
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final products = _parseCsv(response.data as String);
      _cachedProducts = products;
      _lastFetched = now;
      return _filterProducts(products, category, search);
    } catch (e) {
      // Sheet fetch fail → fallback to cache → fallback to hardcoded
      if (_cachedProducts.isNotEmpty) return _cachedProducts;
      return _filterProducts(sampleProducts, category, search);
    }
  }

  // ── Parse CSV from Google Sheet ────────────────────────
  // Sheet columns (order must match):
  // name | category | price | discount_price | asin | brand |
  // rating | review_count | description | active
  List<Product> _parseCsv(String csv) {
    final products = <Product>[];
    final lines = csv.split('\n');

    // Skip header row (row 1)
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final cols = _splitCsvLine(line);
        if (cols.length < 9) continue;

        final name         = cols[0].trim();
        final category     = cols[1].trim().toLowerCase();
        final price        = double.tryParse(cols[2].trim()) ?? 0;
        final discountPrice = cols[3].trim().isEmpty
            ? null : double.tryParse(cols[3].trim());
        final asin         = cols[4].trim();
        final brand        = cols[5].trim();
        final rating       = double.tryParse(cols[6].trim()) ?? 4.0;
        final reviews      = int.tryParse(cols[7].trim()) ?? 0;
        final description  = cols[8].trim();
        final active       = cols.length > 9
            ? cols[9].trim().toLowerCase() != 'false' : true;

        if (!active || name.isEmpty || asin.isEmpty) continue;

        products.add(Product(
          id: asin,
          name: name,
          description: description,
          categoryId: category,
          price: price,
          discountPrice: discountPrice,
          imageUrl: '', // Amazon image dynamically from ASIN
          rating: rating,
          reviewCount: reviews,
          inStock: true,
          brand: brand,
          amazonUrl: 'https://www.amazon.in/dp/$asin?tag=$_amazonTag',
          source: 'amazon',
        ));
      } catch (_) {
        continue; // Skip malformed rows
      }
    }
    return products;
  }

  // Handle CSV lines with commas inside quotes
  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        result.add(current.toString());
        current.clear();
      } else {
        current.write(ch);
      }
    }
    result.add(current.toString());
    return result;
  }

  // Filter by category / search
  List<Product> _filterProducts(
      List<Product> all, String? category, String? search) {
    var filtered = all;
    if (category != null && category != 'all') {
      filtered = filtered.where((p) => p.categoryId == category).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      filtered = filtered.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q)).toList();
    }
    return filtered;
  }

  // ── Build Amazon Multi-Cart URL ────────────────────────
  String buildAmazonCartUrl(List<CartItem> items) {
    final validItems = items
        .where((i) => i.product.amazonUrl.isNotEmpty)
        .toList();
    if (validItems.isEmpty) return '';

    final buf = StringBuffer(
        'https://www.amazon.in/gp/aws/cart/add.html?');
    for (int i = 0; i < validItems.length; i++) {
      final asin = _extractAsin(validItems[i].product.amazonUrl)
          ?? validItems[i].product.id;
      buf.write('ASIN.${i + 1}=$asin&Quantity.${i + 1}=${validItems[i].quantity}');
      if (i < validItems.length - 1) buf.write('&');
    }
    buf.write('&AssociateTag=$_amazonTag');
    return buf.toString();
  }

  String? _extractAsin(String url) {
    if (url.isEmpty) return null;
    if (RegExp(r'^[B][A-Z0-9]{9}$').hasMatch(url)) return url;
    final dp = RegExp(r'/dp/([A-Z0-9]{10})').firstMatch(url);
    if (dp != null) return dp.group(1);
    return null;
  }

  // ── Open Amazon ───────────────────────────────────────
  Future<AffiliateRedirectResult> openAmazonCart(
      List<CartItem> items) async {
    final url = buildAmazonCartUrl(items);
    if (url.isEmpty) {
      return const AffiliateRedirectResult(
          success: false,
          message: 'Koi Amazon product nahi mila.',
          url: '');
    }
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return AffiliateRedirectResult(
            success: true,
            message: 'Amazon pe redirect...',
            url: url,
            itemCount: items.length);
      }
      throw Exception('launch failed');
    } catch (_) {
      return AffiliateRedirectResult(
          success: false,
          message: 'Amazon open nahi hua.',
          url: url);
    }
  }

  // ── Hardcoded fallback (jab sheet set na ho) ──────────
  static List<Product> get sampleProducts => [
    Product(id: 'B0CXYZ001', name: '3M Car Polish & Wax',
        description: 'Deep shine polish', categoryId: 'cleaning',
        price: 599, discountPrice: 449, imageUrl: '',
        rating: 4.3, reviewCount: 2847, brand: '3M', inStock: true,
        amazonUrl: 'https://www.amazon.in/dp/B0CXYZ001?tag=$_amazonTag',
        source: 'amazon'),
    Product(id: 'B0CXYZ002', name: 'Tyre Puncture Repair Kit',
        description: 'Emergency kit', categoryId: 'tyres',
        price: 399, discountPrice: 299, imageUrl: '',
        rating: 4.1, reviewCount: 5621, brand: 'Maruti', inStock: true,
        amazonUrl: 'https://www.amazon.in/dp/B0CXYZ002?tag=$_amazonTag',
        source: 'amazon'),
    Product(id: 'B0CXYZ003', name: 'Car Jump Starter 12000mAh',
        description: 'Dead battery solution', categoryId: 'electrical',
        price: 2999, discountPrice: 1899, imageUrl: '',
        rating: 4.5, reviewCount: 3102, brand: 'AUDEW', inStock: true,
        amazonUrl: 'https://www.amazon.in/dp/B0CXYZ003?tag=$_amazonTag',
        source: 'amazon'),
    Product(id: 'B0CXYZ004', name: 'Car Vacuum Cleaner',
        description: '120W wet & dry', categoryId: 'cleaning',
        price: 1299, discountPrice: 899, imageUrl: '',
        rating: 4.0, reviewCount: 8934, brand: 'Eureka Forbes',
        inStock: true,
        amazonUrl: 'https://www.amazon.in/dp/B0CXYZ004?tag=$_amazonTag',
        source: 'amazon'),
    Product(id: 'B0CXYZ005', name: 'Microfiber Cloths (10 Pack)',
        description: 'Scratch-free cleaning', categoryId: 'cleaning',
        price: 349, discountPrice: 199, imageUrl: '',
        rating: 4.4, reviewCount: 12450, brand: 'Boodaboo', inStock: true,
        amazonUrl: 'https://www.amazon.in/dp/B0CXYZ005?tag=$_amazonTag',
        source: 'amazon'),
    Product(id: 'B0CXYZ006', name: 'Dash Cam Full HD 1080p',
        description: 'Highway accident proof', categoryId: 'accessories',
        price: 3499, discountPrice: 1999, imageUrl: '',
        rating: 4.2, reviewCount: 4567, brand: 'Vantrue', inStock: true,
        amazonUrl: 'https://www.amazon.in/dp/B0CXYZ006?tag=$_amazonTag',
        source: 'amazon'),
    Product(id: 'B0CXYZ007', name: 'Castrol Engine Oil 5W-30 3.5L',
        description: 'Fully synthetic', categoryId: 'oils',
        price: 1599, discountPrice: 1249, imageUrl: '',
        rating: 4.6, reviewCount: 7823, brand: 'Castrol', inStock: true,
        amazonUrl: 'https://www.amazon.in/dp/B0CXYZ007?tag=$_amazonTag',
        source: 'amazon'),
    Product(id: 'B0CXYZ008', name: 'Car First Aid Kit',
        description: 'Highway emergency', categoryId: 'safety',
        price: 799, discountPrice: 549, imageUrl: '',
        rating: 4.3, reviewCount: 2341, brand: 'Apollo', inStock: true,
        amazonUrl: 'https://www.amazon.in/dp/B0CXYZ008?tag=$_amazonTag',
        source: 'amazon'),
  ];
}

class AffiliateRedirectResult {
  final bool success;
  final String message;
  final String url;
  final int itemCount;
  const AffiliateRedirectResult({
    required this.success, required this.message,
    required this.url, this.itemCount = 0,
  });
}
