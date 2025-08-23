import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../post/create_post_page.dart';

final supabase = Supabase.instance.client;

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<dynamic> _posts = [];
  Map<int, bool> _liked = {}; // постId -> лайкнуто ли мной

  Future<void> _load() async {
    // 1) посты из view feed
    final posts = await supabase
        .from('feed')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    // 2) мои лайки для этих постов
    final ids = (posts as List).map((p) => p['id'] as int).toList();
    Map<int, bool> liked = {};
    if (ids.isNotEmpty) {
      final List<dynamic> my = await supabase
          .from('likes')
          .select('post_id')
          .inFilter('post_id', ids);
      for (final row in my) {
        liked[row['post_id'] as int] = true;
      }
      setState(() {
        _posts = posts;
        _liked = liked;
      });
    }

    Future<void> _toggleLike(int postId) async {
      final isLiked = _liked[postId] == true;
      setState(() => _liked[postId] = !isLiked); // оптимистично
      try {
        final uid = supabase.auth.currentUser!.id;
        if (isLiked) {
          await supabase.from('likes').delete().match(
              {'user_id': uid, 'post_id': postId});
        } else {
          await supabase.from('likes').insert(
              {'user_id': uid, 'post_id': postId});
        }
        // счётчик обновится триггером, можно перезагрузить ленту
        await _load();
      } catch (_) {
        setState(() => _liked[postId] = isLiked); // откат при ошибке
      }
    }

    Future<void> _followOrUnfollow(String authorId) async {
      final me = supabase.auth.currentUser!.id;
      // проверим подписку
      final f = await supabase.from('follows').select().match({
        'follower_id': me,
        'followee_id': authorId,
      });
      if ((f as List).isEmpty) {
        await supabase.from('follows').insert(
            {'follower_id': me, 'followee_id': authorId});
      } else {
        await supabase.from('follows').delete().match(
            {'follower_id': me, 'followee_id': authorId});
      }
      await _load();
    }

    @override
    void initState() {
      super.initState();
      _load();
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(title: const Text('Лента')),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CreatePostPage()));
            await _load();
          },
          child: const Icon(Icons.add),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            itemCount: _posts.length,
            itemBuilder: (_, i) {
              final p = _posts[i];
              final postId = p['id'] as int;
              final authorId = p['author_id'] as String;
              final isLiked = _liked[postId] == true;
              return Card(
                margin: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (p['avatar_url'] as String?)
                            ?.isNotEmpty == true
                            ? NetworkImage(p['avatar_url'])
                            : null,
                        child: (p['avatar_url'] as String?)?.isNotEmpty == true
                            ? null
                            : const Icon(Icons.person),
                      ),
                      title: Text(p['username'] ?? ''),
                      trailing: TextButton(
                        onPressed: () => _followOrUnfollow(authorId),
                        child: const Text('Follow/Unfollow'),
                      ),
                    ),
                    CachedNetworkImage(
                        imageUrl: p['image_url'], fit: BoxFit.cover),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(p['caption'] ?? ''),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _toggleLike(postId),
                          icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border),
                        ),
                        Text('${p['like_count']}'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
