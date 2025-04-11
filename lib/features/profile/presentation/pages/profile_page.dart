import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../features/auth/providers/auth_provider.dart';
import '../../application/services/auth_service.dart' as profile_service;

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Profile')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.person,
                  size: 60,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 16),

              // User email
              Text(
                user?.email ?? 'User not authorized',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${user?.uid ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),

              const SizedBox(height: 32),

              // User information
              const _InfoCard(
                title: 'User information',
                children: [
                  _InfoRow(label: 'Registration date', value: 'Test mode'),
                  _InfoRow(label: 'Last login', value: 'Now'),
                  _InfoRow(label: 'Status', value: 'Active'),
                ],
              ),

              const SizedBox(height: 16),

              // Profile settings
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.systemGrey5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Change password
                    GestureDetector(
                      onTap: () {
                        // TODO: Implement password change
                        _showAlert(
                          context,
                          'Function is under development',
                          'Password change will be available in the next version of the application.',
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(
                            CupertinoIcons.lock,
                            size: 20,
                            color: CupertinoColors.activeBlue,
                          ),
                          SizedBox(width: 8),
                          Text('Change password'),
                          Spacer(),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: CupertinoColors.systemGrey,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notifications
                    GestureDetector(
                      onTap: () {
                        // TODO: Implement notification settings
                        _showAlert(
                          context,
                          'Function is under development',
                          'Notification settings will be available in the next version.',
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(
                            CupertinoIcons.bell,
                            size: 20,
                            color: CupertinoColors.activeBlue,
                          ),
                          SizedBox(width: 8),
                          Text('Notificationsns'),
                          Spacer(),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: CupertinoColors.systemGrey,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlert(BuildContext context, String title, String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: CupertinoColors.systemGrey),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
