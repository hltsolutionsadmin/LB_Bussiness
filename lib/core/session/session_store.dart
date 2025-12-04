import 'package:flutter/foundation.dart';

class SessionStore extends ChangeNotifier {
  Map<String, dynamic>? _user;

  Map<String, dynamic>? get user => _user;

  String get businessName =>
      _user != null && _user!['b2bUnit'] is Map<String, dynamic>
      ? (_user!['b2bUnit']['businessName'] as String? ?? 'Local Basket')
      : 'Local Basket';

  String get primaryContact => _user?['primaryContact']?.toString() ?? '';

  List<String> get roleNames {
    final roles = _user?['roles'];
    if (roles is List) {
      return roles
          .whereType<Map<String, dynamic>>()
          .map((e) => (e['name'] as String?) ?? '')
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
