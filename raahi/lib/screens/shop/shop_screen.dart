// ============================================================
// lib/screens/shop/shop_screen.dart  (AFFILIATE VERSION)
// ============================================================
// Flow:
//   Browse products → Add to cart → "Buy on Amazon" tap
//   → Ek URL banata hai saare products ka
//   → Amazon pe redirect — sab already cart mein
//   → User checkout kare → Tera commission milta rahe
// ============================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/affiliate_service.dart';

// ── In-Memory Cart ─────────────────────────────────────────
class CartManager {
  static final CartManager _i = CartManager._();
  factory CartManager() => _i;
  CartManager._();

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  void add(Product p) {
    final idx = _items.indexWhere((i) => i.product.id == p.id);
    if (idx >= 0) _items[idx].quantity++;
    else _items.add(CartItem(product: p));
  }

  void remove(String id) => _items.removeWhere((i) => i.product.id == id);

  void updateQty(String id, int qty) {
    if (qty <= 0) { remove(id); return; }
    final idx = _items.indexWhere((i) => i.product.id == id);
    if (idx >= 0) _items[idx].quantity = qty;
  }

  void clear() => _items.clear();

  int get count  => _items.fold(0, (s, i) => s + i.quantity);
  double get total => _items.fold(0.0, (s, i) => s + i.total);
  bool has(String id) => _items.any((i) => i.product.id == id);
  int qtyOf(String id) {
    final idx = _items.indexWhere((i) => i.product.id == id);
    return idx >= 0 ? _items[idx].quantity : 0;
  }
}

// ════════════════════════════════════════════════════════════
// SHOP SCREEN
// ════════════════════════════════════════════════════════════
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _cart      = CartManager();
  final _affiliate = AffiliateService();
  final _searchCtrl = TextEditingController();

  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _redirecting = false;

  List<Product> _products = [];
  bool _loading = false;

  Future<void> _loadProducts({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    try {
      final products = await _affiliate.loadProducts(
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        forceRefresh: forceRefresh,
      );
      if (mounted) setState(() { _products = products; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── "Buy All on Amazon" ───────────────────────────────────
  Future<void> _buyOnAmazon() async {
    if (_cart.count == 0) {
      _snack('Pehle kuch products add karo!');
      return;
    }
    setState(() => _redirecting = true);

    final result = await _affiliate.openAmazonCart(
        CartManager()._items);

    setState(() => _redirecting = false);

    if (!result.success) {
      _snack(result.message);
    } else {
      // Show confirmation bottom sheet
      _showRedirectSheet(result);
    }
  }

  void _showRedirectSheet(AffiliateRedirectResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('🛒', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('Amazon pe Redirect Ho Raha Hai!',
              style: TextStyle(color: AppTheme.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            '${result.itemCount} products Amazon cart mein\nadd ho jaayenge — ek baar mein!',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary,
                fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.green.withOpacity(0.25)),
            ),
            child: const Row(children: [
              Text('💰', style: TextStyle(fontSize: 18)),
              SizedBox(width: 10),
              Expanded(child: Text(
                'Amazon pe buy karte ho toh Raahi ko commission milta hai — tere liye koi extra cost nahi!',
                style: TextStyle(color: AppTheme.green,
                    fontSize: 11, height: 1.4),
              )),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cart.clear();
                setState(() {});
              },
              child: const Text('Done — Cart Clear Karo ✓',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.cardBg,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  // ── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: AppTheme.saffron,
        backgroundColor: AppTheme.cardBg,
        onRefresh: () => _loadProducts(forceRefresh: true),
        child: Column(children: [
        _buildSearchBar(),
        _buildCategoryChips(),
        Expanded(child: _loading ? _buildShimmer() : _buildProductGrid()),
      ]),
      ),
      floatingActionButton: _cart.count > 0
          ? _buildBuyButton()
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.navyLight,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Raahi Shop 🛒',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text('Powered by Amazon',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        ],
      ),
      actions: [
        // Cart count badge
        if (_cart.count > 0)
          GestureDetector(
            onTap: () => _showCartSheet(),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.saffron.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.saffron.withOpacity(0.4)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.shopping_cart_rounded,
                    color: AppTheme.saffron, size: 16),
                const SizedBox(width: 5),
                Text('${_cart.count}',
                    style: const TextStyle(
                        color: AppTheme.saffron,
                        fontWeight: FontWeight.w800, fontSize: 13)),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: AppTheme.textPrimary),
        onChanged: (v) {
          setState(() => _searchQuery = v);
          _loadProducts();
        },
        decoration: InputDecoration(
          hintText: 'Car products search karo...',
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppTheme.textMuted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppTheme.textMuted, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                    _loadProducts();
                  })
              : null,
          filled: true, fillColor: AppTheme.cardBg,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.cardBorder),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final cats = [
      const ProductCategory(id: 'all', name: 'All', icon: '🛍️'),
      ...ProductCategory.all,
    ];
    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final c = cats[i];
          final sel = _selectedCategory == c.id;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedCategory = c.id);
              _loadProducts();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: sel ? AppTheme.saffron : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? AppTheme.saffron : AppTheme.cardBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(c.icon, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 5),
                Text(c.name, style: TextStyle(
                    color: sel ? Colors.white : AppTheme.textSecondary,
                    fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    final products = _products;
    if (products.isEmpty) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📦', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('Koi product nahi mila',
              style: TextStyle(color: AppTheme.textMuted)),
        ],
      ));
    }
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, _cart.count > 0 ? 90 : 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12,
        mainAxisSpacing: 12, childAspectRatio: 0.68,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => _ProductCard(
        product: products[i],
        qty: _cart.qtyOf(products[i].id),
        onAdd: () => setState(() => _cart.add(products[i])),
        onRemove: () => setState(() {
          final cur = _cart.qtyOf(products[i].id);
          _cart.updateQty(products[i].id, cur - 1);
        }),
      ),
    );
  }


  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12,
        mainAxisSpacing: 12, childAspectRatio: 0.68,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Expanded(flex: 5, child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0D1B2A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
            ),
          )),
          Expanded(flex: 5, child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(3, (i) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                height: 10,
                width: i == 0 ? double.infinity : 60.0 + i * 20,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
          )),
        ]),
      ),
    );
  }

  // ── Floating Buy Button ───────────────────────────────────
  Widget _buildBuyButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _redirecting ? null : _buyOnAmazon,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF9900), // Amazon orange
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 8,
            shadowColor: const Color(0xFFFF9900).withOpacity(0.4),
          ),
          child: _redirecting
              ? const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2)
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('🛒', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(
                    'Buy ${_cart.count} Item${_cart.count > 1 ? "s" : ""} on Amazon',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹${_cart.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
        ),
      ),
    );
  }

  // ── Cart Bottom Sheet ─────────────────────────────────────
  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navyLight,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollCtrl) => Column(children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(children: [
                Text('Cart (${_cart.count} items)',
                    style: const TextStyle(color: AppTheme.textPrimary,
                        fontSize: 17, fontWeight: FontWeight.w800)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => _cart.clear());
                    setModalState(() {});
                    Navigator.pop(ctx);
                  },
                  child: const Text('Clear All',
                      style: TextStyle(color: AppTheme.red, fontSize: 12)),
                ),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _cart.items.length,
                itemBuilder: (_, i) {
                  final item = _cart.items[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(children: [
                      Container(width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.navy,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                              child: Text('📦',
                                  style: TextStyle(fontSize: 22)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.product.name,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12, fontWeight: FontWeight.w700),
                                maxLines: 2),
                            Text('₹${item.product.finalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: AppTheme.saffron,
                                    fontWeight: FontWeight.w800)),
                          ])),
                      // Qty controls
                      Row(children: [
                        _qtyBtn(Icons.remove_rounded, () {
                          setState(() => _cart.updateQty(
                              item.product.id, item.quantity - 1));
                          setModalState(() {});
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('${item.quantity}',
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700)),
                        ),
                        _qtyBtn(Icons.add_rounded, () {
                          setState(() => _cart.add(item.product));
                          setModalState(() {});
                        }),
                      ]),
                    ]),
                  );
                },
              ),
            ),
            // Buy button inside sheet
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _buyOnAmazon();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9900),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    '🛒  Buy on Amazon — ₹${_cart.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: AppTheme.navy,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Icon(icon, size: 14, color: AppTheme.textSecondary),
    ),
  );
}

// ════════════════════════════════════════════════════════════
// PRODUCT CARD
// ════════════════════════════════════════════════════════════
class _ProductCard extends StatelessWidget {
  final Product product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ProductCard({
    required this.product, required this.qty,
    required this.onAdd, required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: qty > 0
              ? AppTheme.saffron.withOpacity(0.4)
              : AppTheme.cardBorder,
          width: qty > 0 ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            child: Stack(
              children: [
                Container(
                  height: 110, width: double.infinity,
                  color: const Color(0xFF0D1B2A),
                  child: const Center(
                      child: Text('📦',
                          style: TextStyle(fontSize: 36))),
                ),
                // Discount badge
                if (product.discountPercent > 0)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.green,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text('-${product.discountPercent}%',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                // Amazon badge
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9900),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('amazon',
                        style: TextStyle(
                            color: Colors.white, fontSize: 8,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 11, fontWeight: FontWeight.w700),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(product.brand,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 9)),
                const SizedBox(height: 4),
                // Rating
                Row(children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFF9900), size: 12),
                  const SizedBox(width: 2),
                  Text('${product.rating}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 10)),
                  Text(' (${product.reviewCount})',
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 9)),
                ]),
                const SizedBox(height: 5),
                Row(children: [
                  Text('₹${product.finalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppTheme.saffron,
                          fontSize: 14, fontWeight: FontWeight.w800)),
                  if (product.discountPrice != null) ...[
                    const SizedBox(width: 4),
                    Text('₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 10,
                            decoration: TextDecoration.lineThrough)),
                  ],
                ]),
              ],
            ),
          ),
          const Spacer(),
          // Add/Qty controls
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: qty == 0
                ? SizedBox(
                    width: double.infinity, height: 34,
                    child: ElevatedButton(
                      onPressed: onAdd,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('+ Add',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  )
                : Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.saffron.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.saffron.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: onRemove,
                          child: Container(
                            width: 34, height: 34,
                            alignment: Alignment.center,
                            child: const Icon(Icons.remove_rounded,
                                color: AppTheme.saffron, size: 16),
                          ),
                        ),
                        Text('$qty',
                            style: const TextStyle(
                                color: AppTheme.saffron,
                                fontWeight: FontWeight.w800, fontSize: 14)),
                        GestureDetector(
                          onTap: onAdd,
                          child: Container(
                            width: 34, height: 34,
                            alignment: Alignment.center,
                            child: const Icon(Icons.add_rounded,
                                color: AppTheme.saffron, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════
// AMAZON PRODUCT IMAGE WIDGET
// ════════════════════════════════════════════════════════════
// Amazon CDN se ASIN ke basis pe image load karta hai
// Format: https://images-na.ssl-images-amazon.com/images/P/{ASIN}.jpg
// ════════════════════════════════════════════════════════════
class _AmazonProductImage extends StatelessWidget {
  final String asin;
  const _AmazonProductImage({required this.asin});

  // Amazon product image URL from ASIN
  String get _imageUrl =>
      'https://images-na.ssl-images-amazon.com/images/P/$asin.01.L.jpg';

  // Fallback URLs to try
  List<String> get _fallbacks => [
    'https://images-na.ssl-images-amazon.com/images/P/$asin.01.M.jpg',
    'https://images-na.ssl-images-amazon.com/images/P/$asin.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: _imageUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => Container(
        color: const Color(0xFF0D1B2A),
        child: const Center(
          child: SizedBox(
            width: 24, height: 24,
            child: CircularProgressIndicator(
              color: AppTheme.saffron,
              strokeWidth: 2,
            ),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xFF0D1B2A),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined,
                color: AppTheme.textMuted, size: 32),
            const SizedBox(height: 4),
            Text('amazon', style: TextStyle(
                color: AppTheme.textMuted.withOpacity(0.5),
                fontSize: 9)),
          ],
        ),
      ),
    );
  }
}
