import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/token_storage.dart';
import '../location/geolocator_service.dart';
import '../location/geolocator_service_impl.dart';
import '../firebase/firebase_messaging_service.dart';
import '../firebase/fcm_firebase_messaging_service.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/apple_sign_in_usecase.dart';
import '../../features/auth/domain/usecases/driver_login_usecase.dart';
import '../../features/auth/domain/usecases/google_sign_in_usecase.dart';
import '../../features/auth/domain/usecases/register_driver_usecase.dart';
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
import '../../features/location/infrastructure/datasources/driver_tracking_ws_datasource.dart';
import '../../features/location/infrastructure/datasources/location_tracking_remote_datasource.dart';
import '../../features/location/infrastructure/repositories/location_tracking_repository_impl.dart';
import '../../features/location/application/services/location_service.dart';
import '../../features/profile/domain/repositories/driver_profile_repository.dart';
import '../../features/profile/domain/usecases/get_driver_profile_usecase.dart';
import '../../features/profile/domain/usecases/update_driver_profile_usecase.dart';
import '../../features/profile/infrastructure/datasources/driver_profile_remote_datasource.dart';
import '../../features/profile/infrastructure/repositories/driver_profile_repository_impl.dart';
import '../../features/offers/domain/repositories/driver_offer_repository.dart';
import '../../features/offers/domain/usecases/accept_driver_offer_usecase.dart';
import '../../features/offers/domain/usecases/list_driver_offers_usecase.dart';
import '../../features/offers/domain/usecases/reject_driver_offer_usecase.dart';
import '../../features/offers/infrastructure/datasources/driver_offer_remote_datasource.dart';
import '../../features/offers/infrastructure/repositories/driver_offer_repository_impl.dart';

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
  final service = FcmFirebaseMessagingService();
  ref.onDispose(service.dispose);
  return service;
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

final registerDriverUseCaseProvider = Provider<RegisterDriverUseCase>((ref) {
  return RegisterDriverUseCase(ref.watch(authRepositoryProvider));
});

final googleSignInUseCaseProvider = Provider<GoogleSignInUseCase>((ref) {
  return GoogleSignInUseCase(ref.watch(authRepositoryProvider));
});

final appleSignInUseCaseProvider = Provider<AppleSignInUseCase>((ref) {
  return AppleSignInUseCase(ref.watch(authRepositoryProvider));
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
  return AcceptOrderUseCase(ref.watch(driverOfferRepositoryProvider));
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

final driverTrackingWsDataSourceProvider =
    Provider<DriverTrackingWsDataSource>((ref) {
  final datasource = DriverTrackingWsDataSource();
  ref.onDispose(() {
    datasource.disconnect();
  });
  return datasource;
});

final locationTrackingRepositoryProvider =
    Provider<LocationTrackingRepository>((ref) {
  return LocationTrackingRepositoryImpl(
    remoteDataSource: ref.watch(locationTrackingRemoteDataSourceProvider),
    wsDataSource: ref.watch(driverTrackingWsDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
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

final driverProfileRemoteDataSourceProvider =
    Provider<DriverProfileRemoteDataSource>((ref) {
  return DriverProfileRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final driverProfileRepositoryProvider = Provider<DriverProfileRepository>((ref) {
  return DriverProfileRepositoryImpl(
    ref.watch(driverProfileRemoteDataSourceProvider),
  );
});

final getDriverProfileUseCaseProvider = Provider<GetDriverProfileUseCase>((ref) {
  return GetDriverProfileUseCase(ref.watch(driverProfileRepositoryProvider));
});

final updateDriverProfileUseCaseProvider =
    Provider<UpdateDriverProfileUseCase>((ref) {
  return UpdateDriverProfileUseCase(ref.watch(driverProfileRepositoryProvider));
});

final onboardingGateProvider = FutureProvider<bool>((ref) async {
  final authed = await ref.watch(authStateProvider.future);
  if (!authed) return true;
  try {
    final profile = await ref.watch(getDriverProfileUseCaseProvider).call();
    return profile.onboardingCompleted;
  } catch (_) {
    return false;
  }
});

final driverOfferRemoteDataSourceProvider =
    Provider<DriverOfferRemoteDataSource>((ref) {
  return DriverOfferRemoteDataSource(ref.watch(apiClientProvider).dio);
});

final driverOfferRepositoryProvider = Provider<DriverOfferRepository>((ref) {
  return DriverOfferRepositoryImpl(
    ref.watch(driverOfferRemoteDataSourceProvider),
  );
});

final listDriverOffersUseCaseProvider = Provider<ListDriverOffersUseCase>((ref) {
  return ListDriverOffersUseCase(ref.watch(driverOfferRepositoryProvider));
});

final acceptDriverOfferUseCaseProvider =
    Provider<AcceptDriverOfferUseCase>((ref) {
  return AcceptDriverOfferUseCase(ref.watch(driverOfferRepositoryProvider));
});

final rejectDriverOfferUseCaseProvider =
    Provider<RejectDriverOfferUseCase>((ref) {
  return RejectDriverOfferUseCase(ref.watch(driverOfferRepositoryProvider));
});
