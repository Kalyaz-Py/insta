import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'edit_profile_page.dart';
import 'my_posts_page.dart';
import 'people_list_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? me;
  int followers = 0;
  int following = 0;
  bool loading = false;

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // профиль
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      me = (profile as Map<String, dynamic>?);

      // Кол-во подписчиков (те, кто подписаны на меня)
      final followersRows = await supabase
          .from('follows')
          .select('follower_id')
          .eq('followee_id', user.id);
      followers = (followersRows as List).length;

      // Кол-во моих подписок (на кого подписан я)
      final followingRows = await supabase
          .from('follows')
          .select('followee_id')
          .eq('follower_id', user.id);
      following = (followingRows as List).length;
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка загрузки профиля: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _edit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfilePage(profile: me)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = me?['avatar_url'] as String?;
    final username = me?['username'] ?? '';
    final name = me?['full_name'] ?? '';
    final bio = me?['bio'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: (avatar != null && avatar.isNotEmpty)
                  ? NetworkImage(avatar)
                  : null,
              child: (avatar == null || avatar.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(username, style: Theme.of(context).textTheme.titleLarge),
            Text(name, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(bio),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PeopleListPage(kind: PeopleKind.followers),
                      ),
                    );
                  },
                  child:  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Подписчики'),
                      Text('$followers'),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PeopleListPage(kind: PeopleKind.following),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Подписки'),
                      Text('$following'),

                    ],
                  ),

                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _edit,
              child: const Text('Редактировать профиль'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPostsPage())),
              child: const Text('Мои посты'),
            ),

          ],

        ),
      ),
    );
  }
}
