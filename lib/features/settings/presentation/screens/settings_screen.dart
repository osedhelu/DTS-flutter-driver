import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifications = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notifications = prefs.getBool('notifications_enabled') ?? true;
      _loading = false;
    });
  }

  Future<void> _setNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notifications = value);
  }

  Future<void> _openSupport() async {
    final uri = Uri.parse('mailto:soporte@dtsdelivery.com?subject=Ayuda%20conductor');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: _loading
          ? const DtsLoading()
          : ListView(
              children: [
                const DtsSectionHeader(
                  title: 'Preferencias',
                ),
                SwitchListTile(
                  title: const Text('Notificaciones push'),
                  subtitle: const Text('Ofertas y actualizaciones de pedidos'),
                  value: _notifications,
                  onChanged: _setNotifications,
                ),
                ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: const Text('Permisos de ubicación'),
                  subtitle: const Text('Necesarios para ofertas y tracking'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ref.read(geolocatorServiceProvider).requestPermission(),
                ),
                const Divider(),
                const DtsSectionHeader(title: 'Cuenta'),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Editar perfil'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile/edit'),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_reset),
                  title: const Text('Cambiar contraseña'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/forgot-password'),
                ),
                const Divider(),
                const DtsSectionHeader(title: 'Soporte'),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Ayuda y FAQ'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/help'),
                ),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('Contactar soporte'),
                  onTap: _openSupport,
                ),
                const Divider(),
                ListTile(
                  title: const Text('Versión'),
                  trailing: Text(
                    '0.1.0',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
    );
  }
}
