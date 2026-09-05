class TriggerOtpRequest {
  final String primaryContact;
  TriggerOtpRequest({required this.primaryContact});
  Map<String, dynamic> toJson() => {
    'primaryContact': primaryContact,
  };
}

class FcmTokenRequest {
  final String fcmToken;
  final String deviceType;
  FcmTokenRequest({required this.fcmToken, this.deviceType = 'ANDROID'});
  Map<String, dynamic> toJson() => {
    'fcmToken': fcmToken,
    'deviceType': deviceType,
  };
}

class TriggerOtpResponse {
  final String otp;
  final String status;
  TriggerOtpResponse({required this.otp, required this.status});
  factory TriggerOtpResponse.fromJson(Map<String, dynamic> json) {
    return TriggerOtpResponse(
      otp: json['otp'] as String,
      status: json['status'] as String,
    );
  }
}

class LoginRequest {
  final String primaryContact;
  final String otp;
  final String fullName;
  final String deviceId;
  LoginRequest({
    required this.primaryContact,
    required this.otp,
    required this.fullName,
    required this.deviceId,
  });
  Map<String, dynamic> toJson() => {
    'primaryContact': primaryContact,
    'otp': otp,
    'fullName': fullName,
    'deviceId': deviceId,
  };
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;
  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
  });
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      tokenType: json['tokenType'] as String,
    );
  }
}

class B2BUnit {
  final String id;
  final String name;
  final String? companyCode;
  final String? tanNumber;
  final String? cinNumber;
  final String? gstNumber;
  final String? panNumber;
  final String? salaryDate;
  final String? isStartup;
  final String? isBootstrapped;
  final String type;
  final String status;
  final String businessRole;
  final String? contactEmail;
  final String? contactPhone;
  final String? website;
  final String? logo;
  final Map<String, dynamic> additionalAttributes;
  final dynamic address;
  final dynamic addresses;
  final String? groupId;
  final String? groupName;

  B2BUnit({
    required this.id,
    required this.name,
    this.companyCode,
    this.tanNumber,
    this.cinNumber,
    this.gstNumber,
    this.panNumber,
    this.salaryDate,
    this.isStartup,
    this.isBootstrapped,
    required this.type,
    required this.status,
    required this.businessRole,
    this.contactEmail,
    this.contactPhone,
    this.website,
    this.logo,
    required this.additionalAttributes,
    this.address,
    this.addresses,
    this.groupId,
    this.groupName,
  });

  factory B2BUnit.fromJson(Map<String, dynamic> json) {
    return B2BUnit(
      id: json['id'] as String,
      name: json['name'] as String,
      companyCode: json['companyCode'] as String?,
      tanNumber: json['tanNumber'] as String?,
      cinNumber: json['cinNumber'] as String?,
      gstNumber: json['gstNumber'] as String?,
      panNumber: json['panNumber'] as String?,
      salaryDate: json['salaryDate'] as String?,
      isStartup: json['isStartup'] as String?,
      isBootstrapped: json['isBootstrapped'] as String?,
      type: json['type'] as String,
      status: json['status'] as String,
      businessRole: json['businessRole'] as String,
      contactEmail: json['contactEmail'] as String?,
      contactPhone: json['contactPhone'] as String?,
      website: json['website'] as String?,
      logo: json['logo'] as String?,
      additionalAttributes: json['additionalAttributes'] as Map<String, dynamic>? ?? {},
      address: json['address'],
      addresses: json['addresses'],
      groupId: json['groupId'] as String?,
      groupName: json['groupName'] as String?,
    );
  }
}

class UserDetails {
  final String id;
  final String username;
  final String email;
  final String mobile;
  final String firstName;
  final String lastName;
  final List<String> roles;
  final String b2bUnitId;
  final B2BUnit b2bUnit;

  UserDetails({
    required this.id,
    required this.username,
    required this.email,
    required this.mobile,
    required this.firstName,
    required this.lastName,
    required this.roles,
    required this.b2bUnitId,
    required this.b2bUnit,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      mobile: json['mobile'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
      b2bUnitId: json['b2bUnitId'] as String,
      b2bUnit: B2BUnit.fromJson(json['b2bUnit'] as Map<String, dynamic>),
    );
  }

  bool get isBusinessAdmin => roles.contains('ROLE_BUSINESS_ADMIN');
}
