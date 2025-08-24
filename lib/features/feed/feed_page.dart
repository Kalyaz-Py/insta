import 'package:copiainsta/features/auth/login_page.dart';
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
      final me = supabase.auth.currentUser!;
      final data = await supabase.rpc('timeline_feed', params: {
        '_viewer': me.id,
        '_limit': 30,
        '_offset': 0,
      }) as List<dynamic>;

      setState(() => posts = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Не удалось загрузить ленту: $e')));
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
    String word = "vatafak";
    print(word);
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Лента'),
        actions: [
          // Кнопка Профиля
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: _openProfile,
            tooltip: 'Профиль',
          ),
          // Кнопка Выхода
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (_, i) {
            final post = posts[i] as Map<String, dynamic>;
            return PostCard(
              post: post,
              onChanged: _loadFeed, // чтобы счётчик лайков синхронизировался с БД
            );

          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreatePostPage()),
        ),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
