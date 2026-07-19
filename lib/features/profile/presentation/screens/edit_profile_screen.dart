import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/driver_profile.dart';
import '../../domain/usecases/update_driver_profile_usecase.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _license = TextEditingController();
  final _plate = TextEditingController();
  final _photoUrl = TextEditingController();
  String _vehicleType = 'moto';
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _license.dispose();
    _plate.dispose();
    _photoUrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await ref.read(getDriverProfileUseCaseProvider).call();
      if (!mounted) return;
      _apply(p);
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el perfil';
        _loading = false;
      });
    }
  }

  void _apply(DriverProfile p) {
    _name.text = p.fullName;
    _phone.text = p.phone;
    _license.text = p.licenseNumber;
    _plate.text = p.vehiclePlate;
    _photoUrl.text = p.photoUrl;
    _vehicleType = p.vehicleType.isEmpty ? 'moto' : p.vehicleType;
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (file == null) return;
    // Sin storage cloud dedicado: el usuario puede pegar URL; aquí usamos path local como placeholder.
    // En producción se subiría a media; por ahora pedimos URL o dejamos la existente.
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sube la foto a un hosting y pega la URL en el campo Foto, o deja la actual.',
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(updateDriverProfileUseCaseProvider).call(
            UpdateDriverProfileParams(
              fullName: _name.text.trim(),
              phone: _phone.text.trim(),
              licenseNumber: _license.text.trim(),
              vehicleType: _vehicleType,
              vehiclePlate: _plate.text.trim(),
              photoUrl: _photoUrl.text.trim(),
            ),
          );
      ref.invalidate(onboardingGateProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado')),
      );
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar perfil')),
      body: _loading
          ? const DtsLoading()
          : _error != null
              ? DtsErrorView(message: _error!, onRetry: _load)
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(labelText: 'Teléfono'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _vehicleType,
                        decoration:
                            const InputDecoration(labelText: 'Vehículo'),
                        items: const [
                          DropdownMenuItem(value: 'moto', child: Text('Moto')),
                          DropdownMenuItem(value: 'carro', child: Text('Carro')),
                          DropdownMenuItem(value: 'bici', child: Text('Bici')),
                        ],
                        onChanged: (v) =>
                            setState(() => _vehicleType = v ?? 'moto'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _plate,
                        decoration: const InputDecoration(labelText: 'Placa'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _license,
                        decoration:
                            const InputDecoration(labelText: 'Licencia'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _photoUrl,
                        decoration: InputDecoration(
                          labelText: 'URL de foto',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.photo_library_outlined),
                            onPressed: _pickPhoto,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      DtsPrimaryButton(
                        label: 'Guardar',
                        isLoading: _saving,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
    );
  }
}
