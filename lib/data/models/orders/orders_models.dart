class OrdersPage {
  final List<Map<String, dynamic>> items;
  final bool hasNext;
  final int page;
  final int size;

  OrdersPage({
    required this.items,
    required this.hasNext,
    required this.page,
    required this.size,
  });
}

double _toDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? 0.0;
}

DateTime? _toDate(dynamic v) {
  final s = v?.toString();
  if (s == null || s.isEmpty) return null;
  return DateTime.tryParse(s);
}

/// Typed model for the Spring-style page wrapper returned by
/// `GET /api/orders/store/{storeId}`.
class OrdersPageResponse {
  final List<OrderResponse> content;
  final int number;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;
  final bool empty;

  OrdersPageResponse({
    required this.content,
    required this.number,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
    required this.empty,
  });

  factory OrdersPageResponse.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'];
    return OrdersPageResponse(
      content: rawContent is List
          ? rawContent
                .whereType<Map>()
                .map(
                  (e) => OrderResponse.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
      number: (json['number'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      first: json['first'] == true,
      last: json['last'] == true,
      empty: json['empty'] == true,
    );
  }
}

/// One order, as returned inside `content[]`.
class OrderResponse {
  final String id;
  final String status;
  final String paymentStatus;
  final String orderType;
  final String? notes;
  final String? couponCode;
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final double subTotal;
  final double totalDiscount;
  final double totalTax;
  final double deliveryCharge;
  final double platformFee;
  final double totalPrice;
  final bool taxInclusive;
  final bool selfOrder;
  final String? deliveryPartnerId;
  final String? b2bUnitId;
  final OrderUserRef? user;
  final OrderStoreRef? store;
  final OrderAddressRef? shippingAddress;
  final OrderAddressRef? billingAddress;
  final OrderFulfillmentAgent? fulfillmentAgent;
  final List<OrderLineItem> lineItems;

  OrderResponse({
    required this.id,
    required this.status,
    required this.paymentStatus,
    required this.orderType,
    this.notes,
    this.couponCode,
    this.createdDate,
    this.updatedDate,
    required this.subTotal,
    required this.totalDiscount,
    required this.totalTax,
    required this.deliveryCharge,
    required this.platformFee,
    required this.totalPrice,
    required this.taxInclusive,
    required this.selfOrder,
    this.deliveryPartnerId,
    this.b2bUnitId,
    this.user,
    this.store,
    this.shippingAddress,
    this.billingAddress,
    this.fulfillmentAgent,
    required this.lineItems,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    final rawLineItems = json['lineItems'];
    final storeField = json['storeId'];
    final userField = json['userId'];
    final shippingField = json['shippingAddressId'];
    final billingField = json['billingAddressId'];
    final agentField = json['fulfillmentAgent'];

    return OrderResponse(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      orderType: json['orderType']?.toString() ?? '',
      notes: json['notes']?.toString(),
      couponCode: json['couponCode']?.toString(),
      createdDate: _toDate(json['createdDate']),
      updatedDate: _toDate(json['updatedDate']),
      subTotal: _toDouble(json['subTotal']),
      totalDiscount: _toDouble(json['totalDiscount']),
      totalTax: _toDouble(json['totalTax']),
      deliveryCharge: _toDouble(json['deliveryCharge']),
      platformFee: _toDouble(json['platformFee']),
      totalPrice: _toDouble(json['totalPrice']),
      taxInclusive: json['taxInclusive'] == true,
      selfOrder: json['selfOrder'] == true,
      deliveryPartnerId: json['deliveryPartnerId']?.toString(),
      b2bUnitId: json['b2bUnitId']?.toString(),
      user: userField is Map
          ? OrderUserRef.fromJson(Map<String, dynamic>.from(userField))
          : null,
      store: storeField is Map
          ? OrderStoreRef.fromJson(Map<String, dynamic>.from(storeField))
          : null,
      shippingAddress: shippingField is Map
          ? OrderAddressRef.fromJson(Map<String, dynamic>.from(shippingField))
          : null,
      billingAddress: billingField is Map
          ? OrderAddressRef.fromJson(Map<String, dynamic>.from(billingField))
          : null,
      fulfillmentAgent: agentField is Map
          ? OrderFulfillmentAgent.fromJson(
              Map<String, dynamic>.from(agentField),
            )
          : null,
      lineItems: rawLineItems is List
          ? rawLineItems
                .whereType<Map>()
                .map(
                  (e) => OrderLineItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : const [],
    );
  }
}

/// `userId` in the order response is a nested customer object, not a plain id.
class OrderUserRef {
  final String id;
  final String? name;
  final String? email;

  OrderUserRef({required this.id, this.name, this.email});

  factory OrderUserRef.fromJson(Map<String, dynamic> json) => OrderUserRef(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString(),
    email: json['email']?.toString(),
  );

  /// Best-effort display name: name > email > shortened id.
  String get displayName {
    final n = name?.trim() ?? '';
    if (n.isNotEmpty) return n;
    final e = email?.trim() ?? '';
    if (e.isNotEmpty) return e;
    return id.length > 8 ? id.substring(0, 8) : id;
  }
}

/// `storeId` in the order response is a nested store object.
class OrderStoreRef {
  final String id;
  final String? storeName;
  final String? address;
  final double? latitude;
  final double? longitude;

  OrderStoreRef({
    required this.id,
    this.storeName,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory OrderStoreRef.fromJson(Map<String, dynamic> json) => OrderStoreRef(
    id: json['id']?.toString() ?? '',
    storeName: json['storeName']?.toString(),
    address: json['address']?.toString(),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );
}

/// `shippingAddressId` / `billingAddressId` are nested address objects.
/// The backend is inconsistent between the two: shipping uses `address`,
/// billing uses `line1` for the street line.
class OrderAddressRef {
  final String id;
  final String? line;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? mobileNumber;

  OrderAddressRef({
    required this.id,
    this.line,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.mobileNumber,
  });

  factory OrderAddressRef.fromJson(Map<String, dynamic> json) =>
      OrderAddressRef(
        id: json['id']?.toString() ?? '',
        line: (json['address'] ?? json['line1'])?.toString(),
        city: json['city']?.toString(),
        state: json['state']?.toString(),
        postalCode: json['postalCode']?.toString(),
        country: json['country']?.toString(),
        mobileNumber: json['mobileNumber']?.toString(),
      );

  bool get hasContent => [
    line,
    city,
    state,
    postalCode,
    country,
  ].any((p) => (p ?? '').trim().isNotEmpty);

  String get formatted {
    final parts = [
      line,
      city,
      state,
      postalCode,
      country,
    ].where((p) => (p ?? '').trim().isNotEmpty).map((p) => p!.trim()).toList();
    return parts.join(', ');
  }
}

/// The delivery partner assigned to the order.
class OrderFulfillmentAgent {
  final String agentId;
  final String? agentType;
  final String? firstName;
  final String? lastName;
  final String? mobileNumber;
  final String? status;

  OrderFulfillmentAgent({
    required this.agentId,
    this.agentType,
    this.firstName,
    this.lastName,
    this.mobileNumber,
    this.status,
  });

  factory OrderFulfillmentAgent.fromJson(Map<String, dynamic> json) =>
      OrderFulfillmentAgent(
        agentId: json['agentId']?.toString() ?? '',
        agentType: json['agentType']?.toString(),
        firstName: json['firstName']?.toString(),
        lastName: json['lastName']?.toString(),
        mobileNumber: json['mobileNumber']?.toString(),
        status: json['status']?.toString(),
      );

  String get displayName {
    final parts = [
      firstName,
      lastName,
    ].where((p) => (p ?? '').trim().isNotEmpty).map((p) => p!.trim());
    return parts.join(' ');
  }
}

class OrderLineItem {
  final String id;
  final String? productId;
  final String? productCode;
  final String? productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double discountPrice;
  final double taxAmount;
  final String? status;
  final String? fulfillmentStatus;

  OrderLineItem({
    required this.id,
    this.productId,
    this.productCode,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.discountPrice,
    required this.taxAmount,
    this.status,
    this.fulfillmentStatus,
  });

  factory OrderLineItem.fromJson(Map<String, dynamic> json) => OrderLineItem(
    id: json['id']?.toString() ?? '',
    productId: json['productId']?.toString(),
    productCode: json['productCode']?.toString(),
    productName: json['productName']?.toString(),
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    unitPrice: _toDouble(json['unitPrice']),
    totalPrice: _toDouble(json['totalPrice']),
    discountPrice: _toDouble(json['discountPrice']),
    taxAmount: _toDouble(json['taxAmount']),
    status: json['status']?.toString(),
    fulfillmentStatus: json['fulfillmentStatus']?.toString(),
  );
}
