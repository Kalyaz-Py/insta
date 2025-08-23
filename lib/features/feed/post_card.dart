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

    final pid = widget.post['id'] as int;
    try {
      if (likedByMe) {
        await supabase.from('likes').delete().match({'user_id': user.id, 'post_id': pid});
        setState(() {
          likedByMe = false;
          likeCount = (likeCount - 1).clamp(0, 1 << 31);
        });
      } else {
        await supabase.from('likes').insert({'user_id': user.id, 'post_id': pid});
        setState(() {
          likedByMe = true;
          likeCount += 1;
        });
      }
      await widget.onChanged?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка лайка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authorName = widget.post['author_username'] ?? '';
    final avatar = widget.post['author_avatar_url'] as String?;
    final imageUrl = widget.post['image_url'] as String;
    final caption = widget.post['caption'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(backgroundImage: (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null),
            title: Text(authorName),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(imageUrl, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(caption),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _toggleLike,
                icon: Icon(likedByMe ? Icons.favorite : Icons.favorite_border),
                color: likedByMe ? Colors.red : null,
              ),
              Text('$likeCount'),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  (widget.post['created_at'] ?? '').toString().split('.').first.replaceFirst('T', ' '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
