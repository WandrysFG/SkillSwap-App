class AppUser {
  final String id;
  final String nombre;
  final String email;
  final String? bio;
  final String? avatarUrl;

  AppUser({
    required this.id,
    required this.nombre,
    required this.email,
    this.bio,
    this.avatarUrl,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      nombre: map['nombre'],
      email: map['email'],
      bio: map['bio'],
      avatarUrl: map['avatar_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'bio': bio,
      'avatar_url': avatarUrl,
    };
  }
}