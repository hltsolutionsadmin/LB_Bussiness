import 'package:local_basket_business/data/models/orders/orders_models.dart';

abstract class OrdersRepository {
  Future<OrdersPage> getOrdersByBusiness({
    required int businessId,
    required int page,
    required int size,
  });

  Future<void> updateOrderStatus({
    required String orderNumber,
    required String status,
    String? notes,
  });
}
