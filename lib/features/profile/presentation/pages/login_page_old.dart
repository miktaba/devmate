import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/controllers/login_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    try {
      if (_isLogin) {
        await ref.read(loginControllerProvider.notifier).login(email, password);
      } else {
        await ref
            .read(loginControllerProvider.notifier)
            .register(email, password);
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Error'),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isLogin ? 'Login' : 'Registration'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 32),
              if (state.isLoading)
                const CupertinoActivityIndicator()
              else
                CupertinoButton.filled(
                  onPressed: _handleSubmit,
                  child: Text(_isLogin ? 'Login' : 'Register'),
                ),
              const SizedBox(height: 16),
              CupertinoButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? 'Create account' : 'Already have an account?',
                ),
              ),
              if (_isLogin) ...[
                const SizedBox(height: 16),
                CupertinoButton(
                  onPressed: () {
                    final email = _emailController.text.trim();
                    if (email.isEmpty) {
                      _showError('Please enter email');
                      return;
                    }
                    ref
                        .read(loginControllerProvider.notifier)
                        .resetPassword(email);
                  },
                  child: const Text('Forgot password?'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
