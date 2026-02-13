import 'dart:async';

class MockUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;

  const MockUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
  });
}

class MockAuthService {
  final _authController = StreamController<MockUser?>.broadcast();
  MockUser? _currentUser;

  Stream<MockUser?> get authStateChanges => _authController.stream;
  MockUser? get currentUser => _currentUser;

  Future<MockUser> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 500));
    const user = MockUser(
      uid: 'mock_user_001',
      email: 'demo@habitbet.app',
      displayName: 'Demo User',
      photoURL: '',
    );
    _currentUser = user;
    _authController.add(user);
    return user;
  }

  Future<MockUser> signInWithApple() async {
    return signInWithGoogle();
  }

  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _authController.add(null);
  }

  void dispose() {
    _authController.close();
  }
}
