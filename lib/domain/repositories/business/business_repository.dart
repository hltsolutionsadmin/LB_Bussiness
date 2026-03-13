abstract class BusinessRepository {
  Future<void> setBusinessEnabled({
    required int businessId,
    required bool enabled,
  });

  Future<void> approveBusiness({required int businessId});

  Future<int?> onboardBusiness({
    required String businessName,
    required String addressLine1,
    required String city,
    required String state,
    required String country,
    required String postalCode,
    required String latitude,
    required String longitude,
    required String contactNumber,
  });
}
