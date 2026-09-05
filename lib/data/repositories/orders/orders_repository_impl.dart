import 'package:local_basket_business/data/datasources/orders/orders_remote_data_source.dart';
import 'package:local_basket_business/domain/repositories/orders/orders_repository.dart';
import 'package:local_basket_business/data/models/orders/orders_models.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl(this._remote);
  final OrdersRemoteDataSource _remote;

  @override
  Future<OrdersPage> getOrdersByStore({
    required String storeId,
    required int page,
    required int size,
  }) {
    return _remote.getOrdersByStore(
      storeId: storeId,
      page: page,
      size: size,
    );
  }

  @override
  Future<Map<String, dynamic>> getBusinessKpi({required int businessId}) {
    return _remote.getBusinessKpi(businessId: businessId);
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) {
    return _remote.updateOrderStatus(
      orderId: orderId,
      status: status,
    );
  }
}
