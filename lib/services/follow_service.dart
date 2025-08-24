import 'package:supabase_flutter/supabase_flutter.dart';

final _sb = Supabase.instance.client;

Future<bool> isFollowing(String targetId) async{
  final me = _sb.auth.currentUser?.id;
  if (me == null || me == targetId) return false;

  final rows = await _sb
    .from('follows')
    .select('follower_id')
    .match({'follower_id' : me, 'followee_id': targetId})
    .limit(1);

  return(rows as List).isNotEmpty;
}

/// Подписаться
Future<void> follow(String targetId) async {
  final me = _sb.auth.currentUser?.id;
  if (me == null || me == targetId) return;
  await _sb.from('follows').insert({'follower_id': me, 'followee_id': targetId})
      .onError((error, stack) async {
    // если unique conflit — просто игнорируем

    if (error is PostgrestException && error.code == '23505') return;
    
  });
}

/// Отписаться
Future<void> unfollow(String targetId) async {
  final me = _sb.auth.currentUser?.id;
  if (me == null || me == targetId) return;
  await _sb.from('follows')
      .delete()
      .match({'follower_id': me, 'followee_id': targetId});
}