import 'package:local_basket_business/data/datasources/orders/orders_remote_data_source.dart';
import 'package:local_basket_business/domain/repositories/orders/orders_repository.dart';
import 'package:local_basket_business/data/models/orders/orders_models.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl(this._remote);
  final OrdersRemoteDataSource _remote;

  @override
  Future<OrdersPage> getOrdersByBusiness({
    required int businessId,
    required int page,
    required int size,
  }) {
    return _remote.getOrdersByBusiness(
      businessId: businessId,
      page: page,
      size: size,
    );
  }

  @override
  Future<void> updateOrderStatus({
    required String orderNumber,
    required String status,
    String? notes,
  }) {
    return _remote.updateOrderStatus(
      orderNumber: orderNumber,
      status: status,
      notes: notes,
    );
  }
}
