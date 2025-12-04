import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:local_basket_business/core/network/dio_client.dart';
import 'package:local_basket_business/core/storage/secure_storage.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:local_basket_business/data/datasources/auth/auth_remote_data_source.dart';
import 'package:local_basket_business/data/datasources/products/product_remote_data_source.dart';
import 'package:local_basket_business/data/datasources/orders/orders_remote_data_source.dart';
import 'package:local_basket_business/data/datasources/business/business_remote_data_source.dart';
import 'package:local_basket_business/data/repositories/auth/auth_repository_impl.dart';
import 'package:local_basket_business/data/repositories/products/product_repository_impl.dart';
import 'package:local_basket_business/data/repositories/orders/orders_repository_impl.dart';
import 'package:local_basket_business/data/repositories/business/business_repository_impl.dart';
import 'package:local_basket_business/domain/repositories/auth/auth_repository.dart';
import 'package:local_basket_business/domain/repositories/products/product_repository.dart';
import 'package:local_basket_business/domain/repositories/orders/orders_repository.dart';
import 'package:local_basket_business/domain/repositories/business/business_repository.dart';

final sl = GetIt.instance;

Future<void> setupLocator() async {
  // Core
  sl.registerLazySingleton<Dio>(() => Dio());
  sl.registerLazySingleton<DioClient>(() => DioClient(sl()));
  sl.registerLazySingleton<AppSecureStorage>(() => AppSecureStorage());
  sl.registerLazySingleton<SessionStore>(() => SessionStore());

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(sl(), sl()),
  );
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSource(sl(), sl()),
  );
  sl.registerLazySingleton<OrdersRemoteDataSource>(
    () => OrdersRemoteDataSource(sl(), sl()),
  );
  sl.registerLazySingleton<BusinessRemoteDataSource>(
    () => BusinessRemoteDataSource(sl(), sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<OrdersRepository>(() => OrdersRepositoryImpl(sl()));
  sl.registerLazySingleton<BusinessRepository>(
    () => BusinessRepositoryImpl(sl()),
  );
}
