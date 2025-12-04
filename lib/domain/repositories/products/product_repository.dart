import 'package:local_basket_business/data/models/products/product_models.dart';

abstract class ProductRepository {
  Future<ProductPage> getProducts({
    required int restaurantId,
    required int page,
    required int size,
  });

  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String shortCode,
    required bool ignoreTax,
    required bool discount,
    required String description,
    required String price,
    required bool available,
    required String productType,
    required int businessId,
    required int categoryId,
    List<Map<String, String>> attributes,
    String? imageFilePath,
  });

  Future<Map<String, dynamic>> updateProduct({
    required int id,
    required String name,
    required String shortCode,
    required bool ignoreTax,
    required bool discount,
    required String description,
    required String price,
    required bool available,
    required String productType,
    required int businessId,
    required int categoryId,
    List<Map<String, String>> attributes,
    String? imageFilePath,
  });

  Future<void> deleteProduct({required int id});

  Future<void> toggleAvailability({required int id});

  Future<void> updateBusinessTimings({
    required int businessId,
    required String startTime,
    required String endTime,
  });

  Future<void> updateProductTimings({
    required int id,
    required String startTime,
    required String endTime,
  });

  Future<List<int>> downloadProductsExcel({
    required DateTime startDate,
    required DateTime endDate,
    required int businessId,
    required String type,
  });

  Future<ProductPage> getProductsReportPaged({
    required DateTime startDate,
    required DateTime endDate,
    required int businessId,
    required String type,
    required int page,
    required int size,
  });
}
