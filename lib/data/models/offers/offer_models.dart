import 'package:equatable/equatable.dart';

class Offer extends Equatable {
  final int id;
  final String name;
  final String offerType;
  final String value;
  final double minOrderValue;
  final String couponCode;
  final DateTime? startDate;
  final DateTime? endDate;
  final int businessId;
  final bool active;
  final String description;
  final List<int> productIds;
  final List<int> categoryIds;

  const Offer({
    required this.id,
    required this.name,
    required this.offerType,
    required this.value,
    required this.minOrderValue,
    required this.couponCode,
    required this.startDate,
    required this.endDate,
    required this.businessId,
    required this.active,
    required this.description,
    required this.productIds,
    required this.categoryIds,
  });

  static String _str(dynamic v) => v?.toString() ?? '';

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(_str(v)) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(_str(v)) ?? 0;
  }

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    final s = _str(v).toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  static DateTime? _toDate(dynamic v) {
    final s = _str(v);
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static List<int> _toIntList(dynamic v) {
    if (v is List) {
      return v.map((e) => _toInt(e)).where((e) => e != 0).toList();
    }
    return const [];
  }

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: _toInt(json['id'] ?? json['offerId']),
      name: _str(json['name']),
      offerType: _str(json['offerType']),
      value: _str(json['value']),
      minOrderValue: _toDouble(json['minOrderValue']),
      couponCode: _str(json['couponCode']),
      startDate: _toDate(json['startDate']),
      endDate: _toDate(json['endDate']),
      businessId: _toInt(json['businessId']),
      active: _toBool(json['active']),
      description: _str(json['description']),
      productIds: _toIntList(json['productIds']),
      categoryIds: _toIntList(json['categoryIds']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    offerType,
    value,
    minOrderValue,
    couponCode,
    startDate,
    endDate,
    businessId,
    active,
    description,
    productIds,
    categoryIds,
  ];
}

class OfferPage extends Equatable {
  final List<Offer> items;
  final int page;
  final int totalPages;

  const OfferPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  @override
  List<Object?> get props => [items, page, totalPages];
}

class SaveOfferRequest extends Equatable {
  final String name;
  final String offerType;
  final double value;
  final double minOrderValue;
  final String couponCode;
  final DateTime startDate;
  final DateTime endDate;
  final String description;
  final List<int> productIds;
  final List<int> categoryIds;
  final String targetType;
  final int windowMinutes;
  final int maxClaimsPerWindow;

  const SaveOfferRequest({
    required this.name,
    required this.offerType,
    required this.value,
    required this.minOrderValue,
    required this.couponCode,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.targetType,
    required this.windowMinutes,
    required this.maxClaimsPerWindow,
    this.productIds = const [],
    this.categoryIds = const [],
  });

  Map<String, dynamic> toJson() {
    String isoNoMillis(DateTime d) {
      final s = d.toIso8601String();
      final idx = s.indexOf('.');
      return idx == -1 ? s : s.substring(0, idx);
    }

    return {
      'name': name,
      'offerType': offerType,
      'value': value,
      'minOrderValue': minOrderValue,
      'couponCode': couponCode,
      'startDate': isoNoMillis(startDate),
      'endDate': isoNoMillis(endDate),
      'description': description,
      'productIds': productIds,
      'categoryIds': categoryIds,
      'targetType': targetType,
      'windowMinutes': windowMinutes,
      'maxClaimsPerWindow': maxClaimsPerWindow,
    };
  }

  @override
  List<Object?> get props => [
    name,
    offerType,
    value,
    minOrderValue,
    couponCode,
    startDate,
    endDate,
    description,
    productIds,
    categoryIds,
    targetType,
    windowMinutes,
    maxClaimsPerWindow,
  ];
}
