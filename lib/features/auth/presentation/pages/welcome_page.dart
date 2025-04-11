import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/router/app_router.dart';
import '../../../../features/auth/providers/auth_provider.dart';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();

    // Check authorization state when loading the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  // Check authorization state
  void _checkAuthState() {
    final authState = ref.read(authProvider);

    authState.whenOrNull(
      data: (user) {
        if (user != null) {
          if (kDebugMode) {
            print('WelcomePage: User is authorized, redirecting to home page');
          }
          context.go(AppRoutes.home);
        }
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for authentication state changes
    ref.listen(authProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null && mounted) {
            if (kDebugMode) {
              print(
                'WelcomePage: Authorization detected, redirecting to home page',
              );
            }
            context.go(AppRoutes.home);
          }
        },
      );
    });

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('')),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeInAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        // Application logo
                        _buildAnimatedLogo(),

                        const SizedBox(height: 24),

                        // Title and subtitle
                        const Text(
                          'Welcome to DevMate',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Your personal assistant for effective programming learning',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Section with illustration and description
                        _buildFeatureCard(
                          icon: CupertinoIcons.star,
                          title: 'Track your skills',
                          description:
                              'Add and organize your programming skills, tracking progress in their mastery',
                          color: CupertinoColors.activeOrange,
                          illustration: _buildSkillsIllustration(),
                        ),

                        const SizedBox(height: 20),

                        _buildFeatureCard(
                          icon: CupertinoIcons.cube_box,
                          title: 'Manage repositories',
                          description:
                              'GitHub integration allows you to view and manage your projects directly in the app',
                          color: CupertinoColors.activeGreen,
                          illustration: _buildRepositoriesIllustration(),
                        ),

                        const SizedBox(height: 20),

                        _buildFeatureCard(
                          icon: CupertinoIcons.list_bullet,
                          title: 'Track tasks',
                          description:
                              'Create and manage tasks for your projects to keep track of important details',
                          color: CupertinoColors.systemPurple,
                          illustration: _buildTasksIllustration(),
                        ),

                        const SizedBox(height: 40),

                        // Login and registration buttons
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton.filled(
                            onPressed: () => context.go(AppRoutes.login),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              color: CupertinoColors.label.resolveFrom(context),
                              fontSize: 14,
                            ),
                            children: [
                              const TextSpan(
                                text:
                                    'By registering in the app, you agree to our ',
                              ),
                              TextSpan(
                                text: 'Terms of Use',
                                style: const TextStyle(
                                  color: CupertinoColors.activeBlue,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        // TODO: Add navigation to terms of use page
                                        _showAlert(
                                          context,
                                          'Terms of Use',
                                          'This feature is in development. Terms of Use will be available in the next version of the app.',
                                        );
                                      },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.activeBlue.withOpacity(0.2),
                  blurRadius: 20 * value,
                  spreadRadius: 5 * value,
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.device_laptop,
              size: 60,
              color: CupertinoColors.activeBlue,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Widget illustration,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey5.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Add illustration
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: illustration,
            ),
          ),
        ],
      ),
    );
  }

  // Illustration for "Skills" section
  Widget _buildSkillsIllustration() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSkillBar('Flutter', 0.8, CupertinoColors.activeBlue),
          _buildSkillBar('Python', 0.6, CupertinoColors.activeGreen),
          _buildSkillBar('JavaScript', 0.7, CupertinoColors.systemYellow),
          _buildSkillBar('Swift', 0.4, CupertinoColors.systemOrange),
          _buildSkillBar('Kotlin', 0.5, CupertinoColors.systemPurple),
        ],
      ),
    );
  }

  Widget _buildSkillBar(String label, double progress, Color color) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 100,
              width: 20,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 10,
                    height: 100,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 100 * value,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ],
        );
      },
    );
  }

  // Illustration for "Repositories" section
  Widget _buildRepositoriesIllustration() {
    return Center(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOutQuart,
        builder: (context, value, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: math.pi / 6,
                child: Container(
                  width: 80 * value,
                  height: 100 * value,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Transform.rotate(
                angle: -math.pi / 12,
                child: Container(
                  width: 80 * value,
                  height: 100 * value,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey3,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Container(
                width: 80 * value,
                height: 105 * value,
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemGrey5),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 105 * value),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.cube_box_fill,
                        size: 38 * value,
                        color: CupertinoColors.activeGreen,
                      ),
                      SizedBox(height: 4 * value),
                      Text(
                        'GitHub',
                        style: TextStyle(
                          fontSize: 12 * value,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Illustration for "Tasks" section
  Widget _buildTasksIllustration() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1500),
        curve: Curves.easeOutQuart,
        builder: (context, value, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTaskItem('Learn Flutter', true, value),
              _buildTaskItem('Create first app', true, value),
              _buildTaskItem('Publish to App Store', false, value),
              _buildTaskItem('Add new features', false, value),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTaskItem(String title, bool isCompleted, double animationValue) {
    return Transform.translate(
      offset: Offset(30 * (1 - animationValue), 0),
      child: Opacity(
        opacity: animationValue,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                isCompleted
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                size: 20,
                color:
                    isCompleted
                        ? CupertinoColors.activeGreen
                        : CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color:
                      isCompleted
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.label.resolveFrom(context),
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
