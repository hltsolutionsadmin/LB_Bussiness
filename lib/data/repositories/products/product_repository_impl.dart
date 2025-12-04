import 'package:local_basket_business/data/datasources/products/product_remote_data_source.dart';
import 'package:local_basket_business/domain/repositories/products/product_repository.dart';
import 'package:local_basket_business/data/models/products/product_models.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remote);
  final ProductRemoteDataSource _remote;

  @override
  Future<ProductPage> getProducts({
    required int restaurantId,
    required int page,
    required int size,
  }) {
    return _remote.fetchProducts(
      restaurantId: restaurantId,
      page: page,
      size: size,
    );
  }

  @override
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
    List<Map<String, String>> attributes = const [],
    String? imageFilePath,
  }) {
    return _remote.createProduct(
      name: name,
      shortCode: shortCode,
      ignoreTax: ignoreTax,
      discount: discount,
      description: description,
      price: price,
      available: available,
      productType: productType,
      businessId: businessId,
      categoryId: categoryId,
      attributes: attributes,
      imageFilePath: imageFilePath,
    );
  }

  @override
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
    List<Map<String, String>> attributes = const [],
    String? imageFilePath,
  }) {
    return _remote.updateProduct(
      id: id,
      name: name,
      shortCode: shortCode,
      ignoreTax: ignoreTax,
      discount: discount,
      description: description,
      price: price,
      available: available,
      productType: productType,
      businessId: businessId,
      categoryId: categoryId,
      attributes: attributes,
      imageFilePath: imageFilePath,
    );
  }

  @override
  Future<void> deleteProduct({required int id}) {
    return _remote.deleteProduct(id: id);
  }

  @override
  Future<void> toggleAvailability({required int id}) {
    return _remote.toggleAvailability(id: id);
  }

  @override
  Future<void> updateBusinessTimings({
    required int businessId,
    required String startTime,
    required String endTime,
  }) {
    return _remote.updateBusinessTimings(
      businessId: businessId,
      startTime: startTime,
      endTime: endTime,
    );
  }

  @override
  Future<void> updateProductTimings({
    required int id,
    required String startTime,
    required String endTime,
  }) {
    return _remote.updateProductTimings(
      id: id,
      startTime: startTime,
      endTime: endTime,
    );
  }

  @override
  Future<List<int>> downloadProductsExcel({
    required DateTime startDate,
    required DateTime endDate,
    required int businessId,
    required String type,
  }) {
    return _remote.downloadProductsExcel(
      startDate: startDate,
      endDate: endDate,
      businessId: businessId,
      type: type,
    );
  }

  @override
  Future<ProductPage> getProductsReportPaged({
    required DateTime startDate,
    required DateTime endDate,
    required int businessId,
    required String type,
    required int page,
    required int size,
  }) {
    return _remote.fetchProductsReportPaged(
      startDate: startDate,
      endDate: endDate,
      businessId: businessId,
      type: type,
      page: page,
      size: size,
    );
  }
}
