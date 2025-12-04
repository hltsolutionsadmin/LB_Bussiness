import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:local_basket_business/core/network/dio_client.dart';
import 'package:local_basket_business/core/storage/secure_storage.dart';
import 'package:local_basket_business/data/models/products/product_models.dart'
    as pm;

class ProductRemoteDataSource {
  ProductRemoteDataSource(this._client, this._storage);

  final DioClient _client;
  final AppSecureStorage _storage;

  Options _authOptions(String? bearer) {
    return Options(
      headers: {
        if (bearer != null && bearer.isNotEmpty)
          'Authorization': 'Bearer $bearer',
        'Content-Type': 'application/json',
      },
    );
  }

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
  }) async {
    final token = await _storage.readToken();
    final form = FormData();
    form.fields
      ..add(MapEntry('name', name))
      ..add(MapEntry('shortCode', shortCode))
      ..add(MapEntry('ignoreTax', ignoreTax.toString()))
      ..add(MapEntry('discount', discount.toString()))
      ..add(MapEntry('description', description))
      ..add(MapEntry('price', price))
      ..add(MapEntry('available', available.toString()))
      ..add(MapEntry('productType', productType))
      ..add(MapEntry('businessId', businessId.toString()))
      ..add(MapEntry('categoryId', categoryId.toString()));
    for (int i = 0; i < attributes.length; i++) {
      final att = attributes[i];
      if (att['attributeName'] != null && att['attributeValue'] != null) {
        form.fields.add(
          MapEntry('attributes[$i].attributeName', att['attributeName']!),
        );
        form.fields.add(
          MapEntry('attributes[$i].attributeValue', att['attributeValue']!),
        );
      }
    }
    if (imageFilePath != null && imageFilePath.isNotEmpty) {
      form.files.add(
        MapEntry(
          'mediaFiles',
          await MultipartFile.fromFile(
            imageFilePath,
            filename: imageFilePath.split('/').last,
          ),
        ),
      );
    }
    if (kDebugMode) {
      debugPrint('[API] Create Product -> POST /product/api/products/create');
      debugPrint(
        '[API] Create fields: name=$name, shortCode=$shortCode, price=$price, businessId=$businessId, categoryId=$categoryId',
      );
      for (final e in form.fields) {
        debugPrint('  FIELD ${e.key}=${e.value}');
      }
      for (final f in form.files) {
        debugPrint('  FILE ${f.key} -> ${(f.value.filename)}');
      }
    }
    final res = await _client.dio.post(
      '/product/api/products/create',
      data: form,
      options: _authOptions(token).copyWith(contentType: 'multipart/form-data'),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

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
  }) async {
    final token = await _storage.readToken();
    final form = FormData();
    form.fields
      ..add(MapEntry('id', id.toString()))
      ..add(MapEntry('productId', id.toString()))
      ..add(MapEntry('name', name))
      ..add(MapEntry('shortCode', shortCode))
      ..add(MapEntry('ignoreTax', ignoreTax.toString()))
      ..add(MapEntry('discount', discount.toString()))
      ..add(MapEntry('description', description))
      ..add(MapEntry('price', price))
      ..add(MapEntry('available', available.toString()))
      ..add(MapEntry('productType', productType))
      ..add(MapEntry('businessId', businessId.toString()))
      ..add(MapEntry('categoryId', categoryId.toString()));
    for (int i = 0; i < attributes.length; i++) {
      final att = attributes[i];
      if (att['attributeName'] != null && att['attributeValue'] != null) {
        form.fields.add(
          MapEntry('attributes[$i].attributeName', att['attributeName']!),
        );
        form.fields.add(
          MapEntry('attributes[$i].attributeValue', att['attributeValue']!),
        );
      }
    }
    if (imageFilePath != null && imageFilePath.isNotEmpty) {
      form.files.add(
        MapEntry(
          'mediaFiles',
          await MultipartFile.fromFile(
            imageFilePath,
            filename: imageFilePath.split('/').last,
          ),
        ),
      );
    }
    final res = await _client.dio.post(
      '/product/api/products/create',
      data: form,
      options: _authOptions(token).copyWith(contentType: 'multipart/form-data'),
    );
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<pm.ProductPage> fetchProducts({
    required int restaurantId,
    required int page,
    required int size,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] List Products -> GET /product/api/products/restaurant/$restaurantId?page=$page&size=$size',
      );
    }
    final res = await _client.dio.get(
      '/product/api/products/restaurant/$restaurantId',
      queryParameters: {'page': page, 'size': size},
      options: _authOptions(token),
    );
    if (kDebugMode) {
      debugPrint('[API] Products Response: ${res.statusCode}');
      debugPrint('BODY: ${res.data}');
    }

    final data = res.data;
    List list;
    int totalPages = 0;
    int number = page;
    if (data is Map<String, dynamic>) {
      // Handle {content: [...]} directly
      if (data['content'] is List) {
        list = data['content'] as List;
        totalPages = (data['totalPages'] as int?) ?? 0;
        number = (data['number'] as int?) ?? page;
      }
      // Handle wrapper { success, message, data: { content: [...], totalPages, number } }
      else if (data['data'] is Map<String, dynamic>) {
        final inner = data['data'] as Map<String, dynamic>;
        list = (inner['content'] is List) ? inner['content'] as List : const [];
        totalPages = (inner['totalPages'] as int?) ?? 0;
        number = (inner['number'] as int?) ?? page;
      }
      // Handle wrapper { success, message, data: [...] }
      else if (data['data'] is List) {
        list = data['data'] as List;
      } else {
        list = [];
      }
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }

    final items = list.whereType<Map>().map<Map<String, dynamic>>((raw) {
      final m = Map<String, dynamic>.from(raw);
      // Pick price preference: attributes.onlinePrice > price > mrp
      num? price = (m['price'] as num?) ?? (m['mrp'] as num?);
      if (m['attributes'] is List) {
        for (final att in (m['attributes'] as List)) {
          if (att is Map) {
            final attMap = Map<String, dynamic>.from(att);
            final name = attMap['attributeName']?.toString().toLowerCase();
            if (name == 'onlineprice') {
              final pv = attMap['attributeValue'];
              if (pv is num) price = pv;
              if (pv is String) {
                final parsed = num.tryParse(pv);
                if (parsed != null) price = parsed;
              }
            }
          }
        }
      }
      final categoryName =
          (m['categoryName']?.toString() ?? m['category']?.toString() ?? '');
      // Extract image url from media list if present
      String? imageUrl;
      if (m['media'] is List) {
        for (final md in (m['media'] as List)) {
          if (md is Map) {
            final mm = Map<String, dynamic>.from(md);
            final t = (mm['mediaType']?.toString() ?? '').toUpperCase();
            final url = mm['url']?.toString();
            if (url != null &&
                url.isNotEmpty &&
                (t == 'PRODUCT' || t.isEmpty)) {
              imageUrl = url;
              break;
            }
          }
        }
      }
      return {
        'id': m['id'],
        'name': m['name'] ?? m['productName'] ?? 'Item',
        'category': categoryName.toLowerCase(),
        'categoryId': m['categoryId'],
        'description': m['description']?.toString() ?? '',
        'price': (price ?? 0).toDouble(),
        'available': (m['available'] ?? m['enabled'] ?? true) == true,
        'imageUrl': imageUrl,
      };
    }).toList();

    final hasNext = totalPages == 0
        ? items.length == size
        : (number + 1) < totalPages;
    return pm.ProductPage(
      items: items,
      hasNext: hasNext,
      page: number,
      size: size,
    );
  }

  Future<void> deleteProduct({required int id}) async {
    final token = await _storage.readToken();
    await _client.dio.delete(
      '/product/api/products/delete/$id',
      options: _authOptions(token),
    );
  }

  Future<void> toggleAvailability({required int id}) async {
    final token = await _storage.readToken();
    await _client.dio.patch(
      '/product/api/products/$id/toggle-availability',
      options: _authOptions(token),
    );
  }

  Future<void> updateProductTimings({
    required int id,
    required String startTime,
    required String endTime,
  }) async {
    final token = await _storage.readToken();
    final form = FormData();
    form.fields
      ..add(MapEntry('attributes[0].attributeName', 'startTime'))
      ..add(MapEntry('attributes[0].attributeValue', startTime))
      ..add(MapEntry('attributes[1].attributeName', 'endTime'))
      ..add(MapEntry('attributes[1].attributeValue', endTime));
    if (kDebugMode) {
      debugPrint(
        '[API] Update Product Timings -> POST /product/api/products/$id/timings',
      );
      for (final e in form.fields) {
        debugPrint('  FIELD ${e.key}=${e.value}');
      }
    }
    await _client.dio.post(
      '/product/api/products/$id/timings',
      data: form,
      options: _authOptions(token).copyWith(contentType: 'multipart/form-data'),
    );
  }

  Future<void> updateBusinessTimings({
    required int businessId,
    required String startTime,
    required String endTime,
  }) async {
    final token = await _storage.readToken();
    final data = {
      'businessId': businessId.toString(),
      'attributes[0].attributeName': 'startTime',
      'attributes[0].attributeValue': startTime,
      'attributes[1].attributeName': 'endTime',
      'attributes[1].attributeValue': endTime,
    };
    await _client.dio.put(
      '/usermgmt/business/timings',
      data: data,
      options: _authOptions(
        token,
      ).copyWith(contentType: 'application/x-www-form-urlencoded'),
    );
  }

  Future<List<int>> downloadProductsExcel({
    required DateTime startDate,
    required DateTime endDate,
    required int businessId,
    required String type,
  }) async {
    final token = await _storage.readToken();
    final s = _fmtDate(startDate);
    final e = _fmtDate(endDate);
    if (kDebugMode) {
      debugPrint(
        '[API] Download Products Excel -> GET /order/report/outlet-itemwise/excel?startDate=$s&endDate=$e&businessId=$businessId&type=$type',
      );
      final tlen = (token ?? '').length;
      debugPrint(
        '[API] Excel Auth header present: ${token != null && token.isNotEmpty}, length=$tlen',
      );
    }
    final res = await _client.dio.get(
      '/order/report/outlet-itemwise/excel',
      queryParameters: {
        'startDate': s,
        'endDate': e,
        'businessId': businessId,
        'type': type,
      },
      options: Options(
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Accept':
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        },
        responseType: ResponseType.bytes,
      ),
    );
    final data = res.data;
    if (data is List<int>) return data;
    if (data is List) return data.cast<int>();
    return List<int>.from(data as List);
  }

  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<pm.ProductPage> fetchProductsReportPaged({
    required DateTime startDate,
    required DateTime endDate,
    required int businessId,
    required String type,
    required int page,
    required int size,
  }) async {
    final token = await _storage.readToken();
    final s = _fmtDate(startDate);
    final e = _fmtDate(endDate);
    if (kDebugMode) {
      debugPrint(
        '[API] Products Report -> GET /order/report/outlet-itemwise/paged?startDate=$s&endDate=$e&businessId=$businessId&type=$type&page=$page&size=$size',
      );
    }
    final res = await _client.dio.get(
      '/order/report/outlet-itemwise/paged',
      queryParameters: {
        'startDate': s,
        'endDate': e,
        'businessId': businessId,
        'type': type,
        'page': page,
        'size': size,
      },
      options: _authOptions(token),
    );

    final data = res.data;
    List list;
    int totalPages = 0;
    int number = page;
    if (data is Map<String, dynamic>) {
      if (data['content'] is List) {
        list = data['content'] as List;
        totalPages = (data['totalPages'] as int?) ?? 0;
        number = (data['number'] as int?) ?? page;
      } else if (data['data'] is Map<String, dynamic>) {
        final inner = data['data'] as Map<String, dynamic>;
        list = (inner['content'] is List) ? inner['content'] as List : const [];
        totalPages = (inner['totalPages'] as int?) ?? 0;
        number = (inner['number'] as int?) ?? page;
      } else if (data['data'] is List) {
        list = data['data'] as List;
      } else {
        list = [];
      }
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }

    num toNum(dynamic v) {
      if (v is num) return v;
      final s = v?.toString();
      return num.tryParse(s ?? '') ?? 0;
    }

    String str(dynamic v) => v?.toString() ?? '';

    final items = list.whereType<Map>().map<Map<String, dynamic>>((raw) {
      final m = Map<String, dynamic>.from(raw);
      return {
        'productName': str(m['productName']),
        'categoryName': str(m['categoryName']),
        'quantity': toNum(m['quantity']).toInt(),
        'grossSales': toNum(m['grossSales']).toDouble(),
        'total': toNum(m['total']).toDouble(),
        'taxAmount': toNum(m['taxAmount']).toDouble(),
        'min': toNum(m['min']).toDouble(),
        'max': toNum(m['max']).toDouble(),
        'avg': toNum(m['avg']).toDouble(),
        'taxable': m['taxable'] == true,
      };
    }).toList();

    final hasNext = totalPages == 0
        ? items.length == size
        : (number + 1) < totalPages;
    return pm.ProductPage(
      items: items,
      hasNext: hasNext,
      page: number,
      size: size,
    );
  }
}
