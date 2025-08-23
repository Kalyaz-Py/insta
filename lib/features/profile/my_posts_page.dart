import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  List<Map<String, dynamic>> posts = [];
  bool loading = false;

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final me = supabase.auth.currentUser!;
      final res = await supabase
          .from('posts')
          .select('id, image_url, caption, like_count, created_at')
          .eq('author_id', me.id)
          .order('created_at', ascending: false);
      posts = (res as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить посты: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _openDetails(Map<String, dynamic> post) {
    // ТВОЁ МЕСТО: здесь делай push на свой экран детали
    // Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailsPage(post: post)));
    // или покажи bottom sheet:
    // showModalBottomSheet(context: context, builder: (_) => YourDetails(post: post));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои посты')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : posts.isEmpty
          ? const Center(child: Text('Постов пока нет'))
          : ListView.separated(
        itemCount: posts.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final p = posts[i];
          return ListTile(
            leading: (p['image_url'] as String?)?.isNotEmpty == true
                ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(p['image_url'], width: 56, height: 56, fit: BoxFit.cover),
            )
                : const SizedBox(width: 56, height: 56),
            title: Text((p['caption'] as String?)?.isNotEmpty == true ? p['caption'] : 'Без подписи'),
            subtitle: Text('Лайков: ${p['like_count'] ?? 0}   •   ${(p['created_at'] ?? '').toString().split(".").first.replaceFirst("T", " ")}'),
            trailing: TextButton(
              onPressed: () => _openDetails(p),
              child: const Text('Подробнее'),
            ),
          );
        },
      ),
    );
  }
}
