import 'package:flutter/material.dart';
import '../../services/follow_service.dart';
import '../../services/supabase_service.dart';

class FollowButton extends StatefulWidget {
  final String authorId;
  final bool? initialFollowing; // можно передать подсказку (если знаешь заранее)
  final void Function(bool isNowFollowing)? onChanged;

  const FollowButton({
    super.key,
    required this.authorId,
    this.initialFollowing,
    this.onChanged,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool? _following; // null = ещё не знаем
  bool _loading = false;

  bool get _isMe => supabase.auth.currentUser?.id == widget.authorId;

  @override
  void initState() {
    super.initState();
    // если подсказка есть — используем, иначе загрузим
    if (widget.initialFollowing != null) {
      _following = widget.initialFollowing;
    } else {
      _init();
    }
  }

  Future<void> _init() async {
    if (_isMe) {
      _following = false;
      if (mounted) setState(() {});
      return;
    }
    try {
      final f = await isFollowing(widget.authorId);
      if (mounted) setState(() => _following = f);
    } catch (_) {
      if (mounted) setState(() => _following = false);
    }
  }

  Future<void> _toggle() async {
    if (_isMe || _loading) return;
    final now = _following ?? false;

    setState(() {
      _loading = true;
      _following = !now; // оптимистично
    });

    try {
      if (now) {
        await unfollow(widget.authorId);
      } else {
        await follow(widget.authorId);
      }
      widget.onChanged?.call(!now);
    } catch (e) {
      // откатываем при ошибке
      if (mounted) {
        setState(() => _following = now);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось ${now ? "отписаться" : "подписаться"}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Не показываем кнопку на своих постах
    if (_isMe) return const SizedBox.shrink();

    final following = _following ?? false;

    // маленькая компактная кнопка
    return SizedBox(
      height: 32,
      child: OutlinedButton(
        onPressed: _loading ? null : _toggle,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(0, 32),
          side: BorderSide(color: following ? Colors.grey : Theme.of(context).colorScheme.primary),
        ),
        child: _loading
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(following ? 'Отписка' : 'Подписаться'),
      ),
    );
  }
}
