import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/location_radius_constants.dart';
import '../../../../core/di/providers.dart';
import '../../../profile/domain/entities/driver_profile.dart';
import '../../../profile/domain/usecases/update_driver_profile_usecase.dart';
import 'location_radius_picker.dart';

Future<DriverProfile?> openDriverWorkZonePicker(
  BuildContext context,
  WidgetRef ref, {
  DriverProfile? profile,
}) async {
  profile ??= await ref.read(getDriverProfileUseCaseProvider).call();

  final result = await LocationRadiusPicker.show(
    context,
    initialLatitude: profile.workCenterLatitude,
    initialLongitude: profile.workCenterLongitude,
    initialRadiusKm: profile.workRadiusKm,
  );
  if (result == null || !context.mounted) return null;

  try {
    final updated = await ref.read(updateDriverProfileUseCaseProvider).call(
          UpdateDriverProfileParams(
            workCenterLatitude: result.latitude,
            workCenterLongitude: result.longitude,
            workRadiusKm: result.radiusKm,
          ),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Zona de trabajo: ${normalizeRadiusPreset(updated.workRadiusKm).toStringAsFixed(0)} km',
          ),
        ),
      );
    }
    return updated;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la zona: $e')),
      );
    }
    return null;
  }
}
