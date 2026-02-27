import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:local_basket_business/core/network/dio_client.dart';
import 'package:local_basket_business/core/storage/secure_storage.dart';
import 'package:local_basket_business/data/models/offers/offer_models.dart';

class OffersRemoteDataSource {
  OffersRemoteDataSource(this._client, this._storage);

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

  Future<OfferPage> listOffers({
    required int businessId,
    required bool active,
    required int page,
    required int size,
  }) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint(
        '[API] List Offers -> GET /product/api/offers/list?businessId=$businessId&active=$active&page=$page&size=$size',
      );
    }

    final res = await _client.dio.get(
      '/product/api/offers/list',
      queryParameters: {
        'businessId': businessId,
        'active': active,
        'page': page,
        'size': size,
      },
      options: _authOptions(token),
    );

    dynamic payload = res.data;
    if (payload is Map<String, dynamic> && payload['data'] != null) {
      payload = payload['data'];
    }

    List itemsRaw = const [];
    int totalPages = 0;
    int number = page;

    if (payload is Map<String, dynamic>) {
      if (payload['content'] is List) {
        itemsRaw = payload['content'] as List;
        totalPages = (payload['totalPages'] as int?) ?? 0;
        number = (payload['number'] as int?) ?? page;
      } else if (payload['items'] is List) {
        itemsRaw = payload['items'] as List;
      } else if (payload['rows'] is List) {
        itemsRaw = payload['rows'] as List;
      }
    } else if (payload is List) {
      itemsRaw = payload;
    }

    final items = itemsRaw.whereType<Map>().map((e) {
      return Offer.fromJson(Map<String, dynamic>.from(e));
    }).toList();

    return OfferPage(items: items, page: number, totalPages: totalPages);
  }

  Future<Map<String, dynamic>> saveOffer(SaveOfferRequest req) async {
    final token = await _storage.readToken();
    if (kDebugMode) {
      debugPrint('[API] Save Offer -> POST /product/api/offers/save');
      debugPrint('[API] Payload: ${req.toJson()}');
    }

    final res = await _client.dio.post(
      '/product/api/offers/save',
      data: req.toJson(),
      options: _authOptions(token),
    );

    if (res.data is Map) {
      return (res.data as Map).cast<String, dynamic>();
    }
    return {'data': res.data};
  }
}
