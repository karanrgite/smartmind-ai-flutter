class AuthResponse {
  final String token;
  final String email;
  final String username;
  final String? fullName;

  AuthResponse({
    required this.token,
    required this.email,
    required this.username,
    this.fullName,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      email: json['email'],
      username: json['username'],
      fullName: json['fullName'],
    );
  }
}