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

  @override
  Future<void> onboardBusiness({
    required String businessName,
    required String addressLine1,
    required String city,
    required String state,
    required String country,
    required String postalCode,
    required String latitude,
    required String longitude,
    required String contactNumber,
  }) {
    return _remote.onboardBusiness(
      businessName: businessName,
      addressLine1: addressLine1,
      city: city,
      state: state,
      country: country,
      postalCode: postalCode,
      latitude: latitude,
      longitude: longitude,
      contactNumber: contactNumber,
    );
  }
}
