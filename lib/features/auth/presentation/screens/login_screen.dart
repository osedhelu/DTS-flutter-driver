import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
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
  bool _obscure = true;
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
          _error = _friendlyAuthError(e);
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

  String _friendlyAuthError(Object e) {
    final raw = e is StateError ? e.message : e.toString();
    final message = raw
        .replaceFirst(RegExp(r'^Bad state:\s*'), '')
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .trim();
    if (message.isEmpty) {
      return 'No se pudo iniciar sesión';
    }
    return message;
  }

  bool get _showApple => !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B3D2E), Color(0xFF145A43), Color(0xFFF7F8F6)],
            stops: [0.0, 0.35, 0.35],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
                      size: 40,
                      color: Color(0xFF0B3D2E),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'DTS Conductor',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gana entregando pedidos cerca de ti',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 36),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Iniciar sesión',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('login_username'),
                            controller: _usernameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Usuario',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Requerido'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: const Key('login_password'),
                            controller: _passwordController,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty
                                    ? 'Requerido'
                                    : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => context.push('/forgot-password'),
                              child: const Text('¿Olvidaste tu contraseña?'),
                            ),
                          ),
                          if (_error != null) ...[
                            Text(
                              _error!,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                            const SizedBox(height: 8),
                          ],
                          DtsPrimaryButton(
                            key: const Key('login_submit'),
                            label: 'Entrar',
                            isLoading: _isLoading,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const Key('login_google'),
                            onPressed: _isLoading ? null : _signInWithGoogle,
                            icon: const Icon(Icons.g_mobiledata, size: 28),
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
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : () => context.go('/register'),
                  child: const Text('¿Nuevo conductor? Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
