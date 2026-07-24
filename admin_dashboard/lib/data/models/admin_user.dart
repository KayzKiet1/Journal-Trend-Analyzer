class AdminUser {
  const AdminUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.disabled,
    required this.emailVerified,
    required this.creationTime,
    required this.lastSignInTime,
    required this.providerIds,
    required this.isAdmin,
  });

  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final bool disabled;
  final bool emailVerified;
  final String creationTime;
  final String lastSignInTime;
  final List<String> providerIds;
  final bool isAdmin;

  String get role => isAdmin ? 'Admin' : 'User';

  String get status => disabled ? 'Disabled' : 'Active';

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      uid: map['uid']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? '',
      photoUrl: map['photoURL']?.toString() ?? '',
      disabled: map['disabled'] == true,
      emailVerified: map['emailVerified'] == true,
      creationTime: map['creationTime']?.toString() ?? '',
      lastSignInTime: map['lastSignInTime']?.toString() ?? '',
      providerIds: (map['providerIds'] as List<dynamic>? ?? const [])
          .map((providerId) => providerId.toString())
          .toList(),
      isAdmin: map['isAdmin'] == true,
    );
  }
}
