import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/usecases/update_driver_profile_usecase.dart';

const _vehicleTypes = <String, String>{
  'moto': 'Moto',
  'carro': 'Carro',
  'bici': 'Bicicleta',
};

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _licenseNumberController = TextEditingController();

  String? _vehicleType;
  int _step = 0;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _vehiclePlateController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  void _goToStep2() {
    if (!_step1FormKey.currentState!.validate()) return;
    setState(() => _step = 1);
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _backToStep1() {
    setState(() => _step = 0);
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _complete() async {
    if (!_step2FormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(updateDriverProfileUseCaseProvider).call(
            UpdateDriverProfileParams(
              fullName: _fullNameController.text.trim(),
              phone: _phoneController.text.trim(),
              vehicleType: _vehicleType,
              vehiclePlate: _vehiclePlateController.text.trim(),
              licenseNumber: _licenseNumberController.text.trim(),
              completeOnboarding: true,
            ),
          );
      ref.invalidate(onboardingGateProvider);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'No se pudo completar el registro: $e');
      }
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completa tu perfil'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Expanded(child: _StepIndicator(active: _step >= 0)),
                const SizedBox(width: 8),
                Expanded(child: _StepIndicator(active: _step >= 1)),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Datos personales',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text('Cuéntanos quién eres para que los comercios te reconozcan.'),
            const SizedBox(height: 24),
            TextFormField(
              key: const Key('onboarding_full_name'),
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Nombre completo'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('onboarding_phone'),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono'),
              validator: (v) =>
                  v == null || v.trim().length < 8 ? 'Teléfono inválido' : null,
            ),
            const SizedBox(height: 32),
            FilledButton(
              key: const Key('onboarding_next'),
              onPressed: _goToStep2,
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu vehículo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            const Text('Necesitamos estos datos para asignarte pedidos.'),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              key: const Key('onboarding_vehicle_type'),
              initialValue: _vehicleType,
              decoration: const InputDecoration(labelText: 'Tipo de vehículo'),
              items: _vehicleTypes.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => setState(() => _vehicleType = value),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('onboarding_vehicle_plate'),
              controller: _vehiclePlateController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Placa'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('onboarding_license_number'),
              controller: _licenseNumberController,
              decoration: const InputDecoration(labelText: 'Número de licencia'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _backToStep1,
                    child: const Text('Atrás'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('onboarding_complete'),
                    onPressed: _isLoading ? null : _complete,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Finalizar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 6,
      decoration: BoxDecoration(
        color: active ? colorScheme.primary : colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
