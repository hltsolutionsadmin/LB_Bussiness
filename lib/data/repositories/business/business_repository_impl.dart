import 'package:local_basket_business/data/datasources/business/business_remote_data_source.dart';
import 'package:local_basket_business/domain/repositories/business/business_repository.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  BusinessRepositoryImpl(this._remote);
  final BusinessRemoteDataSource _remote;

  @override
  Future<void> setBusinessEnabled({
    required int businessId,
    required bool enabled,
  }) {
    return _remote.setBusinessEnabled(businessId: businessId, enabled: enabled);
  }
}
