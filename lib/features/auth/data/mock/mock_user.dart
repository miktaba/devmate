import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';

/// Mock class for Firebase User for offline use
class MockUser extends Mock implements User {
  final String _uid;
  final String? _email;
  final String? _displayName;
  final String? _photoURL;

  MockUser({
    required String uid,
    String? email,
    String? displayName,
    String? photoURL,
  }) : _uid = uid,
       _email = email,
       _displayName = displayName,
       _photoURL = photoURL;

  @override
  String get uid => _uid;

  @override
  String? get email => _email;

  @override
  String? get displayName => _displayName;

  @override
  String? get photoURL => _photoURL;

  @override
  bool get emailVerified => true;

  @override
  bool get isAnonymous => false;

  @override
  UserMetadata get metadata =>
      UserMetadata(0, DateTime.now().millisecondsSinceEpoch);

  @override
  List<UserInfo> get providerData => [];

  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    return 'mock-token-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<User> reload() async {
    return this;
  }

  @override
  Future<void> sendEmailVerification([
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    // Do nothing
  }

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) async {
    throw UnimplementedError();
  }

  @override
  Future<ConfirmationResult> linkWithPhoneNumber(
    String phoneNumber, [
    RecaptchaVerifier? verifier,
  ]) async {
    throw UnimplementedError();
  }
}

/// Mock for UserCredential
class MockUserCredential extends Mock implements UserCredential {
  final User _user;

  MockUserCredential(this._user);

  @override
  User get user => _user;
}
