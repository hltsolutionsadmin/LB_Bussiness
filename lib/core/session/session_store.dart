import 'package:flutter/foundation.dart';

class SessionStore extends ChangeNotifier {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;

  String get businessName {
    if (_user == null) return 'Local Basket';

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

  String get primaryContact => _user?['primaryContact']?.toString() ?? '';

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

  void setUser(Map<String, dynamic> user) {
    _user = user;
    notifyListeners();
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}
