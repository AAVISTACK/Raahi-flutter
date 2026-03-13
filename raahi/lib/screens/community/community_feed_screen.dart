// ============================================================
// FILE: lib/screens/community/community_feed_screen.dart
// Driver Community Feed — highway alerts, tips, help requests
// ============================================================

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

enum PostCategory { alert, tip, found, general }

extension PostCategoryExt on PostCategory {
  String get label {
    switch (this) {
      case PostCategory.alert:  return '🚨 Alert';
      case PostCategory.tip:    return '💡 Tip';
      case PostCategory.found:  return '🔍 Mila Kuch';
      case PostCategory.general: return '💬 General';
    }
  }
  Color get color {
    switch (this) {
      case PostCategory.alert:   return AppTheme.red;
      case PostCategory.tip:     return AppTheme.green;
      case PostCategory.found:   return AppTheme.cyan;
      case PostCategory.general: return AppTheme.saffron;
    }
  }
}

class CommunityFeedScreen extends StatefulWidget {
  const CommunityFeedScreen({super.key});

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _textCtrl = TextEditingController();
  PostCategory _selectedCategory = PostCategory.alert;
  bool _isPosting = false;
  bool _isLoading = true;

  // Mock posts — real mein backend se aayenge
  final List<Map<String, dynamic>> _posts = [
    {
      'id': '1',
      'author': 'Rajesh (Truck)',
      'avatar': 'R',
      'category': PostCategory.alert,
      'text': 'NH-44 Ambala ke paas bada jam hai — 2 ghante se phaas hoon. Bachke niklo!',
      'time': '5 min pehle',
      'likes': 12,
      'liked': false,
      'location': 'Ambala, Haryana',
    },
    {
      'id': '2',
      'author': 'Gurpreet Singh',
      'avatar': 'G',
      'category': PostCategory.tip,
      'text': 'Ludhiana bypass pe naya dhaba khula hai — "Punjabi Tadka". Sasta aur swaadisht. Highly recommend!',
      'time': '23 min pehle',
      'likes': 31,
      'liked': true,
      'location': 'Ludhiana, Punjab',
    },
    {
      'id': '3',
      'author': 'Manoj Driver',
      'avatar': 'M',
      'category': PostCategory.alert,
      'text': 'Fog alert: Panipat se Karnal ke beech zero visibility hai subah 5-8 baje. Speed kum rakhna bhai log.',
      'time': '1 ghanta pehle',
      'likes': 47,
      'liked': false,
      'location': 'Panipat-Karnal, NH-44',
    },
    {
      'id': '4',
      'author': 'Suresh Yadav',
      'avatar': 'S',
      'category': PostCategory.found,
      'text': 'Kisi ka green colour ka bag mila hai NH-8 pe Manesar toll ke paas. Andar ID card hai. Owner contact kare: 9876XXXXXX',
      'time': '2 ghante pehle',
      'likes': 8,
      'liked': false,
      'location': 'Manesar, Haryana',
    },
    {
      'id': '5',
      'author': 'Karim Bhai',
      'avatar': 'K',
      'category': PostCategory.tip,
      'text': 'Raahu app se aaj pehli baar help mili! Tyre puncture tha — 15 min mein banda aa gaya. Bahut badhiya service hai.',
      'time': '3 ghante pehle',
      'likes': 63,
      'liked': false,
      'location': 'Rajasthan Highway',
    },
  ];

  List<Map<String, dynamic>> get _filteredPosts {
    final tab = _tabController.index;
    if (tab == 0) return _posts;
    final cats = [PostCategory.alert, PostCategory.tip, PostCategory.found, PostCategory.general];
    return _posts.where((p) => p['category'] == cats[tab - 1]).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() => setState(() {}));
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _submitPost() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isPosting = true);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _posts.insert(0, {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'author': 'Tum',
          'avatar': 'T',
          'category': _selectedCategory,
          'text': text,
          'time': 'Abhi',
          'likes': 0,
          'liked': false,
          'location': 'Tumhari location',
        });
        _isPosting = false;
        _textCtrl.clear();
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post share ho gaya! 🎉'),
          backgroundColor: AppTheme.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _showPostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.navyLight,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: AppTheme.cardBorder,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Text('Kya share karna hai?',
                  style: TextStyle(color: AppTheme.textPrimary,
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),

              // Category chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: PostCategory.values.map((cat) {
                    final sel = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () {
                        setInner(() => _selectedCategory = cat);
                        setState(() => _selectedCategory = cat);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? cat.color.withOpacity(0.2) : AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel ? cat.color : AppTheme.cardBorder,
                              width: sel ? 1.5 : 1),
                        ),
                        child: Text(cat.label,
                            style: TextStyle(
                                color: sel ? cat.color : AppTheme.textSecondary,
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Text input
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: TextField(
                  controller: _textCtrl,
                  maxLines: 4,
                  maxLength: 280,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Highway pe kya ho raha hai? Dusre drivers ko batao...',
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                    counterStyle: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPosting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.saffron,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isPosting
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Share Karo',
                          style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navyLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver Community', style: TextStyle(
                color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Highway pe kya ho raha hai?',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.saffron,
          labelColor: AppTheme.saffron,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Sab'),
            Tab(text: '🚨 Alerts'),
            Tab(text: '💡 Tips'),
            Tab(text: '🔍 Mila Kuch'),
            Tab(text: '💬 General'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPostSheet,
        backgroundColor: AppTheme.saffron,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Post Karo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.saffron))
          : TabBarView(
              controller: _tabController,
              children: List.generate(5, (_) => _buildFeed()),
            ),
    );
  }

  Widget _buildFeed() {
    final posts = _filteredPosts;
    if (posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum_outlined, color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 12),
            const Text('Koi post nahi abhi', style: TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _showPostSheet,
              child: const Text('Pehla post karo!',
                  style: TextStyle(color: AppTheme.saffron)),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: posts.length,
      itemBuilder: (_, i) => _PostCard(
        post: posts[i],
        onLike: () => setState(() {
          posts[i]['liked'] = !posts[i]['liked'];
          posts[i]['likes'] += posts[i]['liked'] ? 1 : -1;
        }),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onLike;
  const _PostCard({required this.post, required this.onLike});

  @override
  Widget build(BuildContext context) {
    final cat = post['category'] as PostCategory;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cat.color.withOpacity(0.2),
                child: Text(post['avatar'],
                    style: TextStyle(color: cat.color, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post['author'], style: const TextStyle(
                        color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(post['time'], style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cat.color.withOpacity(0.3)),
                ),
                child: Text(cat.label,
                    style: TextStyle(color: cat.color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Post text
          Text(post['text'],
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.5)),
          const SizedBox(height: 8),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppTheme.textMuted, size: 13),
              const SizedBox(width: 3),
              Text(post['location'],
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),

          // Actions
          Row(
            children: [
              GestureDetector(
                onTap: onLike,
                child: Row(
                  children: [
                    Icon(
                      post['liked'] ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      color: post['liked'] ? AppTheme.red : AppTheme.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text('${post['likes']}',
                        style: TextStyle(
                            color: post['liked'] ? AppTheme.red : AppTheme.textMuted,
                            fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              const Icon(Icons.share_outlined, color: AppTheme.textMuted, size: 18),
              const SizedBox(width: 5),
              const Text('Share', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
