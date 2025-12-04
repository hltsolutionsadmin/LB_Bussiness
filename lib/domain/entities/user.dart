class AppUser {
  final int id;
  final String? email;
  final String? fullName;
  final String primaryContact;

  const AppUser({
    required this.id,
    required this.primaryContact,
    this.email,
    this.fullName,
  });
}
