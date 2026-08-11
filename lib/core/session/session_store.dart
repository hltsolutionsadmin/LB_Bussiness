import 'package:flutter/foundation.dart';

class SessionStore extends ChangeNotifier {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;

  String _readString(Map<String, dynamic>? map, String key) {
    final value = map?[key];
    final text = value?.toString().trim() ?? '';
    return text.toLowerCase() == 'null' ? '' : text;
  }

  Map<String, dynamic>? _readMap(String key) {
    final value = _user?[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String get businessName {
    if (_user == null) return 'Local Basket';

    final store = _readMap('store');
    final storeName = _readString(store, 'name');
    if (storeName.isNotEmpty) return storeName;

    final business = _user!['business'];
    if (business is Map<String, dynamic>) {
      return (business['name'] as String?)?.trim() ?? 'Local Basket';
    }

    final b2bUnit = _user!['b2bUnit'];
    if (b2bUnit is Map<String, dynamic>) {
      return (b2bUnit['name'] as String?)?.trim() ??
          (b2bUnit['businessName'] as String?)?.trim() ??
          'Local Basket';
    }

    return 'Local Basket';
  }

  String get userDisplayName {
    final fullName = _readString(_user, 'fullName');
    if (fullName.isNotEmpty) return fullName;

    final first = _readString(_user, 'firstName');
    final last = _readString(_user, 'lastName');
    final name = [first, last].where((part) => part.isNotEmpty).join(' ');
    if (name.isNotEmpty) return name;

    final username = _readString(_user, 'username');
    if (username.isNotEmpty) return username;

    return '';
  }

  String get primaryContact {
    final primary = _readString(_user, 'primaryContact');
    if (primary.isNotEmpty) return primary;

    final mobile = _readString(_user, 'mobile');
    if (mobile.isNotEmpty) return mobile;

    return _readString(_user, 'phone');
  }

  String get storeId {
    final direct = _readString(_user, 'storeId');
    if (direct.isNotEmpty) return direct;

    final store = _readMap('store');
    return _readString(store, 'id');
  }

  String get b2bUnitId {
    final direct = _user?['b2bUnitId']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;

    final b2bUnit = _user?['b2bUnit'];
    if (b2bUnit is Map<String, dynamic>) {
      return b2bUnit['id']?.toString() ?? '';
    }

    return '';
  }

  List<String> get roleNames {
    final roles = _user?['roles'];
    if (roles is List) {
      return roles
          .map((r) {
            if (r is String) return r;
            if (r is Map<String, dynamic>) return (r['name'] as String?) ?? '';
            return '';
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  bool get isStoreVendor {
    final roles = roleNames;
    return roles.contains('ROLE_STORE_ADMIN') ||
        roles.contains('ROLE_RESTAURANT_OWNER');
  }

  void setUser(Map<String, dynamic> user) {
    _user = user;
    notifyListeners();
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}
