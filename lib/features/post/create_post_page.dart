import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../services/supabase_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final captionController = TextEditingController();
  XFile? picked;
  bool loading = false;

  Future<void> _pickImage() async {
    final ip = ImagePicker();
    final img = await ip.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
    if (img != null) setState(() => picked = img);
  }

  Future<void> _publish() async {
    if (picked == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Выберите изображение')));
      return;
    }
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => loading = true);
    try {
      final id = const Uuid().v4();
      final path = 'posts/${user.id}/$id.jpg'; // расширение подскажет content-type

      if (kIsWeb) {
        final bytes = await picked!.readAsBytes();
        await supabase.storage.from('images').uploadBinary(
          path,
          bytes,

        );
      } else {
        await supabase.storage.from('images').upload(
          path,
          File(picked!.path),

        );
      }

      final publicUrl = supabase.storage.from('images').getPublicUrl(path);

      await supabase.from('posts').insert({
        'author_id': user.id,
        'image_url': publicUrl,
        'caption': captionController.text.trim(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Опубликовано!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка публикации: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = picked;

    return Scaffold(
      appBar: AppBar(title: const Text('Новый пост')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 240,
                width: double.infinity,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: img == null
                    ? const Text('Нажмите, чтобы выбрать изображение')
                    : (kIsWeb
                    ? Image.network(img.path, fit: BoxFit.cover)
                    : Image.file(File(img.path), fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: captionController,
              decoration: const InputDecoration(labelText: 'Подпись'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _publish,
              child: loading
                  ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator())
                  : const Text('Опубликовать'),
            ),
          ],
        ),
      ),
    );
  }
}
