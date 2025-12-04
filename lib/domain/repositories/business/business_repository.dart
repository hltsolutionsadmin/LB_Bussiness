abstract class BusinessRepository {
  Future<void> setBusinessEnabled({
    required int businessId,
    required bool enabled,
  });
}
