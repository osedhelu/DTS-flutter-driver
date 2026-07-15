import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../application/post_auth_service.dart';
import '../../domain/exceptions/not_a_driver_exception.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _afterAuth(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await action();
      await ref.read(postAuthServiceProvider).complete(ref);
    } on NotADriverException {
      if (mounted) {
        setState(() {
          _error = 'Esta cuenta no es de conductor';
          _isLoading = false;
        });
      }
      return;
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo iniciar sesión: $e';
          _isLoading = false;
        });
      }
      return;
    }

    if (!mounted) return;
    context.go('/home');
    setState(() => _isLoading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _afterAuth(
      () => ref.read(driverLoginUseCaseProvider).call(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
          ),
    );
  }

  Future<void> _signInWithGoogle() async {
    await _afterAuth(() => ref.read(googleSignInUseCaseProvider).call());
  }

  Future<void> _signInWithApple() async {
    await _afterAuth(() => ref.read(appleSignInUseCaseProvider).call());
  }

  bool get _showApple =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conductor — Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                key: const Key('login_username'),
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Usuario'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('login_password'),
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Requerido' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('login_submit'),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Entrar'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('login_google'),
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Continuar con Google'),
              ),
              if (_showApple) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const Key('login_apple'),
                  onPressed: _isLoading ? null : _signInWithApple,
                  icon: const Icon(Icons.apple),
                  label: const Text('Continuar con Apple'),
                ),
              ],
              TextButton(
                onPressed: _isLoading ? null : () => context.go('/register'),
                child: const Text('Crear cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
