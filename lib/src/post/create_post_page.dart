import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});
  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  Uint8List? _bytes;
  final _caption = TextEditingController();
  bool _loading = false;

  Future<void> _pick() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      setState(() => _bytes = await img.readAsBytes());
  }
  }

  Future<void> _publish() async {
    if (_bytes == null) return;
    setState(() => _loading = true);
    try {
      final uid = supabase.auth.currentUser!.id;
      final path = 'images/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('images').uploadBinary(
        path,
        _bytes!,
        fileOptions: const FileOptions(upsert: false, contentType: 'image/jpeg'),
      );
      final publicUrl = supabase.storage.from('images').getPublicUrl(path);
      await supabase.from('posts').insert({
        'author_id': uid,
        'image_url': publicUrl,
        'caption': _caption.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новый пост')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_bytes != null) Image.memory(_bytes!, height: 240, fit: BoxFit.cover),
            const SizedBox(height: 8),
            TextField(controller: _caption, decoration: const InputDecoration(labelText: 'Подпись')),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(onPressed: _pick, child: const Text('Выбрать фото')),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _loading ? null : _publish, child: const Text('Опубликовать')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
