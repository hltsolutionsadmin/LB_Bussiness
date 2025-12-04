import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get baseUrl {
    if (!dotenv.isInitialized) return '';
    return dotenv.env['BASE_URL']?.trim() ?? '';
  }

  static String? get seedBearer {
    if (!dotenv.isInitialized) return null;
    final v = dotenv.env['SEED_BEARER']?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }
}
