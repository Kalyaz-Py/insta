import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../post/create_post_page.dart';
import '../profile/profile_page.dart';
import 'post_card.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<dynamic> posts = [];
  bool loading = false;

  Future<void> _loadFeed() async {
    setState(() => loading = true);
    try {
      // Читаем из VIEW feed (колонки уже "раскрыты")
      final res = await supabase.from('feed').select();
      posts = res as List<dynamic>;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось загрузить ленту: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  void _openCreatePost() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostPage()));
    _loadFeed();
  }

  void _openProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Лента'),
        actions: [
          IconButton(onPressed: _openProfile, icon: const Icon(Icons.person_outline)),
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: posts.length,
          itemBuilder: (_, i) => PostCard(post: posts[i], onChanged: _loadFeed),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreatePost,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
