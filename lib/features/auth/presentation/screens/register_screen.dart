import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../application/post_auth_service.dart';
import '../../domain/usecases/register_driver_usecase.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(registerDriverUseCaseProvider).call(
            RegisterDriverParams(
              username: _usernameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
              phone: _phoneController.text.trim(),
            ),
          );
      await ref.read(postAuthServiceProvider).complete(ref);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo crear la cuenta');
      }
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta conductor')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                key: const Key('register_username'),
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Usuario'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('register_email'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Email inválido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('register_phone'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (v) =>
                    v == null || v.length < 8 ? 'Teléfono inválido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('register_password'),
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                validator: (v) =>
                    v == null || v.length < 8 ? 'Mínimo 8 caracteres' : null,
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
                key: const Key('register_submit'),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Registrarme'),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Ya tengo cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
