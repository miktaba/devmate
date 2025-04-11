import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String? displayName;

  @HiveField(3)
  final String? photoURL;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
  });

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
    );
  }
}
