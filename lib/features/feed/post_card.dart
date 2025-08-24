import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../common/follow_button.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final Future<void> Function()? onChanged;

  const PostCard({
    super.key,
    required this.post,
    this.onChanged,
  });

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

    final postId = widget.post['id'];
    try {
      if (likedByMe) {
        // оптимистичное обновление
        setState(() {
          likedByMe = false;
          likeCount = (likeCount - 1).clamp(0, 1 << 30);
        });
        await supabase.from('likes').delete().match({
          'user_id': user.id,
          'post_id': postId,
        });
      } else {
        setState(() {
          likedByMe = true;
          likeCount += 1;
        });
        await supabase.from('likes').insert({
          'user_id': user.id,
          'post_id': postId,
        });
      }

      // если нужно синхронизировать с БД/рефрешнуть ленту
      // await widget.onChanged?.call();
    } catch (e) {
      // откат при ошибке
      setState(() {
        if (likedByMe) {
          likedByMe = false;
          likeCount = (likeCount - 1).clamp(0, 1 << 30);
        } else {
          likedByMe = true;
          likeCount += 1;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка лайка: $e')),
        );
      }
    }
  }

  Widget _header({
    required String username,
    required String? avatarUrl,
    required String? authorId,
    required String createdText,
  }) {
    return Stack(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: CircleAvatar(
            backgroundImage:
            (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
            child: (avatarUrl == null || avatarUrl.isEmpty)
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(username, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            createdText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (authorId != null && authorId.isNotEmpty)
          Positioned(
            right: 12,
            top: 8,
            child: FollowButton(authorId: authorId),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = (widget.post['author_username'] ?? '') as String;
    final avatar = widget.post['author_avatar_url'] as String?;
    final authorId = widget.post['author_id']?.toString();
    final imageUrl = (widget.post['image_url'] ?? '') as String;
    final caption = (widget.post['caption'] ?? '') as String;
    final createdText = (widget.post['created_at'] ?? '')
        .toString()
        .replaceFirst('T', ' ')
        .split('.')
        .first;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            username: username,
            avatarUrl: avatar,
            authorId: authorId,
            createdText: createdText,
          ),

          if (imageUrl.isNotEmpty)
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),

          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Text(caption),
            ),

          // лайк + счётчик
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: likedByMe ? 'Убрать лайк' : 'Лайк',
                  onPressed: _toggleLike,
                  icon: Icon(likedByMe ? Icons.favorite : Icons.favorite_border),
                  color: likedByMe ? Colors.red : null,
                ),
                Text('$likeCount'),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
