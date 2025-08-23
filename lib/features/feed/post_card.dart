import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final Future<void> Function()? onChanged;

  const PostCard({super.key, required this.post, this.onChanged});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool likedByMe;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    likedByMe = widget.post['liked_by_me'] as bool? ?? false;
    likeCount = widget.post['like_count'] as int? ?? 0;
  }

  Future<void> _toggleLike() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final postId = widget.post['id'] as int;
    try {
      if (likedByMe) {
        await supabase.from('likes').delete().match({
          'user_id': user.id,
          'post_id': postId,
        });
        setState(() {
          likedByMe = false;
          likeCount = (likeCount - 1).clamp(0, 1 << 30);
        });
      } else {
        await supabase.from('likes').insert({
          'user_id': user.id,
          'post_id': postId,
        });
        setState(() {
          likedByMe = true;
          likeCount += 1;
        });
      }
      // Перезагрузим ленту сверху, если передан колбэк
      await widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка лайка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final username = (widget.post['author_username'] ?? '') as String;
    final avatar = widget.post['author_avatar_url'] as String?;
    final imageUrl = widget.post['image_url'] as String? ?? '';
    final caption = widget.post['caption'] as String? ?? '';
    final created = (widget.post['created_at'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
              (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
              child: (avatar == null || avatar.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(username),
            subtitle: Text(created.replaceFirst('T', ' ').split('.').first),
          ),
          if (imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(caption),
            ),
          Row(
            children: [
              IconButton(
                tooltip: likedByMe ? 'Убрать лайк' : 'Лайк',
                onPressed: _toggleLike,
                icon: Icon(likedByMe ? Icons.favorite : Icons.favorite_border),
                color: likedByMe ? Colors.red : null,
              ),
              Text('$likeCount'),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
