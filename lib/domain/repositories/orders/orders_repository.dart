import 'package:local_basket_business/data/models/orders/orders_models.dart';

abstract class OrdersRepository {
  Future<OrdersPage> getOrdersByStore({
    required String storeId,
    required int page,
    required int size,
  });

  Future<Map<String, dynamic>> getBusinessKpi({required int businessId});

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  });
}
