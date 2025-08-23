import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final usernameController = TextEditingController();
  final nameController = TextEditingController();
  bool loading = false;

  Future<void> _register() async {
    setState(() => loading = true);
    try {
      final email = emailController.text.trim();
      final password = passController.text;
      final username = usernameController.text.trim();
      final fullName = nameController.text.trim();

      final res = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'full_name': fullName,
        },
      );

      // Если email подтверждение выключено, сразу обновим профиль
      if (res.user != null) {
        try {
          await supbaseUpdateProfile(username: username, fullName: fullName);
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Регистрация успешна. Проверьте почту (если требуется подтверждение).')),
      );
      Navigator.pop(context);
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка регистрации: ${e.message}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> supbaseUpdateProfile({required String username, required String fullName}) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase.from('profiles').update({
      'username': username,
      'full_name': fullName,
    }).eq('id', user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: passController, decoration: const InputDecoration(labelText: 'Пароль'), obscureText: true),
            const SizedBox(height: 12),
            TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Юзернейм')),
            const SizedBox(height: 12),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Имя')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _register,
              child: loading ? const CircularProgressIndicator() : const Text('Создать аккаунт'),
            ),
          ],
        ),
      ),
    );
  }
}
