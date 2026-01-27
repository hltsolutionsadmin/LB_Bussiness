abstract class BusinessRepository {
  Future<void> setBusinessEnabled({
    required int businessId,
    required bool enabled,
  });

  Future<void> onboardBusiness({
    required String businessName,
    required String categoryId,
    required String addressLine1,
    required String city,
    required String country,
    required String postalCode,
    required String latitude,
    required String longitude,
    required String contactNumber,
    String? gstNumber,
    String? fssaiNumber,
    String? loginTime,
    String? logoutTime,
  });
}
