import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:local_basket_business/core/network/dio_client.dart';
import 'package:local_basket_business/core/storage/secure_storage.dart';

class BusinessRemoteDataSource {
  BusinessRemoteDataSource(this._client, this._storage);

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

  Future<void> setBusinessEnabled({
    required int businessId,
    required bool enabled,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] Business Status -> PUT /usermgmt/business/$businessId/status?enabled=$enabled',
      );
    }
    await _client.dio.put(
      '/usermgmt/business/$businessId/status',
      queryParameters: {'enabled': enabled},
      options: _authOptions(token),
    );
  }

  Future<void> onboardBusiness({
    required String businessName,
    required String categoryId,
    required String addressLine1,
    required String city,
    required String country,
    required String postalCode,
    required String latitude,
    required String longitude,
    required String contactNumber,
    String? gstNumber,
    String? fssaiNumber,
    String? loginTime,
    String? logoutTime,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint('[API] Onboard Business -> POST /usermgmt/business/onboard');
    }

    final form = FormData();
    form.fields
      ..add(MapEntry('businessName', businessName))
      ..add(MapEntry('categoryId', categoryId))
      ..add(MapEntry('addressLine1', addressLine1))
      ..add(MapEntry('city', city))
      ..add(MapEntry('country', country))
      ..add(MapEntry('postalCode', postalCode))
      ..add(MapEntry('latitude', latitude))
      ..add(MapEntry('longitude', longitude))
      ..add(MapEntry('contactNumber', contactNumber));

    int attrIndex = 0;
    void addAttr(String name, String value) {
      form.fields.add(MapEntry('attributes[$attrIndex].attributeName', name));
      form.fields.add(MapEntry('attributes[$attrIndex].attributeValue', value));
      attrIndex += 1;
    }

    if (gstNumber != null && gstNumber.isNotEmpty) {
      addAttr('GSTNumber', gstNumber);
    }
    if (fssaiNumber != null && fssaiNumber.isNotEmpty) {
      addAttr('FSSAINumber', fssaiNumber);
    }
    if (loginTime != null && loginTime.isNotEmpty) {
      addAttr('loginTime', loginTime);
    }
    if (logoutTime != null && logoutTime.isNotEmpty) {
      addAttr('logoutTime', logoutTime);
    }

    await _client.dio.post(
      '/usermgmt/business/onboard',
      data: form,
      options: Options(
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'X-API-KEY': '027e0b4f-5d91-4399-9306-75401b53e865',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> listBusinesses() async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint('[API] List Businesses -> GET /usermgmt/business/list');
    }
    final res = await _client.dio.get(
      '/usermgmt/business/list',
      options: _authOptions(token),
    );
    final data = res.data;
    List list;
    if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        list = data['data'] as List;
      } else if (data['content'] is List) {
        list = data['content'] as List;
      } else {
        list = [];
      }
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
