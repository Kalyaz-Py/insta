import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../common/follow_button.dart';

enum PeopleKind { following, followers }

class PeopleListPage extends StatefulWidget {
  final PeopleKind kind;
  const PeopleListPage({super.key, required this.kind});

  @override
  State<PeopleListPage> createState() => _PeopleListPageState();
}

class _PeopleListPageState extends State<PeopleListPage> {
  List<Map<String, dynamic>> items = [];
  bool loading = false;

  String get _title => widget.kind == PeopleKind.following
      ? 'Мои подписки'
      : 'Мои подписчики';

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final me = supabase.auth.currentUser!;
      if (widget.kind == PeopleKind.following) {
        // На кого я подписан
        final res = await supabase
            .from('follows')
        // было: 'followee:followee_id!follows_followee_fk (...)'
            .select('followee:profiles!follows_followee_fk (id, username, avatar_url)')
            .eq('follower_id', me.id)
            .order('created_at', ascending: false);
        items = (res as List)
            .map<Map<String, dynamic>>((e) => (e['followee'] ?? {}) as Map<String, dynamic>)
            .where((m) => m.isNotEmpty)
            .toList();
      }

      else {
        // Кто подписан на меня
        final res = await supabase
            .from('follows')
        // было: 'follower:follower_id!follows_follower_fk (...)'
            .select('follower:profiles!follows_follower_fk (id, username, avatar_url)')
            .eq('followee_id', me.id)
            .order('created_at', ascending: false);
        items = (res as List)
            .map<Map<String, dynamic>>((e) => (e['follower'] ?? {}) as Map<String, dynamic>)
            .where((m) => m.isNotEmpty)
            .toList();

      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? Center(child: Text(widget.kind == PeopleKind.following
          ? 'Вы ещё ни на кого не подписаны'
          : 'У вас пока нет подписчиков'))
          : ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final u = items[i];
          final id = (u['id'] ?? '').toString();
          final username = (u['username'] ?? '') as String;
          final avatarUrl = u['avatar_url'] as String?;

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(username, overflow: TextOverflow.ellipsis),
            trailing: FollowButton(
              authorId: id,
              // Можно отобразить текущее состояние позже,
              // но FollowButton сам подгрузит при инициализации.
            ),
          );
        },
      ),
    );
  }
}
