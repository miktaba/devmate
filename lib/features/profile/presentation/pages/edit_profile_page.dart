import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/user_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final nameController = TextEditingController();
  final bioController = TextEditingController();
  final avatarUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    if (user != null) {
      nameController.text = user.name;
      bioController.text = user.bio ?? '';
      avatarUrlController.text = user.avatarUrl ?? '';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    avatarUrlController.dispose();
    super.dispose();
  }

  void _save() {
    final current = ref.read(userProvider);
    if (current == null) return;

    final updatedUser = current.copyWith(
      name: nameController.text.trim(),
      bio: bioController.text.trim(),
      avatarUrl: avatarUrlController.text.trim(),
    );

    ref.read(userProvider.notifier).setUser(updatedUser);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
            ),
            TextField(
              controller: avatarUrlController,
              decoration: const InputDecoration(labelText: 'Avatar URL'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
