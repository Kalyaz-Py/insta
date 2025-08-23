import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../services/supabase_service.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic>? profile;
  const EditProfilePage({super.key, this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final username = TextEditingController();
  final fullName = TextEditingController();
  final bio = TextEditingController();
  XFile? picked;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile ?? {};
    username.text = p['username'] ?? '';
    fullName.text = p['full_name'] ?? '';
    bio.text = p['bio'] ?? '';
  }

  Future<String?> _uploadAvatar() async {
    if (picked == null) return widget.profile?['avatar_url'];
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final key = 'avatars/${user.id}/${const Uuid().v4()}.jpg';

    if (kIsWeb) {
      final bytes = await picked!.readAsBytes();
      await supabase.storage.from('images').uploadBinary(
        key,
        bytes,
        // без fileOptions — совместимо с 2.x
      );
    } else {
      await supabase.storage.from('images').upload(
        key,
        File(picked!.path),
        // без fileOptions — совместимо с 2.x
      );
    }
    return supabase.storage.from('images').getPublicUrl(key);
  }

  Future<void> _save() async {
    setState(() => loading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final avatarUrl = await _uploadAvatar();

      await supabase.from('profiles').update({
        'username': username.text.trim(),
        'full_name': fullName.text.trim(),
        'bio': bio.text.trim(),
        'avatar_url': avatarUrl,
      }).eq('id', user.id);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pick() async {
    final ip = ImagePicker();
    final img = await ip.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 90,
    );
    if (img != null) setState(() => picked = img);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать профиль')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.image),
              label: const Text('Выбрать аватар'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: username,
              decoration: const InputDecoration(labelText: 'Юзернейм'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: fullName,
              decoration: const InputDecoration(labelText: 'Имя'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bio,
              decoration: const InputDecoration(labelText: 'О себе'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _save,
              child: loading
                  ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator())
                  : const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
