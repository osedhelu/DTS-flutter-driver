import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/driver_profile.dart';

const _vehicleTypeLabels = <String, String>{
  'moto': 'Moto',
  'carro': 'Carro',
  'bici': 'Bicicleta',
};

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  DriverProfile? _profile;
  bool _isLoading = true;
  String? _error;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await ref.read(getDriverProfileUseCaseProvider).call();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el perfil';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      ref.read(locationServiceProvider).stop();
      await ref.read(authRepositoryProvider).logout();
      ref.invalidate(authStateProvider);
      ref.invalidate(onboardingGateProvider);
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _isLoading
          ? const DtsLoading()
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      backgroundImage: (profile?.photoUrl.isNotEmpty ?? false)
                          ? NetworkImage(profile!.photoUrl)
                          : null,
                      child: (profile?.photoUrl.isEmpty ?? true)
                          ? Icon(
                              Icons.person,
                              size: 44,
                              color: theme.colorScheme.onSecondaryContainer,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      profile?.fullName.isNotEmpty == true
                          ? profile!.fullName
                          : 'Conductor',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Center(
                    child: DtsStatusChip(
                      label: profile?.isOnline == true ? 'En línea' : 'Offline',
                      tone: profile?.isOnline == true
                          ? DtsChipTone.success
                          : DtsChipTone.neutral,
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Card(
                    child: Column(
                      children: [
                        _MenuTile(
                          icon: Icons.edit_outlined,
                          title: 'Editar perfil',
                          onTap: () async {
                            final ok = await context.push('/profile/edit');
                            if (ok == true) _loadProfile();
                          },
                        ),
                        const Divider(height: 1),
                        _MenuTile(
                          icon: Icons.payments_outlined,
                          title: 'Ganancias',
                          onTap: () => context.push('/earnings'),
                        ),
                        const Divider(height: 1),
                        _MenuTile(
                          icon: Icons.history,
                          title: 'Historial',
                          onTap: () => context.push('/history'),
                        ),
                        const Divider(height: 1),
                        _MenuTile(
                          icon: Icons.settings_outlined,
                          title: 'Ajustes',
                          onTap: () => context.push('/settings'),
                        ),
                        const Divider(height: 1),
                        _MenuTile(
                          icon: Icons.help_outline,
                          title: 'Ayuda',
                          onTap: () => context.push('/help'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        children: [
                          _InfoTile(
                            icon: Icons.phone_outlined,
                            label: 'Teléfono',
                            value: profile?.phone ?? '—',
                          ),
                          const Divider(height: 1),
                          _InfoTile(
                            icon: Icons.two_wheeler_outlined,
                            label: 'Vehículo',
                            value: profile == null
                                ? '—'
                                : (_vehicleTypeLabels[profile.vehicleType] ??
                                    profile.vehicleType),
                          ),
                          const Divider(height: 1),
                          _InfoTile(
                            icon: Icons.directions_car_filled_outlined,
                            label: 'Placa',
                            value: profile?.vehiclePlate ?? '—',
                          ),
                          const Divider(height: 1),
                          _InfoTile(
                            icon: Icons.badge_outlined,
                            label: 'Licencia',
                            value: profile?.licenseNumber ?? '—',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    key: const Key('profile_logout'),
                    onPressed: _isLoggingOut ? null : _logout,
                    icon: _isLoggingOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      trailing: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
