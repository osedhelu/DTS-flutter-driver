import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/token_storage.dart';
import '../location/geolocator_service.dart';
import '../location/geolocator_service_impl.dart';
import '../firebase/firebase_messaging_service.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/driver_login_usecase.dart';
import '../../features/auth/infrastructure/datasources/auth_remote_datasource.dart';
import '../../features/auth/infrastructure/repositories/auth_repository_impl.dart';
import '../../features/availability/domain/repositories/availability_repository.dart';
import '../../features/availability/domain/usecases/toggle_online_usecase.dart';
import '../../features/availability/infrastructure/datasources/availability_remote_datasource.dart';
import '../../features/availability/infrastructure/repositories/availability_repository_impl.dart';
import '../../features/orders/domain/repositories/driver_order_repository.dart';
import '../../features/orders/domain/usecases/accept_order_usecase.dart';
import '../../features/orders/domain/usecases/confirm_delivery_usecase.dart';
import '../../features/orders/domain/usecases/confirm_pickup_usecase.dart';
import '../../features/orders/infrastructure/datasources/driver_order_remote_datasource.dart';
import '../../features/orders/infrastructure/repositories/driver_order_repository_impl.dart';
import '../../features/location/domain/usecases/send_location_usecase.dart';
import '../../features/location/infrastructure/datasources/location_tracking_remote_datasource.dart';
import '../../features/location/infrastructure/repositories/location_tracking_repository_impl.dart';
import '../../features/location/application/services/location_service.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: storage);
});

final geolocatorServiceProvider = Provider<GeolocatorService>((ref) {
  return const GeolocatorServiceImpl();
});

final firebaseMessagingServiceProvider = Provider<FirebaseMessagingService>((ref) {
  return MockFirebaseMessagingService();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final driverLoginUseCaseProvider = Provider<DriverLoginUseCase>((ref) {
  return DriverLoginUseCase(ref.watch(authRepositoryProvider));
});

final authStateProvider = FutureProvider<bool>((ref) async {
  return ref.watch(authRepositoryProvider).isAuthenticated();
});

final availabilityRemoteDataSourceProvider =
    Provider<AvailabilityRemoteDataSource>((ref) {
  return AvailabilityRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final availabilityRepositoryProvider = Provider<AvailabilityRepository>((ref) {
  return AvailabilityRepositoryImpl(
    ref.watch(availabilityRemoteDataSourceProvider),
  );
});

final toggleOnlineUseCaseProvider = Provider<ToggleOnlineUseCase>((ref) {
  return ToggleOnlineUseCase(ref.watch(availabilityRepositoryProvider));
});

final driverOrderRemoteDataSourceProvider =
    Provider<DriverOrderRemoteDataSource>((ref) {
  return DriverOrderRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final driverOrderRepositoryProvider = Provider<DriverOrderRepository>((ref) {
  return DriverOrderRepositoryImpl(
    ref.watch(driverOrderRemoteDataSourceProvider),
  );
});

final acceptOrderUseCaseProvider = Provider<AcceptOrderUseCase>((ref) {
  return AcceptOrderUseCase(ref.watch(driverOrderRepositoryProvider));
});

final confirmPickupUseCaseProvider = Provider<ConfirmPickupUseCase>((ref) {
  return ConfirmPickupUseCase(ref.watch(driverOrderRepositoryProvider));
});

final confirmDeliveryUseCaseProvider = Provider<ConfirmDeliveryUseCase>((ref) {
  return ConfirmDeliveryUseCase(ref.watch(driverOrderRepositoryProvider));
});

final locationTrackingRemoteDataSourceProvider =
    Provider<LocationTrackingRemoteDataSource>((ref) {
  return LocationTrackingRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final locationTrackingRepositoryProvider =
    Provider<LocationTrackingRepository>((ref) {
  return LocationTrackingRepositoryImpl(
    ref.watch(locationTrackingRemoteDataSourceProvider),
  );
});

final sendLocationUseCaseProvider = Provider<SendLocationUseCase>((ref) {
  return SendLocationUseCase(
    availabilityRepository: ref.watch(availabilityRepositoryProvider),
    orderRepository: ref.watch(driverOrderRepositoryProvider),
    trackingRepository: ref.watch(locationTrackingRepositoryProvider),
  );
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService(
    sendLocationUseCase: ref.watch(sendLocationUseCaseProvider),
    geolocatorService: ref.watch(geolocatorServiceProvider),
  );
});
