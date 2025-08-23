import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../feed/feed_page.dart';

final supabase = Supabase.instance.client;

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _username = TextEditingController();
  bool _isRegister = true;
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      if (_isRegister) {
        final res = await supabase.auth.signUp(
          email: _email.text.trim(),
          password: _pass.text,
        );
        final user = res.user;
        if (user == null) throw 'Не удалось создать пользователя';
        // создаём профиль
        await supabase.from('profiles').insert({
          'id': user.id,
          'username': _username.text.trim().isEmpty
              ? 'user_${user.id.substring(0, 8)}'
              : _username.text.trim(),
        });
      } else {
        await supabase.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _pass.text,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const FeedPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRegister ? 'Регистрация' : 'Вход')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_isRegister)
              TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username')),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Пароль'), obscureText: true),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(_isRegister ? 'Создать аккаунт' : 'Войти'),
            ),
            TextButton(
              onPressed: () => setState(() => _isRegister = !_isRegister),
              child: Text(_isRegister ? 'У меня уже есть аккаунт' : 'Создать новый аккаунт'),
            ),
          ],
        ),
      ),
    );
  }
}
